// Required by Ethernet
#include <SPI.h>
// Ethernet
#include <Dhcp.h>
#include <Dns.h>
#include <Ethernet.h>
#include <EthernetClient.h>
#include <EthernetServer.h>
#include <EthernetUdp.h>
#include <util.h>
// LCD
#include <LiquidCrystal.h>
// Webduino -- https://github.com/sirleech/Webduino
#include <WebServer.h>
// Bounce (a Debounce library) -- http://arduino.cc/playground/Code/Bounce
#include <Bounce.h>

const int numCols = 20;
const int numRows = 4;
// 20 columns:          _2345678_1_2345678_2
#define STARTUP_LINE_1 "InfoNinja"
#define STARTUP_LINE_2 "v1.0"
#define STARTUP_LINE_3 "--------------------"
#define STARTUP_LINE_4 "Obtaining IP address"

// General state info
// (state info for specific features are near their associated functions)
unsigned char wroteLcdLine4 = 0;
unsigned char backlightOn = 1;
int backlightRed = 255;
int backlightGreen = 255;
int backlightBlue = 255;
unsigned char blinkMode = 0;
#define BLINK_MODE_NONE 0
#define BLINK_MODE_FLASH_YELLOW 1
#define BLINK_MODE_FLASH_RED 2
#define BLINK_MODE_FADE_YELLOW 3
#define BLINK_MODE_FADE_RED 4
#define BLINK_MODE_INVALID 5
unsigned char blinkDirection = 0; // 0=down, 1=up -- mainly for fades, not blinks

// GPIO pins
#define LCD_D4     A5
#define LCD_D5     A4
#define LCD_D6      7
#define LCD_D7      4
#define LCD_RS      2
#define LCD_ENABLE  8
#define LCD_RED     5
#define LCD_GREEN   6
#define LCD_BLUE    3
#define BUTTON_RED_GREEN_LED  A3
#define BUTTON_GREEN          A0
#define BUTTON_WHITE          A1
#define BUTTON_RED            A2

byte mac[] = {0x90, 0xA2, 0xDA, 0x00, 0x75, 0xD9};

LiquidCrystal lcd(LCD_RS, LCD_ENABLE, LCD_D4, LCD_D5, LCD_D6, LCD_D7);
#define WEBSERVER_PREFIX ""
WebServer webserver(WEBSERVER_PREFIX, 80);
Bounce debounceGreen(BUTTON_GREEN, 100);
Bounce debounceWhite(BUTTON_WHITE, 200);
Bounce debounceRed(BUTTON_RED, 200);

byte clock[8] = {
  B01110,
  B10101,
  B10101,
  B10101,
  B10011,
  B10001,
  B01110,
};

#define MINUTES3 (3 * 60)
#define MINUTES5 (5 * 60)
#define MINUTES7 (7 * 60)

void helloCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
    server.httpSuccess();
    if (type != WebServer::HEAD)
    {
        P(helloMsg) = "<h1>InfoNinja is alive!</h1>";
        server.printP(helloMsg);
    }
}

// http://a.b.c.d/print?1/My_Message
void printCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
    server.httpSuccess();
    // TODO: check security?
    if (type != WebServer::HEAD && strlen(url_tail) >= 3)
    {
        int lineNumber = url_tail[0] - '0';
        if (lineNumber >= 0 && lineNumber <= 3)
        {
            lcd.setCursor(0, lineNumber); lcd.print("                    ");
            lcd.setCursor(0, lineNumber); lcd.print(url_tail + 2);
            if (3 == lineNumber)
                wroteLcdLine4 = 1;
            P(helloMsg) = "<h1>GOOD</h1>";
            server.printP(helloMsg);
        } else {
            P(helloMsg) = "<h1>ERROR</h1>";
            server.printP(helloMsg);
        }
    }
}

