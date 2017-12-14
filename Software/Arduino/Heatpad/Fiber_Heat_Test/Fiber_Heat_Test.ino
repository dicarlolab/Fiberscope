#include <Wire.h> 
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x3F,20,4);  // set the LCD address to 0x3F for a 16 chars and 2 line display

int state = 0;
long time;
const int NUM_AVG = 100;
const float MeanTargetTemperature = 35;
const int RELAY_PIN = 5;
const int LED_PIN = 6;
const int SENSOR_PIN = 6;
const int KNOB_PIN = 2;
const float margin_temp = 0;

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
  Serial.begin(115200);
    digitalWrite(RELAY_PIN,LOW);
    digitalWrite(LED_PIN,LOW);
  
}

long t0 = millis();
long t1=millis();
bool ON=false;
void loop() {
  long t = millis();
  if (!ON)
  {
    if ( (t-t0) > 60000) {
      Serial.println(String(t-t0));
      Serial.println("TURNING ON!");
      digitalWrite(RELAY_PIN,HIGH);
      digitalWrite(LED_PIN,HIGH);
      ON = true;
      t0=millis();
    }
  } 
  
  
  if (ON) {
    if ( (t-t0) > 60000)
    {
      Serial.println("TURNING OFF!");      
      digitalWrite(RELAY_PIN,LOW);
      digitalWrite(LED_PIN,LOW);
      ON  = false;
      t0=millis();
    }
  }
 if (t-t1 > 1000)
{ 
 // Read out temperature
  float avg_temp = 0;
  for (int k=0;k<100;k++)
  {
    int v = analogRead(SENSOR_PIN);
    float tmp = (  (float)v/1024.0 * 5.0 * 1000 - 500) / 10;
    avg_temp += tmp;
  }
  avg_temp /= NUM_AVG;
  lcd.setCursor(0,0);
  lcd.print("Curr: "+String(avg_temp,1)+" C Deg  ");
  t1=millis();
}

}
