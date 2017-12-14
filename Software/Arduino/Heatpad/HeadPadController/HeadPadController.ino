#include <LiquidCrystal.h>


#include <Wire.h> 

LiquidCrystal_I2C lcd(0x3F,20,2);  // set the LCD address to 0x3F for a 16 chars and 2 line display

int state = 0;
long time;
const int NUM_AVG = 100;
const float MeanTargetTemperature = 35;
const int RELAY_PIN = 5;
const int LED_PIN = 6;
const int SENSOR_PIN = 6;
const int KNOB_PIN = 2;
const float margin_temp = 0;
const long UPDATE = 20000; // 20 seconds  intervals...

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  
  lcd.init();                      // initialize the lcd 
  lcd.init();
  // Print a message to the LCD.
  lcd.backlight();
  lcd.setCursor(0,0);
  lcd.print("Init...");
  pinMode(RELAY_PIN,OUTPUT);
  pinMode(LED_PIN,OUTPUT);
 
}

float prevTemp = 0;
long t0 = millis();
void loop() {
  
  // Read out temperature
  float avg_temp = 0;
  for (int k=0;k<100;k++)
  {
    int v = analogRead(SENSOR_PIN);
    float tmp = (  (float)v/1024.0 * 5.0 * 1000 - 500) / 10;
    avg_temp += tmp;
  }
  avg_temp /= NUM_AVG;
  
  int v2 = analogRead(KNOB_PIN);
  bool keypressed = false;
  float desiredTemp = MeanTargetTemperature + (v2/1024.0 * 10 - 5);
  if ( abs(prevTemp-desiredTemp) > 1) 
  {
    keypressed= true;
    prevTemp = desiredTemp; 
  }
  
    
    lcd.setCursor(0,0);    
    lcd.print("Curr: "+String(avg_temp,1)+" C Deg  ");
    lcd.setCursor(0,1);
    lcd.print("Goal: "+String(desiredTemp,0)+" C Deg  ");
  
  
  if ((millis()-t0 > UPDATE) || keypressed)
  {
    Serial.println("Updating...");
  if (avg_temp > desiredTemp) 
  {
    // we reached our desired temperature. Turn off relay.
    digitalWrite(RELAY_PIN,LOW);
    digitalWrite(LED_PIN,LOW);
  } else if (avg_temp < desiredTemp)
  {
    // temperature is below our target temperature. Turn on relay.
    digitalWrite(RELAY_PIN,HIGH);
    digitalWrite(LED_PIN,HIGH);
  }
  
    t0 = millis();
  }
  
}