// http://a.b.c.d/lcdcolor?rrrgggbbb
void lcdColorCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
    server.httpSuccess();
    // TODO: check security?
    if (type != WebServer::HEAD && strlen(url_tail) >= 9)
    {
        int red = 0, green = 0, blue = 0;
        red   = (url_tail[0] - '0') * 100 + (url_tail[1] - '0') * 10 + (url_tail[2] - '0');
        green = (url_tail[3] - '0') * 100 + (url_tail[4] - '0') * 10 + (url_tail[5] - '0');
        blue  = (url_tail[6] - '0') * 100 + (url_tail[7] - '0') * 10 + (url_tail[8] - '0');
        if (red >= 0 && red <= 255 && green >= 0 && green <= 255 && blue >= 0 && blue <= 255)
        {
            analogWrite(LCD_RED,   255 - red);
            analogWrite(LCD_GREEN, 255 - green);
            analogWrite(LCD_BLUE,  255 - blue);
            backlightOn = 1;
            backlightRed = red;
            backlightGreen = green;
            backlightBlue = blue;
            P(helloMsg) = "<h1>GOOD</h1>";
            server.printP(helloMsg);
        } else {
            P(helloMsg) = "<h1>ERROR</h1>";
            server.printP(helloMsg);
        }
    }
}

// http://a.b.c.d/buttonled?x
void buttonLedCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
    server.httpSuccess();
    // TODO: check security?
    if (type != WebServer::HEAD && strlen(url_tail) >= 1)
    {
        digitalWrite(BUTTON_RED_GREEN_LED, url_tail[0] == '1' ? HIGH : LOW);
        P(helloMsg) = "<h1>GOOD</h1>";
        server.printP(helloMsg);
    } else {
        P(helloMsg) = "<h1>ERROR</h1>";
        server.printP(helloMsg);
    }
}

// http://a.b.c.d/blinkmode?x
void blinkModeCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
    server.httpSuccess();
    // TODO: check security?
    if (type != WebServer::HEAD && strlen(url_tail) >= 1)
    {
        unsigned char value = url_tail[0] - '0';
        if (value >= BLINK_MODE_NONE && value < BLINK_MODE_INVALID)
        {
            blinkMode = value;
            blinkDirection = 1;
            P(helloMsg) = "<h1>GOOD</h1>";
            server.printP(helloMsg);
        } else {
            P(helloMsg) = "<h1>ERROR</h1>";
            server.printP(helloMsg);
        }
    } else {
        P(helloMsg) = "<h1>ERROR</h1>";
        server.printP(helloMsg);
    }
}

void setup()
{
    int counter;
    // Set up LCD pins
    pinMode(LCD_D4, OUTPUT);
    digitalWrite(LCD_D4, LOW);
    pinMode(LCD_D5, OUTPUT);
    digitalWrite(LCD_D5, LOW);
    pinMode(LCD_RED, OUTPUT);
    pinMode(LCD_GREEN, OUTPUT);
    pinMode(LCD_BLUE, OUTPUT);
    
    // Set up button LED pins
    pinMode(BUTTON_RED_GREEN_LED, OUTPUT);
    
    // Test lights
    for (counter = 0; counter < 4; counter++)
    {
        analogWrite(LCD_RED,   (0 == counter || 3 == counter) ? 0 : 255);
        analogWrite(LCD_GREEN, (1 == counter || 3 == counter) ? 0 : 255);
        analogWrite(LCD_BLUE,  (2 == counter || 3 == counter) ? 0 : 255);
        digitalWrite(BUTTON_RED_GREEN_LED, counter % 2 == 0 ? HIGH : LOW);
        delay(750);
    }
    
    // Set up button pins
    pinMode(BUTTON_GREEN, INPUT);
    pinMode(BUTTON_WHITE, INPUT);
    pinMode(BUTTON_RED, INPUT);
    digitalWrite(BUTTON_GREEN, HIGH);
    digitalWrite(BUTTON_WHITE, HIGH);
    digitalWrite(BUTTON_RED, HIGH);
        
    // Set up LCD writer
    lcd.begin(numCols, numRows);
    lcd.createChar(1, clock);
    lcd.setCursor(0, 0); lcd.print(STARTUP_LINE_1);
    lcd.setCursor(0, 1); lcd.print(STARTUP_LINE_2);
    lcd.setCursor(0, 2); lcd.print(STARTUP_LINE_3);
    lcd.setCursor(0, 3); lcd.print(STARTUP_LINE_4);
    
    // Set up Ethernet
    Ethernet.begin(mac); // This blocks until we get a DHCP address!
    lcd.clear();
    lcd.setCursor(0, 0); lcd.print(STARTUP_LINE_1);
    
    // Set up web server
    webserver.setDefaultCommand(&helloCmd);
    webserver.addCommand("index.html", &helloCmd);
    webserver.addCommand("print", &printCmd); 
    webserver.addCommand("lcdcolor", &lcdColorCmd); 
    webserver.addCommand("buttonled", &buttonLedCmd); 
    webserver.addCommand("blinkmode", &blinkModeCmd); 
    webserver.begin();
    
    debounceGreen.update();
    debounceWhite.update();
    debounceRed.update();
}

