#InfoNinja

Initial project files.

TODO: write stuff here

##Parts

1. Obtain the tools you might need
    - Soldering iron
    - Solder
    - Wire
    - etc.
2. Obtain electronics parts
    - Arduino Ethernet <http://www.adafruit.com/products/418>
    - RGB LCD <http://www.adafruit.com/products/499>
    - Contrast knob (10K panel-mount potentiometer) <http://www.adafruit.com/products/562>
    - Red button <http://www.adafruit.com/products/559>
    - Green button <http://www.adafruit.com/products/560>
    - White button <http://www.adafruit.com/products/558>
    - FTDI Friend (for programming) <https://www.adafruit.com/products/284>
    - Mini-USB cable
    - Ethernet cable
3. Obtain hardware
    - 16M3 screws
    - 16M3 nuts
    - xxx screws
    - xxx nuts
    - spacers
    - Feet
4. Obtain laser-cut parts
    - TODO: link to Thingiverse files
5. Obtain the 3rd party webserver library for the Arduino, [Webduino]
    - Create a "libraries" folder in your Arduino sketch folder.  For me, this means creating a folder named "libraries" in "~/Documents/Arduino"
    - Using your git tool of choice, check out https://github.com/sirleech/Webduino.git into that "libraries" folder.

[Webduino]: https://github.com/sirleech/Webduino

##Assembly

1. Assemble electronics components according to the schematic.
    - Be sure to leave enough wire between the Arduino and the various other components (LCD, Buttons, and Knob).
2. Test your wiring by loading the lcd_test application.
    - This app is an LCD "hello, world" that is preconfigured with the correct pin numbers.
    - It cycles the LCD from red to green to blue.
    - It cycles the buttons from red to green to white.
    - If you do not see "hello, world" on the LCD (you may have to adjust the contrast knob), or if the color cycling is missing a color then you should recheck your wiring.
3. Assemble the laser-cut enclosure
    - Attach Arduino and feet to bottom.
    - Attach LCD to front.  Note the orientation.  The solder pads are at the TOP.
    - Attach buttons to top.  A is green, B is white, C is red.
    - Attach knob to rear.
    - Assemble box.

