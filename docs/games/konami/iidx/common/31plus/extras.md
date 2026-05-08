# Extra Information

## Changing the game's language

!!! tip ""

    This is done in-game before card-in by pressing your `EFFECT` key.

## About ea3-config.xml

!!! tip ""

    The `ea3-config.xml` file is located inside the `prop` folder. 
    It defines several *prop*erties that tell the game how its should be configured.

    Below is an explanation on what different sections of this file do.

    The following lines change the PCBID and HARDID that your system reports to your e-amusement server.  
    There is ^^**no need to manually change this**^^ as `spice2x` will do it for us.
    
    ```xml
    <pcbid __type="str">00010203040506070809</pcbid>
    <hardid __type="str">00010203040506070809</hardid>
    ```

    The following line determines what version of the game you are running.  
    ^^**You should never change this**^^. It should always say `LDJ`.

    ```xml
    <model __type="str">LDJ</model>
    ```

    The following line determines the game's region.
    ^^**You shouldn't need to change this**^^ as you can change the language in-game.

    ```xml
    <dest __type="str">J</dest>
    ```

    The following line determines whether the game is in Standard or Lightning mode.

    ```xml
    <spec __type="str">E</spec>
    ```

    - ^^`E`^^ for Standard (LDJ-012, LDJ, 60 Hz)
    - ^^`D`^^ for Lightning (LDJ-010, TDJ, 120 Hz)

    Editing this line **by itself will not change which mode** your game runs in!

    Your dll must already be in the right mode **in addition** to setting this property properly. [(Read More)](../setup/#standard-and-lightning-modes)

    ^^**Always keep it up to date**^^ with what mode your game is configured to run in. 

    ^^**The following line should never be changed**^^. It should always say `A`.

    ```xml
    <rev __type="str">A</rev>
    ```

    The following line determines your datecode.  
    It is best practice to ^^**keep it up to date**^^ with your game's current version.

    ```xml
    <ext __type="str">2024100900</ext>
    ```

    The following line determine what remote service URL `spice2x` is supposed to connect to.  
    There is ^^**no need to manually change this**^^ as `spice2x` will do it for us.

    ```xml
    <services __type="str">http://localhost:8083</services>
    ```