void toggleBacklight()
{
    if (backlightOn)
    {
        backlightOn = 0;
        analogWrite(LCD_RED,   255);
        analogWrite(LCD_GREEN, 255);
        analogWrite(LCD_BLUE,  255);
    } else {
        backlightOn = 1;
        analogWrite(LCD_RED,   255 - backlightRed);
        analogWrite(LCD_GREEN, 255 - backlightGreen);
        analogWrite(LCD_BLUE,  255 - backlightBlue);
    }
}

unsigned char demoTimer = 0;
unsigned char inDemo = 0; // 0 = not in demo mode, any other value is a demo mode state

void demo()
{
    unsigned int now = (millis() / 1000) % 10;
    if (now == demoTimer)
        return;
    //lcd.write(random(0x20, 0xFF));
    demoTimer = now;
    analogWrite(LCD_RED,   random(255));
    analogWrite(LCD_GREEN, random(255));
    analogWrite(LCD_BLUE,  random(255));
    digitalWrite(BUTTON_RED_GREEN_LED, demoTimer % 2 == 0 ? HIGH : LOW);
}

int teaTimerValue = -1; // -1 = not in tea timer mode, any other value is the current time
int teaTimerLastSecond = 0;

void doTeaTimer()
{
    unsigned int now = (millis() / 1000) % 10;
    if (now != teaTimerLastSecond)
    {
        teaTimerLastSecond = now;
        if (teaTimerValue > 0)
        {
            teaTimerValue = teaTimerValue - 1;
        } else {
            toggleBacklight();
        }
    }
    lcd.setCursor(15, 0);
    lcd.write(1);
    lcd.write(teaTimerValue / 60 + '0');
    lcd.write(':');
    lcd.write(teaTimerValue % 60 / 10 + '0');
    lcd.write(teaTimerValue % 10 + '0');
}

int blinkModeLastTime = 0;

