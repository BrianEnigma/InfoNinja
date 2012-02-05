#include <LiquidCrystal.h>

// LCD Test
// App to test the wiring of the LCD.  I have it wired to some pretty weird pins
// because I'm using an Arduino Ethernet Uno and I need some PWMs available for 
// the backlight coloring.

const int numCols = 20;
const int numRows = 4;

//            rs, enable     d4  d5  d6 d7
LiquidCrystal lcd(2,  8,     A5, A4, 7, 4);

void setup()
{
    pinMode(A4, OUTPUT);
    digitalWrite(A4, LOW);
    pinMode(A5, OUTPUT);
    digitalWrite(A5, LOW);
    lcd.begin(numCols, numRows);
    lcd.print("hello, world!");
}

void loop()
{
    // set the cursor to column 0, line 1
    // (note: line 1 is the second row, since counting begins with 0): 
    lcd.setCursor(0, 1);
    // print the number of seconds since reset:    
    //lcd.print(millis()/1000);
}

