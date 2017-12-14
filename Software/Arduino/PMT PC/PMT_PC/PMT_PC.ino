//SainSmart
#include <Wire.h> 
//#include <LiquidCrystal_I2C_Due_Compatible.h>
//LiquidCrystal_I2C lcd(0x27,16,2);  // set the LCD address to 0x3F for a 16 chars and 2 line display

#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 2, 1, 0, 4, 5, 6, 7, 3, POSITIVE);  // Set the LCD I2C address


#include <Adafruit_MCP4725.h>

const int CMD_SET_GAIN = 01;
const int CMD_GET_GAIN = 02;
const int CMD_PMT_ON = 03;
const int CMD_PMT_OFF = 04;
const int CMD_RAMP_GAIN = 05;
const int CMD_INIT = 06;
const int CMD_GET_MONITOR = 07;

const int PIN_BUZZER = 12;
const int PIN_PMT_ERR = 11;
const int PIN_PMT_POWER = 10;
const int PIN_COOLER_ERR = 9;
const int PIN_COOLER_POWER = 8;

const int PIN_EMERGENCY_SHUTDOWN = 7;

const int PIN_MANUAL_PC = 6;
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

int desiredMV = 0;

void SetGain(int mV)
{
  // map the desired mV (0..800) to the dac output range...
  // a dac value of 4095 corresponds to 2.7V.
  if (mV > 900)
    mV = 900;
  if (mV < 0)
    mV = 0;
  float Volt = mV/1000.0;
  // 5V is mapped to 4095
  // 
  int dacValue = Volt/5.0 *4095.0;
  dac.setVoltage(dacValue, false); 
  //Serial.println("GAIN "+String(mV));
}

void rampGain(float mV)
{
  int currentGain = getVoltageMonitor();
  int numSteps = MAX(1, fabs(mV-currentGain)/50); // 50 mV increments.
  
  if (mV == 0)
  {
    SetGain(0);
    return;
  }
  
  if (currentGain < mV)
  {
    // ramp Up
    for (int k=0; k< numSteps;k++)
    {
      SetGain((float)mV/ (numSteps-1) * k);
    }
  } else 
  {
     // ramp down
   for (int k=0; k< numSteps;k++)
    {
      SetGain((float)mV/ (numSteps-1) * (numSteps-1-k));
    }
     
  }
  
}

void setupPins()
{
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_PMT_ERR, INPUT);
  pinMode(PIN_PMT_POWER, OUTPUT);  
  pinMode(PIN_COOLER_ERR, INPUT);
  pinMode(PIN_COOLER_POWER, OUTPUT);
  pinMode(PIN_EMERGENCY_SHUTDOWN, INPUT);
  pinMode(PIN_MANUAL_PC, INPUT);
  
  digitalWrite(PIN_BUZZER, LOW);
  digitalWrite(PIN_PMT_POWER, LOW);
}

void DisplayMessage(String s)
{
lcd.setCursor(0,0);
lcd.println(s + String("             "));
//Serial.println(s);
}

void setup() {
   Serial.begin(115200);
   DisplayMessage("Now starting up");  
   dac.begin(0x62);
   dac.setVoltage(0, false);
   setupPins();

     lcd.begin(16, 2);  // initialize the lcd for 16 chars 2 lines, turn on backlight
  lcd.backlight();
  lcd.setCursor(0, 0); //Start at character 4 on line 0

 /// lcd.init();                      // initialize the lcd 
 // lcd.init();                      // initialize the lcd 
 // lcd.backlight();
   
  DisplayMessage("PMT Controller");   
  lcd.setCursor(0,1);
  lcd.println("                 ");
  CoolerON();
  
  
   bool emergencyShutdown = !digitalRead(PIN_EMERGENCY_SHUTDOWN);
   if (emergencyShutdown)
   {
       
     lcd.setCursor(0,1);
     lcd.println("RED_BUTTON=>ON      ");
     while (digitalRead(PIN_EMERGENCY_SHUTDOWN) == 0)
     {
       digitalWrite(PIN_BUZZER, HIGH);
       delay(1000);
       digitalWrite(PIN_BUZZER, LOW);
       delay(2000);
     }
    lcd.setCursor(0,1);
    lcd.println("                 ");
     
   }

}



void PMT_High_VoltageON()
{
  
      //SetGain(0);
      
      digitalWrite(PIN_PMT_POWER, HIGH);
      /*
      int numSteps = 10;
       for (int k=0; k < numSteps; k++)
      {
        SetGain(desiredMV * ((float)k/(numSteps-1)));
        delay(10);
      }*/
}


void PMT_High_VoltageOFF()
{
  // Ramp Down
      // allow ~ 1 second to ramp up.  Each call to SetGain is 50 ms.
      /*
      int numSteps = 10;
      for (int k=0; k < numSteps; k++)
      {
        SetGain(desiredMV * (1.0-((float)k/(numSteps-1))));
      }
*/
      digitalWrite(PIN_PMT_POWER, LOW);
}

void CoolerON()
{
    digitalWrite(PIN_COOLER_POWER, HIGH);
}

