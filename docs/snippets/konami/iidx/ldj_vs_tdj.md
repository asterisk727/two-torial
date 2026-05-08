!!! warning "Lightning mode requires a 120 Hz capable monitor"

!!! warning "Standard and Lightning modes"

    The game data comes in two variants based on the `bm2dx.dll` file.  
    Before proceeding with the setup, it's very important to understand the two cabinet types for IIDX:

    - **Lightning (TDJ/LDJ-010)**:  

        - Runs at 120 FPS
        - Requires a 120 Hz main monitor
        - Second 60 Hz touchscreen monitor called a subscreen
        - Disables physical keypad input; a virtual keypad is on the subscreen
        - Optional video recording feature

    - **Standard/Legacy (LDJ/LDJ-012)**:  

        - Runs at 60 FPS
        - Requires a 60 Hz main monitor
        - No subscreen
        - Accepts physical keypad input
    
    You can patch a LDJ dll to behave like a TDJ dll. This will enable all TDJ features **except** video recording.
    If you want to run in TDJ mode, you **must** also enable the `-iidxtdj` spice2x option [here](#__tabbed_1_8).
    
    You can also patch a TDJ dll to behave like a LDJ dll.
    
    For simplicity, we'll use "TDJ" for Lightning Mode and "LDJ" for Standard Mode throughout our guides.