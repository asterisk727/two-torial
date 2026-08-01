#!/usr/bin/env bash
# Original Author: NotAkitake
# Revised by gnosticJade, see https://github.com/asterisk727/two-torial/pull/8
# sp2x-linux-setup.sh
# Place this script in your game directory before running
# OR export GAME_DIR with your game directory (the one containing the contents directory)

set -euo pipefail

# Colors
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  MAGENTA='\033[0;35m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' BOLD='' NC=''
fi

# Print functions
print_error() { echo -e "${RED}✗ ERROR:${NC} $1" >&2; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${CYAN}➜${NC} $1"; }
print_warn() { echo -e "${YELLOW}⚠ ${NC} $1"; }
print_header() { echo -e "\n${BOLD}${BLUE}===${NC} ${BOLD}$1${NC} ${BOLD}${BLUE}===${NC}\n"; }
print_step() { echo -e "\n${MAGENTA}▶${NC} ${BOLD}$1${NC}"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GAME_DIR="${GAME_DIR:-$SCRIPT_DIR}" # If GAME_DIR wasn't already set, use script_dir
MODULES_DIR="$GAME_DIR/contents/modules"

# Check dependencies
print_step "Checking dependencies"
MISSING_TOOLS=()
command -v wine &>/dev/null || MISSING_TOOLS+=("wine")
command -v winetricks &>/dev/null || MISSING_TOOLS+=("winetricks")
command -v curl &>/dev/null || MISSING_TOOLS+=("curl")
command -v unzip &>/dev/null || MISSING_TOOLS+=("unzip")

if [[ ${#MISSING_TOOLS[@]} -ne 0 ]]; then
  print_error "Missing required tools: ${MISSING_TOOLS[*]}"
  echo "  Install with: sudo pacman -S ${MISSING_TOOLS[*]} (Arch/Manjaro)"
  echo "            or: sudo apt install ${MISSING_TOOLS[*]} (Debian/Ubuntu)"
  echo "            or: sudo dnf install ${MISSING_TOOLS[*]} (Fedora/RHEL)"
  exit 1
fi

# Check for contents dir
print_step "Verifying game directory"
if [[ ! -d "$GAME_DIR/contents" ]]; then
  print_error "Game contents directory not found at $GAME_DIR/contents"
  echo "  Please ensure your game files are in the correct location."
  echo "  The directory structure should be:"
  echo "    $GAME_DIR/contents/modules/<game>.dll"
  exit 1
fi
print_success "contents directory found"

# Game detection
print_step "Detecting game..."
GAME_ID=""
GAME_NAME=""
GAME_INSTRUCTIONS=""
GAME_DLL=""
GAME_DLL_ARCH=0
GAME_PORTRAIT=0
SPICE_EXE=""
STUBS=0

if [[ -f "$MODULES_DIR/gamemdx.dll" ]]; then
  GAME_ID="ddr"
  GAME_NAME="DanceDanceRevolution"
  GAME_INSTRUCTIONS="  1. Verify DDR World is detected
  2. Bind your game buttons"
  GAME_DLL="gamemdx.dll"
  STUBS=1
elif [[ -f "$MODULES_DIR/soundvoltex.dll" ]]; then
  GAME_ID="sdvx"
  GAME_NAME="SOUND VOLTEX"
  GAME_INSTRUCTIONS="  1. Verify SOUND VOLTEX is detected
  2. Bind your game buttons
  3. Go to the Patches tab
  4. Import patches from URL: https://patcher.573.moe
  5. Enable Shared mode WASAPI patch and whatever else you want
  6. Enable Auto apply patches on game start"
  GAME_DLL="soundvoltex.dll"
  GAME_PORTRAIT=1
  STUBS=1
elif [[ -f "$MODULES_DIR/kamunity.dll" && -f "$GAME_DIR/contents/game/MFGClient_Data/app.info" ]]; then
  GAME_ID="mfg"
  GAME_NAME="Mahjong Fight Girl"
  GAME_INSTRUCTIONS="  1. Verify Mahjong Fight Girl is detected
  2. Bind your game buttons"
  GAME_DLL="kamunity.dll"
else
  print_error "No supported game detected in $MODULES_DIR"
  exit 1
fi

if file "$MODULES_DIR/$GAME_DLL" | grep -q "PE32+ executable"; then
  GAME_DLL_ARCH=64
  SPICE_EXE="spice64.exe"
elif file "$MODULES_DIR/$GAME_DLL" | grep -q "PE32 executable"; then
  GAME_DLL_ARCH=32
  SPICE_EXE="spice.exe"
else
  print_error "Could not find whether $GAME_DLL is 32 or 64 bit"
  exit 1
fi

print_success "Detected $GAME_NAME"
WINEPREFIX="$GAME_DIR/prefix"
PORTRAIT_MODE=0

# Ask about portrait mode if applicable to the game
if [[ "$GAME_PORTRAIT" -eq 1 ]]; then
  echo -en "\n${CYAN}Will you set your monitor to portrait mode before playing? [y/N]:${NC} "
  read -r PORTRAIT_ANSWER
  if [[ "$PORTRAIT_ANSWER" =~ ^[Yy]$ ]]; then
    PORTRAIT_MODE=0
    print_info "Will use your native monitor orientation"
  else
    PORTRAIT_MODE=1
    print_info "Will emulate 1080x1920 in a virtual desktop"
  fi
fi

# Prompt user before proceeding
print_header "$GAME_NAME - Linux Setup"

print_info "Game: $GAME_NAME ($GAME_ID)"
print_info "Script directory: $SCRIPT_DIR"
print_info "Game directory: $GAME_DIR"
print_info "Prefix directory: $WINEPREFIX"
if [[ "$GAME_PORTRAIT" -eq 1 ]]; then
  if [[ "$PORTRAIT_MODE" -eq 1 ]]; then
    print_info "Portrait handling: Virtual desktop for use in landscape mode"
  else
    print_info "Portrait handling: Manual (will need to set monitor to portrait mode before launching the game)"
  fi
fi

echo -en "\n${CYAN}Is this correct and do you want to proceed with setup? [y/N]:${NC} "
read -r PROCEED_ANSWER
if [[ ! "$PROCEED_ANSWER" =~ ^[Yy]$ ]]; then
  print_info "Cancelling setup"
  exit 1
fi

# Download spice2x if not present
print_step "Setting up spice2x"
if [[ ! -d "$GAME_DIR/spice2x" ]]; then
  print_info "Downloading latest spice2x release..."

  # get the latest zip url from api manifest
  # likely in the format of https://[...]/spice2x-yy-mm-dd-full.zip
  DOWNLOAD_URL=$(curl -s https://api.github.com/repos/spice2x/spice2x.github.io/releases/latest |
    grep -o 'https://.*\.zip' | head -1)

  if [[ -z "$DOWNLOAD_URL" ]]; then
    print_error "Failed to get spice2x download URL"
    exit 1
  fi

  # strips the rest of the URL, leaving just spice2x-yy-mm-dd-full.zip
  # download to /tmp/spice2x-yy-mm-dd-full.zip
  ZIP_FILE=$(basename "$DOWNLOAD_URL")
  curl -L --progress-bar "$DOWNLOAD_URL" -o "/tmp/$ZIP_FILE"

  print_info "Extracting spice2x..."
  unzip -q -o "/tmp/$ZIP_FILE" -d "/tmp/spice2x"
  mv /tmp/spice2x "$GAME_DIR/"
  rm "/tmp/$ZIP_FILE"

  print_info "Copying $SPICE_EXE..."
  cp "$GAME_DIR/spice2x/$SPICE_EXE" "$GAME_DIR/contents/"

  if [[ "$STUBS" -eq 1 ]]; then
    print_info "Copying nvidia stubs ($GAME_DLL_ARCH)..."
    cp "$GAME_DIR/spice2x/stubs/$GAME_DLL_ARCH/"* "$GAME_DIR/contents/modules/"
  fi

  rm -r "$GAME_DIR/spice2x"

  print_success "spice2x installed"
else
  print_success "spice2x already present"
fi

# Create Wine prefix
print_step "Creating Wine prefix"
export WINEARCH=win64
export WINEPREFIX="$GAME_DIR/prefix"

if [[ ! -d "$WINEPREFIX" ]]; then
  print_info "Initializing Wine prefix at $WINEPREFIX..."
  # Call wineboot and skip gecko/mono prompts
  WINEDLLOVERRIDES="mscoree=d;mshtml=d" wineboot &>/dev/null
  print_success "Wine prefix created"
else
  print_warn "Wine prefix already exists, skipping creation"
fi

print_step "Configuring Wine"
if [[ $PORTRAIT_MODE -eq 1 ]]; then
  print_info "Setting up virtual desktop (1080x1920)..."
  cat >/tmp/wine_desktop.reg <<'EOF'
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"

[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="1080x1920"
EOF
  wine regedit /tmp/wine_desktop.reg &>/dev/null
  rm /tmp/wine_desktop.reg
  print_success "Virtual desktop configured"
fi

# Install Wine dependencies
print_step "Installing Wine dependencies"
print_info "Installing DXVK, D3D compilers (this may take a while)..."
# common
winetricks -q dxvk d3dcompiler_42 d3dcompiler_43 d3dcompiler_46 d3dcompiler_47 &>/dev/null || {
  print_warn "Winetricks installation had some warnings, continuing..."
}
# required for ddr video playback
if [[ "$GAME_ID" = "ddr" ]]; then
  print_info "Installing quartz, devenum, amstream, windowscodecs (this may take a while)..."
  winetricks -q quartz devenum amstream windowscodecs &>/dev/null || {
    print_warn "Winetricks installation had some warnings, continuing..."
  }
fi
print_success "Wine dependencies installed"

# Install audio dependencies
print_step "Installing audio dependencies"
if command -v pacman &>/dev/null; then
  print_info "Installing GStreamer packages..."
  sudo pacman -S --needed --noconfirm gstreamer gst-plugins-good gst-plugins-ugly gst-libav || {
    print_warn "Failed to install some audio packages, you may need to install them manually"
  }
  print_success "Audio dependencies installed"
else
  print_warn "Not on Arch Linux - please install gstreamer, gst-plugins-good, gst-plugins-ugly, and gst-libav manually"
fi

# Setup PipeWire virtual sink
print_step "Configuring audio (PipeWire)"
echo -en "\n${CYAN}Do you want to set up a PipeWire virtual sink? [Y/n]:${NC} "
read -r AUDIO_SETUP
AUDIO_SETUP=${AUDIO_SETUP:-Y}

if [[ "$AUDIO_SETUP" =~ ^[Yy]$ ]]; then
  # Detect audio output device
  print_info "Creating PipeWire virtual sink configuration..."
  mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"

  cat >"$HOME/.config/pipewire/pipewire.conf.d/virtual-sink.conf" <<EOF
context.modules = [
  {
    name = libpipewire-module-loopback
    args = {
      audio.position = [ FL FR ]
      capture.props = {
        media.class = Audio/Sink
        audio.format = S16LE
        audio.rate = 44100
        audio.channels = 2
        node.name = spice2x
        node.description = "SPICE2X"
      }
      playback.props = {
        node.passive = true
        node.name = spice2x.output
        node.description = "SPICE2X OUTPUT"
        target.object = "alsa_output.pci-0000_04_00.6.HiFi__hw_Generic_1__sink"
        audio.format = S16LE
      }
    }
  }
]
EOF

  print_info "Restarting PipeWire..."
  systemctl --user restart pipewire.service pipewire-pulse.socket

  print_success "Virtual sink created"
  echo ""
  print_warn "Don't forget to set 'SPICE2X' as your default audio sink!"
fi

# Create launcher scripts
print_step "Creating launcher scripts"
cat >"$GAME_DIR/launch-$GAME_ID.sh" <<LAUNCHER_EOF
#!/bin/bash
# $GAME_NAME - Game Launcher

GAME_DIR="$GAME_DIR"
export WINEARCH=win64
export WINEPREFIX="\$GAME_DIR/prefix"

# Default arguments
ARGS="-modules ../contents/modules"

# Optional: Add arguments
# ARGS="\$ARGS -url localhost:8083"     # Network URL
# ARGS="\$ARGS -p 01FXXXXXXXXXXXXXXXXX" # PCBID

# Append args to this script
ARGS="\$ARGS \$@"

cd "\$GAME_DIR/contents"
wine "$SPICE_EXE" \$ARGS
LAUNCHER_EOF
chmod +x "$GAME_DIR/launch-$GAME_ID.sh"

cat >"$GAME_DIR/config-$GAME_ID.sh" <<LAUNCHER_EOF
#!/bin/bash
# $GAME_NAME - Config Launcher

"$GAME_DIR/launch-$GAME_ID.sh" -cfg
LAUNCHER_EOF
chmod +x "$GAME_DIR/config-$GAME_ID.sh"

print_success "Launcher scripts created"

# Configure spice2x
print_step "Configuring spice2x"
print_info "Launching spicecfg for manual configuration..."
echo ""
echo "  Please configure the following:"
echo "$GAME_INSTRUCTIONS"
echo -en "\n${CYAN}Press Enter to launch spicecfg..."
# shellcheck disable=SC2162
read
"$SCRIPT_DIR/config-$GAME_ID.sh"

# Final instructions
print_header "Setup Complete!"
echo ""
print_success "$GAME_NAME should now be ready to play!"
echo ""
echo "To launch the game: run launch-$GAME_ID.sh"
echo "To launch spicecfg: run config-$GAME_ID.sh"
echo ""
if [[ "$AUDIO_SETUP" =~ ^[Yy]$ ]]; then
  print_warn "Remember to set 'SPICE2X' as your default audio sink!"
fi
echo ""