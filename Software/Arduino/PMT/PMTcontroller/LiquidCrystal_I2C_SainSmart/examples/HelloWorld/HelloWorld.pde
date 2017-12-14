//SainSmart
#include <Wire.h> 
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x3F,20,4);  // set the LCD address to 0x3F for a 16 chars and 2 line display

void setup()
{
  lcd.init();                      // initialize the lcd 
  lcd.init();
  // Print a message to the LCD.
  lcd.backlight();
  lcd.setCursor(3,0);
  lcd.print("Hello, world!");
  lcd.setCursor(2,1);
  lcd.print("SainSmart for UNO");
   lcd.setCursor(2,2);
  lcd.print("SainSmart LCM IIC");
   lcd.setCursor(1,3);
  lcd.print("Design By SainSmart");
}

void loop()
{
}
