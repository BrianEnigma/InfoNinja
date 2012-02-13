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


// 20 columns:          _2345678_1_2345678_2
#define STARTUP_LINE_1 "InfoNinja"
#define STARTUP_LINE_2 "v1.0"
#define STARTUP_LINE_3 "--------------------"
#define STARTUP_LINE_4 "Obtaining IP address"

const int numCols = 20;
const int numRows = 4;

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
    webserver.begin();    
}

void loop()
{
    char buff[64];
    int len = 64;
    
    lcd.setCursor(0, 1);
    lcd.print(millis()/1000); // Seconds since reset
    
    lcd.setCursor(0, 2);
    lcd.print(Ethernet.localIP());
    
    lcd.setCursor(0, 3);
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

    buff[0] = 0;
    webserver.processConnection(buff, &len);        
}

