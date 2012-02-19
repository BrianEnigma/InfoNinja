#include <LiquidCrystal.h>

// Full Test
// App to test the wiring of the LCD.  I have it wired to some pretty weird pins
// because I'm using an Arduino Ethernet Uno and I need some PWMs available for 
// the backlight coloring.

const int numCols = 20;
const int numRows = 4;

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

LiquidCrystal lcd(LCD_RS, LCD_ENABLE, LCD_D4, LCD_D5, LCD_D6, LCD_D7);

void setup()
{
    // Set up LCD pins
    pinMode(LCD_D4, OUTPUT);
    digitalWrite(LCD_D4, LOW);
    pinMode(LCD_D5, OUTPUT);
    digitalWrite(LCD_D5, LOW);
    pinMode(LCD_RED, OUTPUT);
    pinMode(LCD_GREEN, OUTPUT);
    pinMode(LCD_BLUE, OUTPUT);
    analogWrite(LCD_RED, 127);
    analogWrite(LCD_GREEN, 255);
    analogWrite(LCD_BLUE, 127);
    
    // Set up button LED pins
    pinMode(BUTTON_RED_GREEN_LED, OUTPUT);
    digitalWrite(BUTTON_RED_GREEN_LED, HIGH);
    
    // Set up button pins
    pinMode(BUTTON_GREEN, INPUT);
    pinMode(BUTTON_WHITE, INPUT);
    pinMode(BUTTON_RED, INPUT);
    digitalWrite(BUTTON_GREEN, HIGH);
    digitalWrite(BUTTON_WHITE, HIGH);
    digitalWrite(BUTTON_RED, HIGH);
        
    // Set up LCD writer
    lcd.begin(numCols, numRows);
    lcd.print("Hello, world!");
    
}

void loop()
{
    lcd.setCursor(0, 1);
    lcd.print(millis()/1000); // Seconds since reset
    
    lcd.setCursor(0, 2);
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
}

