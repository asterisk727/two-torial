# Linux Setup

!!! info "Synopsis"

    CHUNITHM is built for Windows, but newer `chusan`-based versions can be run on Linux with Wine and DXVK.

    This guide explains how to create a Wine prefix, map the required game drives, and launch `amdaemon` and `chusanApp` correctly on Linux.

!!! warning "Compatibility"

    **ONLY** the following game and versions are confirmed to work with the process described in this guide.

    | Game | Version(s) | Caveats (if any) |
    |------|:----------:|:----------------:|
    | CHUNITHM | `X-VERSE-X` | Tested on Arch/EndeavourOS and NVIDIA. |

    This guide was primarily written targetting arch-based systems running Wine with DXVK.  
    **Instructions should still be distro and DE agnostic, but your mileage may vary.**

## Pre-requisites

!!! tip ""

    - A Linux system with:
        - `wine` with wow64 included
        - `winetricks` installed
        - Vulkan drivers installed for both 64-bit and 32-bit applications
    - X-VERSE-X game data prepared using the regular setup guide
    - Your regular X-VERSE-X setup guide opened in another tab

=== "Arch / EndeavourOS"

    !!! tip ""

        Install the common packages with:

        ```sh
        sudo pacman -Sy --needed wine wine-mono wine-gecko winetricks vulkan-tools vulkan-icd-loader lib32-vulkan-icd-loader
        ```

        Install the 32-bit Vulkan driver matching your graphics card:

        ```sh
        sudo pacman -S --needed lib32-nvidia-utils
        ```

        Replace `lib32-nvidia-utils` with `lib32-vulkan-radeon` for AMD or `lib32-vulkan-intel` for Intel.

=== "Other distros"

    !!! tip ""

        Package names vary by distro, but you need these components:

        - Wine with wow64 support
        - Winetricks
        - DXVK, installed through Winetricks or your package manager
        - 32-bit Vulkan support for your GPU

## Preparing data

--8<-- "docs/snippets/common/data_warning.md"

!!! tip ""

    Follow the regular X-VERSE-X setup guide first, up to and including:

    - Preparing data
    - Installing option data
    - Installing unprotected executables
    - Installing ICFs
    - Patching the game
    - Installing and configuring Segatools

    This Linux guide assumes the prepared game application folder is available as `📂contents`.

    If you followed the regular setup guide exactly, this is the prepared `📂App` folder. You may either rename/copy it to `📂contents`, or edit the launcher scripts below so `CONTENTS` points at your `📂App` folder.

    The expected structure is:

    ```
    📂contents
    ├── 📂bin
    ├── 📂data
    ├── 📂firm
    ├── 📂license
    ├── 📄firewall.cfg
    ├── ▶️game.bat
    ├── ▶️pwGetHwinfo.exe
    ├── 📝pxGetHwInfo.ini
    └── 📄system_config.json
    ```

!!! warning "Writable data"

    Ensure the game directory is writable by your Linux user.  
    The game writes to `📂bin/appdata`, `📂bin/DEVICE`, and other files while running.

!!! danger "Double check commands"

    We provide ready-made commands for simplicity, however **don't blindly copy and execute them**.  
    **ALWAYS** double check commands before running them, and substitute `REPLACE_THIS_PATH` with your own location.

## Wine prefix

### Initializing

!!! tip ""

    Create a new `📂prefix` directory next to your `📂contents` directory:

    ```sh
    WINEARCH=win64 WINEPREFIX=REPLACE_THIS_PATH/prefix wineboot --init
    ```

### Common dependencies

!!! tip ""

    Install DXVK to the prefix:

    ```sh
    WINEARCH=win64 WINEPREFIX=REPLACE_THIS_PATH/prefix winetricks -q dxvk
    ```

    DXVK is important for CHUNITHM on Wine. Without it, `chusanApp.exe` may exit immediately after the Segatools injector starts it.

### Mapping the `Y:` drive

