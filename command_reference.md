#InfoNinja Command Reference

for firmware version 1.0

##Display Text

###URL

    http://x.x.x.x/print?n:my_text

###Parameters

- n : the 0-based line number to replace
- my_text : the URL-encoded text to write

###Description

This command displays text on the given line (from 0 to 3).  The entire line will be replaced with the text you give it, so any previously-displayed text will get overwritten, even if you're writing a shorter line.

The text is URL-encoded, so you will have to escape non-alphanumerics with percent-hex equivalents.  For example, "hello world" would be escaped to "hello%20world".  

You have up to 20 characters (after un-escaping) on each line, but remember that the last 5 characters of the first line (line 0) might be obscured by the tea timer countdown.

##Set BacklightColor

###URL

    http://x.x.x.x/lcdcolor?rrrgggbbb

###Parameters

- rrr : The 3-digit red value, from 000 to 255
- ggg : The 3-digit green value, from 000 to 255
- bbb : The 3-digit blue value, from 000 to 255

###Description

This command sets the LCD backlight color to any arbitrary value.  You should keep a few things in mind:

- The user can disable the solid-color backlight with the backlight toggle button.
- If you specify a backlight blink mode, that takes precedence over the solid color you define here.
- If you want to do more complex animations (such as blinking or fading), this is probably not the command to use.  The variable network delay can be unpredictable.  You likely want to use "Set Blink/Fade Mode" command, possibly extending that command to do a custom color pattern, if that is your desire.

##Set Button Lights

###URL

    http://x.x.x.x/buttonled?n

###Parameters

- n : light mode

####Description

This command enables, disables, or blinks the button LEDs.  The possible values for light mode are:

- 0 : disable button lights
- 1 : enable button lights
- 2 : blink button lights (the light toggles every second)

##Set Blink/Fade Mode

###URL

    http://x.x.x.x/blinkmode?n

###Parameters

- n : light mode

###Description

This command enables or disables the LCD backlight blink/fade mode.  The possible values for light mode are:

- 0 : Disable blinking/fading
- 1 : flash between bright yellow and dim yellow once a second
- 2 : flash between bright red and dim red once a second
- 3 : flash between bright blue and dim blue once a second
- 4 : fade between bright yellow and dim yellow
- 5 : fade between bright red and dim red
- 6 : fade between bright blue and dim blue

Note that this setting overrides any background color you may have set via the background-color command.

Also note that manually enabling the blue fade mode through software may be misleading.  This mode is automatically enabled if InfoNinja has not been communicated to in the last few minutes.  It is used to indicate that the displayed data may be stale.

##Button State

Retrieving the button state from the desktop software is specifically *not* supported.  Because the web server is single-threaded, it does not allow for cool Ajax-like blocking web requests (where the incoming web request is accepted, but holds off writing to it until the button state changes, simulating a synchronous action from an asynchronous query).  The desktop software would have to continually poll InfoNinja for the button state, then send updates to respond accordingly.  This introduces enough latency as to provide a rather poor user experience.  For this reason, the ability to query buttons has been intentionally omitted.
