#include <Wire.h> 
#include "LiquidCrystal_I2C_Due_Compatible.h"
LiquidCrystal_I2C lcd(0x3F,20,2);  // set the LCD address to 0x3F for a 16 chars and 2 line display

#define DACaddr                         (0x62)  // I2C address of 4726 DAC (second is at 63)
#define MCP4726_CMD_WRITEDAC            (0x40)  // Writes data to the DAC
#define MCP4726_CMD_WRITEDACEEPROM      (0x60)  // Writes data to the DAC and the EEPROM (persisting the assigned value after reset)

const int TOGGLE_SWITCH = 12;
const int BUZZER_PIN = 11;
const int KNOB_PIN = 3;
const int FEEDBACK_PIN = 2;
const int MAX_OUTPUT_VOLTAGE = 8000;
const float MAX_VOLTAGE = 1.2;
const int MAX_DAQ_VALUE = MAX_VOLTAGE/5.0 * 4095;

void setDAC( uint16_t output)
{
  if (output > MAX_DAQ_VALUE) {
    output = MAX_DAQ_VALUE;
  }
  if (output < 0)
    output = 0;
  Wire.beginTransmission(DACaddr);  // select DAC0, 1, etc
  Wire.write((MCP4726_CMD_WRITEDAC));
  Wire.write(output / 16);                   // Upper data bits          (D11.D10.D9.D8.D7.D6.D5.D4)
  Wire.write((output % 16) << 4);            // Lower data bits          (D3.D2.D1.D0.x.x.x.x)
  Wire.endTransmission();
}

void setup()
{
  Serial.begin(115200);
   lcd.init();
 lcd.init();
 lcd.backlight();
 lcd.setCursor(0,0);
 pinMode(TOGGLE_SWITCH, INPUT);
 pinMode(BUZZER_PIN,OUTPUT);
 digitalWrite(BUZZER_PIN,LOW);
 Wire.begin();
 setDAC(0);
 if (digitalRead(TOGGLE_SWITCH) == 1)
 {
    lcd.print("Turn off switch");
    while (digitalRead(TOGGLE_SWITCH) == 1);
    lcd.setCursor(0,0);  
    lcd.print("                 ");
 }
}

void loop()
{
  // knob-value range is between 0V and MAX_VOLTAGE
  float knob_value = 0;
  float feedback = 0;
  for (int k=0;k<100;k++) {
    knob_value+=analogRead(KNOB_PIN);
    feedback += analogRead(FEEDBACK_PIN);
  }
  knob_value/= (100.0 * 1023.0);
  feedback /= (100.0 * 1023.0);
 int feedbackmV = feedback * 5.0 * 1000.0 * 2.0 * 0.95; // voltage divider
 int switchValue = digitalRead(TOGGLE_SWITCH);
 Serial.print(millis());
 Serial.print(" ");
 Serial.print(switchValue);
 Serial.print(" ");
 Serial.println(knob_value);
 if (feedbackmV > MAX_OUTPUT_VOLTAGE)
 {
    setDAC(0);
    lcd.setCursor(0,1);
    lcd.print("Turn down gain!");

    unsigned long t0=millis()-1000;
    bool buzzerState = 0;
    while(1)
    {
      knob_value = 0;
      for (int k=0;k<100;k++) {
        knob_value+=analogRead(KNOB_PIN);
      }
      knob_value/= (100.0 * 1023.0);
      int mV = knob_value*MAX_VOLTAGE*1000;
      int mVround = 5*(mV/5);
      lcd.setCursor(0,0);
      lcd.print("GAIN: " + String(mVround)+"    ");
      
      if (mVround == 0)
       break;

      if (millis() - t0 > 1000)
      {
          buzzerState = !buzzerState;
          digitalWrite(BUZZER_PIN,buzzerState?HIGH:LOW);
          t0=millis();
      }
    }
    digitalWrite(BUZZER_PIN,LOW);
 }

 int mV = knob_value*MAX_VOLTAGE*1000;
 int mVround = 5*(mV/5);
 int daqValue = mVround/1000.0/5.0 * 4095;
 if (switchValue) 
 {
    setDAC(daqValue);
    lcd.setCursor(0,0);
    lcd.print("GAIN: " + String(mVround)+"    ");
    lcd.setCursor(0,1);
    lcd.print("Output: " + String(feedbackmV)+"    ");
 }
 else {
    setDAC(0);
  
    lcd.setCursor(0,0);
    lcd.print("GAIN: DISABLED");
    lcd.setCursor(0,1);
    lcd.print("Output: " + String(feedbackmV)+"    ");
 }
 
}
