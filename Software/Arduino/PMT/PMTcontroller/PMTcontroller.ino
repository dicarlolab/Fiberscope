//SainSmart
#include <Wire.h> 
#include <LiquidCrystal_I2C_Due_Compatible.h>
LiquidCrystal_I2C lcd(0x27,16,2);  // set the LCD address to 0x3F for a 16 chars and 2 line display


#include <Adafruit_MCP4725.h>


const int PIN_BUZZER = 12;
const int PIN_PMT_ERR = 11;
const int PIN_PMT_POWER = 10;
const int PIN_COOLER_ERR = 9;
const int PIN_COOLER_POWER = 8;
const int PIN_PMT_VOLTAGE_SWITCH = 7;
const int PIN_PMT_MANUAL_GAIN_SWITCH = 6;
const int PIN_VOLTAGE_MONITOR = 0;
const int PIN_MANUAL_GAIN = 1;

const float COOLER_STARTUP_TIME_MIN = 1;
const float GAIN_SPEED_MS = 0.1; // 1 ms per one DAC increment. 
const float AUTO_COOLER_OFF_MIN = 30;

const int BEEP_DURATION_MS = 500;
const int BEEP_INTER_DURATION_MS = 2000;

const int NUM_SAMPLES_TO_AVG = 50;
#define MAX(a,b)((a)>(b))?(a):(b)
#define MIN(a,b)((a)>(b))?(b):(a)

Adafruit_MCP4725 dac;

float dacValueToVoltage(int X)
{
  // X is between 0 and 4095
  // return value is in mV
  return MAX(0,0.2194 * X -12.3901);
}

int  VoltageToDac(float mV)
{
  // returns the closest integer for a given mV value
  return MIN(4095,MAX(0,mV*4.5580+56.5600));
}

// Calibrate input-output voltages using voltage divider circuit 
void calibrateVoltages()
{
   for (int k=0; k< 4095;k+=10)
  {
        SetVoltage(k);
        delay(5);
        long v=0;
        for (int i=0;i<1000;i++)
        {
          v+=analogRead(0);
        }
        v/=1000;
        Serial.println(String(k) + "," + String(v/1023.0 * 5 * 1000)+String(";"));
  }
}

void setupPins()
{
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_PMT_ERR, INPUT);
  pinMode(PIN_PMT_POWER, OUTPUT);  
  pinMode(PIN_COOLER_ERR, INPUT);
  pinMode(PIN_COOLER_POWER, OUTPUT);
  pinMode(PIN_PMT_VOLTAGE_SWITCH, INPUT);
  pinMode(PIN_PMT_MANUAL_GAIN_SWITCH, INPUT);
  
  digitalWrite(PIN_BUZZER, LOW);
  digitalWrite(PIN_PMT_POWER, LOW);
  digitalWrite(PIN_COOLER_POWER, LOW);
  
  
}

void DisplayMessage(String s)
{
lcd.setCursor(0,0);
lcd.println(s + String("             "));
Serial.println(s);
}

void setup() {
   Serial.begin(9600);
   DisplayMessage("Now starting up");  
   dac.begin(0x62);
    SetVoltage(0);
   setupPins();
   
  // put your setup code here, to run once:
  lcd.init();                      // initialize the lcd 
  lcd.init();                      // initialize the lcd 
  // Print a message to the LCD.
  lcd.backlight();
   
  DisplayMessage("PMT Controller");   
  //calibrateVoltages();
lcd.setCursor(0,1);
lcd.println("                 ");
  
}

int beep_state = 0;
long beep_time = 0;
int beep_type_state;
void beep(int beep_type)
{
  if (beep_state == 0) {
    beep_state = 1;
    beep_type_state = beep_type;
  }
}

void beepFSM()
{
  if (beep_state == 1)
  {
    beep_state = 2;
    beep_time = millis();
    digitalWrite(PIN_BUZZER, HIGH);
  }
  
  if (beep_state == 2)
  {
    if (millis()-beep_time > beep_type_state*BEEP_DURATION_MS)
    {
      digitalWrite(PIN_BUZZER, LOW);
      beep_state = 3;
      beep_time = millis();
    }
  }
  if (beep_state == 3)
  {
   if (millis()-beep_time > BEEP_INTER_DURATION_MS)
   {
     beep_state = 0;
   }
     
  }
  
  
  
}

