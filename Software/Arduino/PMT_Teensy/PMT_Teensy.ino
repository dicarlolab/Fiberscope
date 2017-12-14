#include "LiquidCrystal_I2C_Due_Compatible.h"

//SainSmart
#include <Wire.h> 


void setup()
{
  Serial.begin(115200);
  Serial.println("Start");
  delay(500);
 

}

int addr = 10;
void loop()
{
  Serial.println(addr);
    delay(100);  
      LiquidCrystal_Due_I2C lcd(addr,16,2);  // set the LCD address to 0x3F for a 16 chars and 2 line display

  
  lcd.init();                      // initialize the lcd 
  lcd.init();
  // Print a message to the LCD.
  lcd.backlight();
  lcd.setCursor(0,0);
  lcd.print("Hello, world!");
  delay(100);
 
  addr++;
}

