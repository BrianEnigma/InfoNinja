#InfoNinja

InfoNinja is an Open Source Ethernet-connected desktop heads-up display. It works in tandem with a desktop computer to give you an at-a-glance secondary display of both text and ambient (color/blink/fade) information.

It is also a tea timer.

More detailed information and instructions about InfoNinja can be found at <http://netninja.com/projects/infoninja/>.

#Overview

There are two pieces to InfoNinja, each split into its own section:

 - [Hardware/Firmware](http://netninja.com/projects/infoninja/hardware/)
 - [Software](http://netninja.com/projects/infoninja/software/)

The hardware is the InfoNinja box itself.  The firmware runs within InfoNinja and provides a lightweight REST-enabled web server.  It receives commands over the network and updates the text and lights.

The software runs on a desktop computer.  It can query various environmental conditions — things like weather, bus times, the stock market, recent Tweets, email counts, automated software builds — and then tell InfoNinja to do things like flash red or print status.

The two work in unison to give you any information you need.