!!! warning "Required for `amdaemon`"

    `amdaemon.exe` expects writable storage at `Y:\SDHD\`.  
    If `Y:` is not mapped, `amdaemon.exe.log` may contain:

    ```txt
    Error: create root folder. path Y:\SDHD\
    ```

!!! tip ""

    Map Wine's `Y:` drive to `📂contents/bin/appdata`:

    ```sh
    mkdir -p REPLACE_THIS_PATH/prefix/dosdevices
    ln -sfn REPLACE_THIS_PATH/contents/bin/appdata REPLACE_THIS_PATH/prefix/dosdevices/y:
    ```

    The final path `Y:\SDHD\` should resolve to:

    ```
    📂contents/bin/appdata/SDHD
    ```

## Launcher scripts

!!! info "This section will help you create two bash scripts you may use to start and stop the game"

    The original `launch.bat` starts `amdaemon`, starts `chusanApp`, then kills `amdaemon` when the injector returns.  
    Under Wine, `chusanApp.exe` can stay running after the injector returns, so it is more reliable to start `amdaemon` separately and keep it alive.

### Game start

!!! tip ""

    Create a file named `start.sh` next to your `📂contents` and `📂prefix` directories:

    ```sh
    #!/usr/bin/env bash
    set -euo pipefail

    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CONTENTS="$BASE_DIR/contents"
    WINEPREFIX="$BASE_DIR/prefix"

    export WINEPREFIX
    export DXVK_LOG_LEVEL=info
    export WINEDEBUG=-all

    mkdir -p "$WINEPREFIX/dosdevices"
    ln -sfn "$CONTENTS/bin/appdata" "$WINEPREFIX/dosdevices/y:"

    cd "$CONTENTS/bin"

    wine inject_x64.exe -k chusanhook_x64.dll amdaemon.exe \
      -c config_common.json config_server.json config_client.json \
      config_cvt.json config_sp.json config_hook.json \
      > "$BASE_DIR/amdaemon.log" 2>&1 &

    for _ in {1..40}; do
      pgrep -x amdaemon.exe >/dev/null && break
      sleep 0.25
    done

    if ! pgrep -x amdaemon.exe >/dev/null; then
      echo "amdaemon did not stay running. Check amdaemon.log."
      exit 1
    fi

    wine inject_x86.exe -k chusanhook_x86.dll chusanApp.exe \
      > "$BASE_DIR/chusanapp.log" 2>&1 &

    for _ in {1..80}; do
      pgrep -x chusanApp.exe >/dev/null && break
      sleep 0.25
    done

    if ! pgrep -x chusanApp.exe >/dev/null; then
      echo "chusanApp did not stay running. Check chusanapp.log."
      exit 1
    fi

    while pgrep -x chusanApp.exe >/dev/null; do
      sleep 2
    done

    pkill -x amdaemon.exe >/dev/null 2>&1 || true
    ```

    Make it executable:

    ```sh
    chmod +x REPLACE_THIS_PATH/start.sh
    ```

    Launch the game:

    ```sh
    REPLACE_THIS_PATH/start.sh
    ```

??? tip "Optional performance monitoring"

    If you want a live FPS/frame-time overlay while testing performance, install MangoHud and add the following near the top of `start.sh`, before launching Wine:

    ```sh
    if [[ "${CHUSAN_SHOW_FPS:-1}" == "1" ]]; then
      mkdir -p "$BASE_DIR/mangohud-logs"
      export MANGOHUD=1
      export MANGOHUD_CONFIG="fps,frametime,gpu_stats,cpu_stats,position=top-left,output_folder=$BASE_DIR/mangohud-logs"
    fi
    ```

    On Arch-based distros, the packages are usually:

    ```sh
    sudo pacman -S --needed mangohud lib32-mangohud
    ```

    If your system uses NVIDIA PRIME render offload, try launching the script through `prime-run`:

    ```sh
    prime-run REPLACE_THIS_PATH/start.sh
    ```

    `prime-run` is only needed on PRIME/hybrid graphics setups. On single-GPU desktops, or setups where you already export NVIDIA/Vulkan offload variables manually, launch the script normally.

### Game stop

!!! tip ""

    Create a file named `stop.sh` next to `start.sh`:

    ```sh
    #!/usr/bin/env bash
    set -euo pipefail

    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    export WINEPREFIX="$BASE_DIR/prefix"

    pkill -x chusanApp.exe >/dev/null 2>&1 || true
    pkill -x amdaemon.exe >/dev/null 2>&1 || true
    wineserver -k >/dev/null 2>&1 || true
    ```

    Make it executable:

    ```sh
    chmod +x REPLACE_THIS_PATH/stop.sh
    ```

## First launch

!!! tip ""

    Once the game starts, continue with your version's regular CHUNITHM setup guide from the **First launch** section.

    You will still need to configure the service menu, network, and cab settings as described in the Windows guide.

## Troubleshooting

### `amdaemon` exits immediately

!!! tip ""

    Check `amdaemon.log` first.

    If it mentions `Y:\SDHD\`, your Wine `Y:` drive is missing or points to the wrong folder.

    Recreate it with:

    ```sh
    ln -sfn REPLACE_THIS_PATH/contents/bin/appdata REPLACE_THIS_PATH/prefix/dosdevices/y:
    ```

### `chusanApp.exe` exits immediately

!!! tip ""

    Make sure DXVK is installed to the same Wine prefix used by `start.sh`:

    ```sh
    WINEARCH=win64 WINEPREFIX=REPLACE_THIS_PATH/prefix winetricks -q dxvk
    ```

    Also check that `segatools.ini` uses valid relative paths under `[vfs]`:

    ```ini
    [vfs]
    amfs=amfs
    option=option
    appdata=appdata
    ```

### The game runs too fast or too slow

!!! tip ""

    CHUNITHM expects the monitor refresh rate configured in `segatools.ini`.

    For a 60 Hz monitor:

    ```ini
    [system]
    dipsw2=1
    dipsw3=1
    ```

    For a 120 Hz monitor:

    ```ini
    [system]
    dipsw2=0
    dipsw3=0
    ```

## Help

--8<-- "docs/snippets/common/help.md"