void CoolerOFF()
{
  digitalWrite(PIN_COOLER_POWER, LOW);
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



unsigned long PMThighVoltageONtimestamp = 0;
unsigned long PMThighVoltageOFFtimestamp = 0;




int highVoltageFSM = 0;
int AutoCoolerFSM = 0;
int prev_manual_mode = -1;
float prev_manual_value = -100;
#define MAX_BUFFER 128
int buffer_index = 0;
char packetBuffer[MAX_BUFFER]; //buffer to hold incoming packet,



void fnHandleSerialCommunication()
{
  if (Serial.available() > 0) {
    // get incoming byte:
    char inByte = Serial.read();
    if (inByte == 10)
    { // new line
      packetBuffer[buffer_index] = 0;
      if (buffer_index > 0)
        apply_command();

      buffer_index = 0;

    } else {
      packetBuffer[buffer_index++] = inByte;
      if (buffer_index >= MAX_BUFFER - 1) {
        buffer_index = MAX_BUFFER - 1;
      }
    }
  }
}




byte apply_command()
{  
  long newGainValue;
  float Voltage;
  int command = (packetBuffer[0] - '0') * 10 + packetBuffer[1] - '0';
  switch (command)
  {
    case CMD_SET_GAIN:
      newGainValue = atoi(packetBuffer + 3);
      SetGain(newGainValue);
      Serial.println("OK! ");
      
      lcd.setCursor(0,1);
      lcd.println("PC: GAIN => " + String(newGainValue)+"                 ");
      
      break;
     case CMD_GET_GAIN:
      Serial.println("OK! "+String(getVoltageMonitor()));
      break;
     case CMD_PMT_ON:      
       PMT_High_VoltageON();
       Serial.println("OK! ");
       
      lcd.setCursor(0,1);
      lcd.println("PC: PMT ON                 ");
        
       break;
    case CMD_PMT_OFF:      
       PMT_High_VoltageOFF();
       Serial.println("OK! ");
       lcd.setCursor(0,1);
       lcd.println("PC: PMT OFF              ");
        
       break;       
    case CMD_RAMP_GAIN:
      newGainValue = atoi(packetBuffer + 3);
      rampGain(newGainValue);
       Serial.println("OK! ");
    lcd.setCursor(0,1);
       lcd.println("PC: GAIN => " + String(newGainValue)+"                 ");
        break;
     case CMD_INIT:
       SetGain(0);
       PMT_High_VoltageOFF();
         Serial.println("OK! ");
         lcd.setCursor(0,1);
       lcd.println("PC: PMT OFF            ");
       
       break;  
       case CMD_GET_MONITOR:
        Voltage = getVoltageMonitor();
       Serial.println(String(Voltage,4));
  }

}

int getVoltageMonitor()
{
  // Read current voltages
       long y = 0;
      for (int k=0;k<NUM_SAMPLES_TO_AVG;k++) {
        y += analogRead(PIN_VOLTAGE_MONITOR);
      }
      int PMT_gain_Monitor_mV = ((float)y/NUM_SAMPLES_TO_AVG) / 1023.0 * 5000;  
   return PMT_gain_Monitor_mV;
}

void loop() {
  bool emergencyShutdown = !digitalRead(PIN_EMERGENCY_SHUTDOWN);
  if (emergencyShutdown)
  {
    PMT_High_VoltageOFF();
    SetGain(0);
    Serial.println("EMERGENCY_SHUTDOWN_ON");
    lcd.setCursor(0,1);
    lcd.println("SHUTDOWN!           ");
    while (1)
    {
      if (digitalRead(PIN_EMERGENCY_SHUTDOWN) == 1)
        break;
    }
    lcd.setCursor(0,1);    
    lcd.println("                       ");    
    Serial.println("EMERGENCY_SHUTDOWN_OFF");
    prev_manual_mode = -1;
  }
  
  fnHandleSerialCommunication();
  
  // Read current voltages
   long x=0;
  for (int k=0;k<NUM_SAMPLES_TO_AVG;k++) {
    x += analogRead(PIN_MANUAL_GAIN);
  }
  desiredMV = ((float)x/NUM_SAMPLES_TO_AVG) / 1023.0 * 900; // map potentiometer value to [0,900]
  // max Vcont signal is 0.9V
  
  int ManualMode = digitalRead(PIN_MANUAL_PC);
  
  if (prev_manual_mode != ManualMode)
  {
     // Change in manual / PC Mode.
     // if Manual, turn PMT high voltage ON and ramp gain using potentiometer.
     prev_manual_mode = ManualMode;
     
     if (ManualMode)
     {
       PMT_High_VoltageON();
       rampGain(desiredMV);
       prev_manual_value = -100;
     } else
     {
       // PC Mode. First, turn off PMT
       SetGain(0);
       PMT_High_VoltageOFF();
       lcd.setCursor(0,1);    
       lcd.println("PC MODE                ");    
       
     }
     
  }
  
  if (ManualMode)
  {
  
    if  ( ( fabs(prev_manual_value - desiredMV) >= 2) || (desiredMV <= 10 && prev_manual_value != 0) )
    {
      if (desiredMV <= 10)
      {
        PMT_High_VoltageOFF();
        desiredMV = 0;
      } else
      {
          PMT_High_VoltageON();      
      }
      prev_manual_value = desiredMV;
      
      SetGain(desiredMV);
     
      lcd.setCursor(0,1);
      if (desiredMV == 0)
          lcd.println("PMT OFF                 ");
        else {
           lcd.println("MON:" + String(getVoltageMonitor())  +"=>"+ String(desiredMV)+"         ");
        }
    }
    
  } else
  {
    // PC Mode 
    
  }
  

  
  beepFSM();
    
//  Serial.println(String(int(dacValueToVoltage(manualPMTdacValue))));

  int err1 = digitalRead(PIN_PMT_ERR);
  int err2 = digitalRead(PIN_COOLER_ERR);
  
  if (err1 && err2)
  {
   // Serial.println("Both PMT error and Cooler errors");
    beep(3);
  } else if (err1)
    {
    //Serial.println("only PMT error");      
      beep(2);
    } else
    if (err2)
    {
   // Serial.println("only cooler error");            
      beep(1);
    }
 
  
}