int prev_dac_value = 0;
int gainUSB = 0;

int gain_state = 0;
int gain_value_goal = 0;

unsigned long gain_timer;
int prev_value = -1;
void setGain(int value)
{
  if ( abs(gain_value_goal - value) > 100)
  {
    gain_value_goal = value;
    gain_state = 1;
  } else
  {
    if (prev_value != value)
    {
//      lcd.setCursor(0,1);
//      lcd.print("Gain =  "+String(int(dacValueToVoltage(value)))+String("    "));    
      SetVoltage(value);
      Serial.println("Gain is now " + String(value));
      prev_value = value;
    }
  }
  
}

void SetVoltage(int x)
{
  Serial.println("DAC => "+String(x) + "    " + String(int(dacValueToVoltage(gain_value_goal))));    
  dac.setVoltage(x, false);
}

void gainFSM()
{
  if (gain_state == 1)
  {
    // slowly ramp up/down gain until we reach intended value...   
//    lcd.setCursor(0,1);
//    lcd.print("Gain => "+String(int(dacValueToVoltage(gain_value_goal)))+String("    "));    
    Serial.println("Gain is now " + String(prev_dac_value) + ". Now setting new gain value of " + String(gain_value_goal));
    gain_state = 2;
  }
  
  if (gain_state == 2)
  {
      if ( abs(gain_value_goal- prev_dac_value) <= 100)
      {
        // nothing to do here (?)
//       lcd.setCursor(0,1);
//       lcd.print("Gain =  "+String(int(dacValueToVoltage(gain_value_goal)))+String("    "));    

        Serial.println("Gain goal (" + String(gain_value_goal)+") has been reached");
        gain_state = 0;
        
        if (gain_value_goal == 0)
        {
          SetVoltage(0);
          prev_dac_value = 0;
        }
        
      } else if (gain_value_goal > prev_dac_value)    
      {
        prev_dac_value = prev_dac_value + 100;
        SetVoltage(prev_dac_value);
        gain_timer = millis();
        gain_state = 3;
      } else if (gain_value_goal < prev_dac_value)    
      {
        prev_dac_value = prev_dac_value - 100;
        SetVoltage(prev_dac_value);
        gain_timer = millis();
        gain_state = 3;
      }
      
      
  }
  
  if (gain_state == 3)
  {
    if (millis()- gain_timer > GAIN_SPEED_MS)
    {
      gain_state = 2;
    }
    
  }
}

bool prevHighVoltageMode = false;
unsigned long PMThighVoltageONtimestamp = 0;
unsigned long PMThighVoltageOFFtimestamp = 0;


int CoolerState = 0;
unsigned long CoolerONtimestamp = 0;
unsigned long CoolerOFFtimestamp = 0;
void CoolerON()
{
  if (CoolerState == 0)
  {
   DisplayMessage("Cooling is ON");
    
    Serial.println("Now turning cooling device ON");
    digitalWrite(PIN_COOLER_POWER, HIGH);
    CoolerONtimestamp = millis();
    CoolerState = 1;
  }
}

bool isCoolerON()
{
  return CoolerState == 1;
}

float CoolerONelapsedTime()
{
  if (!isCoolerON())
    return 0;
  
  return (millis()-CoolerONtimestamp)/1000.0/60.0;
}

void CoolerOFF()
{
   DisplayMessage("Cooling is OFF");
  Serial.println("Now turning cooling device OFF");
  digitalWrite(PIN_COOLER_POWER, LOW);
  CoolerOFFtimestamp = millis();
  CoolerState = 0;
}