void adjustBlink()
{
    unsigned int now;
    
    if (blinkMode == BLINK_MODE_NONE)
    {
        // restore background?
        return;
    }
    if (BLINK_MODE_FLASH_YELLOW == blinkMode || BLINK_MODE_FLASH_RED == blinkMode)
    {
        unsigned int now = (millis() / 1000) % 10;
        if (blinkModeLastTime == now)
            return; // Operate only every second
         blinkModeLastTime = now;
         if (BLINK_MODE_FLASH_YELLOW == blinkMode)
         {
             backlightRed = (backlightRed == 255) ? 128 : 255;
             backlightGreen = (backlightGreen == 255) ? 128 : 255;
             backlightBlue = 0;
         } else { // red
             backlightRed = (backlightRed == 255) ? 128 : 255;
             backlightGreen = 0;
             backlightBlue = 0;
         }
    }
    if (BLINK_MODE_FADE_YELLOW == blinkMode || BLINK_MODE_FADE_RED == blinkMode)
    {
        unsigned int now = (millis() / 10) % 10;
        if (blinkModeLastTime == now)
            return;
         if (BLINK_MODE_FADE_YELLOW == blinkMode)
         {
             // fade
             if (blinkDirection == 1 && backlightRed < 255)
                 backlightRed = backlightRed - backlightRed % 5 + 5;
             else if (blinkDirection == 0 && backlightRed > 127)
                 backlightRed = backlightRed - backlightRed % 5 - 5;
             if (blinkDirection == 1 && backlightGreen < 255)
                 backlightGreen = backlightGreen - backlightGreen % 5 + 5;
             else if (blinkDirection == 0 && backlightGreen > 127)
                 backlightGreen = backlightGreen - backlightGreen % 5 - 5;
             // switch                 
             if (blinkDirection == 1 && backlightRed == 255 && backlightGreen == 255)
                 blinkDirection = 0;
             else if (blinkDirection == 0 && backlightRed <= 127 && backlightGreen <= 127)
                 blinkDirection = 1;
             backlightBlue = 0;
         } else { // red
             if (blinkDirection == 1 && backlightRed < 255)
                 backlightRed = backlightRed - backlightRed % 5 + 5;
             else if (blinkDirection == 1 && backlightRed == 255)
                 blinkDirection = 0;
             else if (blinkDirection == 0 && backlightRed > 127)
                 backlightRed = backlightRed - backlightRed % 5 - 5;
             else if (blinkDirection == 0 && backlightRed <= 127)
                 blinkDirection = 1;
             backlightGreen = 0;
             backlightBlue = 0;
         }
    }
}

void doBlink()
{
    adjustBlink();
    analogWrite(LCD_RED,   random(255));
    analogWrite(LCD_GREEN, random(255));
    analogWrite(LCD_BLUE,  random(255));
}


void loop()
{
    char buff[64];
    int len = 64;

    // Handle buttons
    debounceGreen.update();
    debounceWhite.update();
    debounceRed.update();
    if (debounceWhite.risingEdge())
        toggleBacklight();
    if (debounceRed.risingEdge())
    {
        if (0 == inDemo)
        {
            randomSeed(millis());
            inDemo = 1;
            //lcd.clear();
        } else {
            inDemo = 0;
        }
    }

    if (debounceGreen.risingEdge())
    {
        if (teaTimerValue == -1)
            teaTimerValue = MINUTES3;
        else if (teaTimerValue == 0)
            teaTimerValue = -1;
        else if (teaTimerValue <= MINUTES3)
            teaTimerValue = MINUTES5;
        else if (teaTimerValue <= MINUTES5)
            teaTimerValue = MINUTES7;
        else if (teaTimerValue <= MINUTES7)
            teaTimerValue = -1;
        if (-1 == teaTimerValue)
        {
            lcd.setCursor(15, 0);
            lcd.write("     ");
        }
    }
        
    if (inDemo)
    {
        teaTimerValue == -1;
        demo();
    } else {
        // Write the IP address on the last line, but only until a
        // client web connection writes something on that line.
        if (!wroteLcdLine4)
        {
            lcd.setCursor(0, 3);
            lcd.print(Ethernet.localIP());
        }
        doBlink();
        
        // Print buttons
#if 0
        lcd.setCursor(17, 3);
        if (digitalRead(BUTTON_GREEN))
            lcd.write('_');
        else
            lcd.write('*');
        if (digitalRead(BUTTON_WHITE))
            lcd.write('_');
        else
            lcd.write('*');
        if (digitalRead(BUTTON_RED))
            lcd.write('_');
        else
            lcd.write('*');
#endif
    
        buff[0] = 0;
        webserver.processConnection(buff, &len);
    }
    if (teaTimerValue != -1)
        doTeaTimer();
}