int highVoltageFSM = 0;
int AutoCoolerFSM = 0;
int prev_manualPMTdacValue = -1;
void loop() {
  
   long x=0;
   long y = 0;
  for (int k=0;k<NUM_SAMPLES_TO_AVG;k++) {
    x += analogRead(PIN_MANUAL_GAIN);
    y += analogRead(PIN_VOLTAGE_MONITOR);
  }
  int PMT_gain_Monitor_mV = ((float)y/NUM_SAMPLES_TO_AVG) / 1023.0 * 5000;  
  
  int manualPMTdacValue = ((float)x/NUM_SAMPLES_TO_AVG) / 1023.0 * 4095.0;
  int manual_gain_mode = digitalRead(PIN_PMT_MANUAL_GAIN_SWITCH);
  bool highVoltageMode = digitalRead(PIN_PMT_VOLTAGE_SWITCH);

  int manualPMT_mV = dacValueToVoltage(manualPMTdacValue);
  lcd.setCursor(0,1);
  lcd.println("Gain:" + String(PMT_gain_Monitor_mV)  +"=>"+ String(manualPMT_mV) + "       ");
  
  if (prev_manualPMTdacValue != manualPMTdacValue)
  {
//    lcd.setCursor(0,1);
//    lcd.println("Gain => "+String((int)dacValueToVoltage(manualPMTdacValue)) + String("        "));
    prev_manualPMTdacValue=manualPMTdacValue;
    
  }
  
  if (prevHighVoltageMode == 0 && highVoltageMode)
  {
    // Start the sequence of turning the high voltage PMT ON
    DisplayMessage("PMT start sequence");
     prevHighVoltageMode = true;
     PMThighVoltageONtimestamp = millis();
     CoolerON();
     AutoCoolerFSM = 0;
   }
 
  if (highVoltageMode && highVoltageFSM == 0)
  {
    // has cooler been on for at least 3 minutes ?
    // if so, we can safely turn on the PMT and then adjust gain.
    if (CoolerONelapsedTime() > COOLER_STARTUP_TIME_MIN) {
      DisplayMessage("PMT now ON");
      digitalWrite(PIN_PMT_POWER, HIGH);
      int desiredGain = manual_gain_mode ? manualPMTdacValue : gainUSB;
      setGain(desiredGain);
      highVoltageFSM = 1;  
    } else
    {
      lcd.setCursor(0,0);
      int perc_left = (COOLER_STARTUP_TIME_MIN-CoolerONelapsedTime())/COOLER_STARTUP_TIME_MIN * 100;
      lcd.print("Cool Wait:"+String(perc_left) +"       ");
    }
  }   
  
   if (highVoltageMode && highVoltageFSM == 1) 
   {
        int desiredGain = manual_gain_mode ? manualPMTdacValue : gainUSB;
        setGain(desiredGain);
   }

  gainFSM();
  
  if (prevHighVoltageMode == 1 && !highVoltageMode)
  {
     // Shut PMT OFF
     DisplayMessage("PMT stop sequence!");
     Serial.println("PMT high voltage shut down sequence started");
      prevHighVoltageMode = false;
      highVoltageFSM = 1;
     setGain(0);
  }
  
  if (prev_dac_value == 0 && !highVoltageMode && highVoltageFSM == 1)
  {
     DisplayMessage("PMT is OFF");
     
      Serial.println("Gain is now at zero.");
      Serial.println("Turning off high voltage");
      PMThighVoltageOFFtimestamp = millis();
      digitalWrite(PIN_PMT_POWER, LOW);
      highVoltageFSM = 0;
  }
  
  
  float minSincePMThighVoltageOFF = (millis()-PMThighVoltageOFFtimestamp)/1000.0/60.0;  
  if (!highVoltageMode && minSincePMThighVoltageOFF > AUTO_COOLER_OFF_MIN && AutoCoolerFSM == 0 && highVoltageFSM == 0)
  {
  
    Serial.println("Auto cooling shut down");
    CoolerOFF();
    AutoCoolerFSM = 1;
  }
  
  
  beepFSM();
    
//  Serial.println(String(int(dacValueToVoltage(manualPMTdacValue))));

  int err1 = digitalRead(PIN_PMT_ERR);
  int err2 = digitalRead(PIN_COOLER_ERR);
  
  if (err1 && err2)
  {
    Serial.println("Both PMT error and Cooler errors");
    beep(3);
  } else if (err1)
    {
    Serial.println("only PMT error");      
      beep(2);
    } else
    if (err2)
    {
    Serial.println("only cooler error");            
      beep(1);
    }
 
  
}
