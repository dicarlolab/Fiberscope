#define MAX(a,b)(a>b)?(a):(b)

const int AnalogToDigitalThreshold = 500;
const int START_BUTTON_PIN = 10;
const int RESET_BUTTON_PIN = 9;

const int VOLUME_BUTTON_APIN = 0;
const int SPEED_BUTTON_APIN = 1;
const int MODE_BUTTON_APIN = 2;

const int BUZZER_PIN = 13;

const int MOTOR_ENABLE_PIN = 6;
const int MOTOR_DIRECTION_PIN = 7;
const int MOTOR_STEP_PIN = 8;

const int DOWN_DIRECTION = 1;

const int LCD_PIN_RS = 12;
const int LCD_PIN_E = 11;
const int LCD_PIN_D4 = 5;
const int LCD_PIN_D5 = 4;
const int LCD_PIN_D6 = 3;
const int LCD_PIN_D7 = 2;

const int SYRINGE_TYPE_PIN = 14;
const int RESET_VOLUME_PIN = 15;

const int QUANTITY_PIN = 16;
const int SPEED_PIN = 17;


const int NUM_SYRINGE_TYPES = 4;
const long SYRINGE_VOLUMES_NL[NUM_SYRINGE_TYPES] = {3000,5000,10000,50000};
const long SYRINGE_LENGTH_UM[NUM_SYRINGE_TYPES] = {16000,55450,55450,55450};

const int NUM_QUANTITIES_PRESETS = 16;
const int NUM_SPEEDS_PRESETS = 13;
const long QUANTITIES_TO_INJECT[NUM_QUANTITIES_PRESETS]={25,50, 100, 200, 250, 500, 750, 1000, 1250, 1500, 2000, 2500, 3000, 3500, 4000, 5000};
const long SPEEDS_NL_PER_MINUTE[NUM_SPEEDS_PRESETS] = {10, 25, 50, 80, 100, 150, 200, 250, 400, 500, 1000, 1500, 2000};
 
const long MOTOR_TTL_USEC = 150; // minimal time for motor to respond to step commands
const long MOTOR_TTL_USEC_FAST = 60;

const double FullRotationInUM = 254; // 254 micron per revolusion, 100 TPI
const double StepAngleDeg = 0.176 / 8.0;
const double OneDegreeInUM = FullRotationInUM/360;
const double OneStepInUM = StepAngleDeg * OneDegreeInUM;
const double OneMicronInSteps = 1.0/OneStepInUM;

long syringeType = 0;
long motorPosition = 0;
long quantityPreset = 0;
double amountInjectedNL = 0;
long speedPreset = 0;
int mode = 0;
int mode_direction = 0;
int volume_button_state = 0;
int speed_button_state = 0;
int reset_button_state = 0;

// include the library code:
#include <LiquidCrystal.h>

LiquidCrystal lcd(LCD_PIN_RS,LCD_PIN_E,LCD_PIN_D4,LCD_PIN_D5,LCD_PIN_D6,LCD_PIN_D7);



/*
#include <EEPROM.h>


int EEPROM_writeLong(int ee, const long& value)
{
    const byte* p = (const byte*)(const void*)&value;
    unsigned int i;
    for (i = 0; i < sizeof(value); i++)
          EEPROM.write(ee++, *p++);
    return i;
}

 int EEPROM_readLong(int ee, long& value)
{
    byte* p = (byte*)(void*)&value;
    unsigned int i;
    for (i = 0; i < sizeof(value); i++)
          *p++ = EEPROM.read(ee++);
    return i;
}

void  readVariablesFromROM()
{
  int i=0;
  i+=EEPROM_readLong(i, motorPosition);
  i+=EEPROM_readLong(i, syringeType);
  i+=EEPROM_readLong(i, quantityPreset);  
  i+=EEPROM_readLong(i, amountInjectedNL);  
  i+=EEPROM_readLong(i, speedPreset);  
}


void  writeVariablesToROM()
{
  int i=0;
  i+=EEPROM_writeLong(i, motorPosition);
  i+=EEPROM_writeLong(i, syringeType);
  i+=EEPROM_writeLong(i, quantityPreset);  
  i+=EEPROM_writeLong(i, amountInjectedNL);  
  i+=EEPROM_writeLong(i, speedPreset);  
}
*/

void setup() {
  Serial.begin(115200);
  Serial.println("Initializing...");
  
  // put your setup code here, to run once:
  lcd.begin(20, 4);
  lcd.cursor();
  pinMode(START_BUTTON_PIN, INPUT);
  
  pinMode(RESET_BUTTON_PIN, INPUT);

  
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN,LOW);
  pinMode(MOTOR_ENABLE_PIN, OUTPUT);
  pinMode(MOTOR_DIRECTION_PIN, OUTPUT);
  pinMode(MOTOR_STEP_PIN, OUTPUT);

  digitalWrite(MOTOR_ENABLE_PIN, HIGH);
  mode = analogRead(MODE_BUTTON_APIN) > AnalogToDigitalThreshold;

SelectSyringe();
    UpdateScreen();

}


void SelectSyringe()
{
 lcd.clear();
  long x = millis();
 Serial.println("Waiting for input");

    lcd.setCursor(0, 0);
    lcd.print("Select Syringe Type");


  bool prev_volume_button_state = analogRead(VOLUME_BUTTON_APIN) > AnalogToDigitalThreshold;
  bool prev_speed_button_state = analogRead(SPEED_BUTTON_APIN) > AnalogToDigitalThreshold;
 
  while (millis() - x < 5000)
  {
      long syringeVolumeUL = SYRINGE_VOLUMES_NL[syringeType]/1000;
      lcd.setCursor(0, 1);
      lcd.print(String(syringeVolumeUL)+"ul Syringe   ");

      volume_button_state = analogRead(VOLUME_BUTTON_APIN) > AnalogToDigitalThreshold;
      if (volume_button_state != prev_volume_button_state)
      {
        prev_volume_button_state = volume_button_state ;
        syringeType = syringeType + 1;
        if (syringeType >= NUM_SYRINGE_TYPES)
            syringeType = 0;
        delay(50);            
        x = millis();          
      }
    
      speed_button_state =  analogRead(SPEED_BUTTON_APIN) > AnalogToDigitalThreshold;
      if (speed_button_state != prev_speed_button_state)
      {
          prev_speed_button_state = speed_button_state ;
          syringeType = syringeType - 1;
          if (syringeType < 0)
            syringeType = NUM_SYRINGE_TYPES-1;
          delay(50);
          x = millis(); 
          
      }
    
  }
  Serial.println("Finishing Syringe Selection");
}

void UpdateScreen()
{
  lcd.clear();
  
  if ( mode == 0)
{

  long syringeVolumeUL = SYRINGE_VOLUMES_NL[syringeType]/1000;
 long amountToInjectNL = QUANTITIES_TO_INJECT[quantityPreset];
lcd.setCursor(0, 0);
lcd.print(String(syringeVolumeUL)+"ul Syringe");
lcd.setCursor(0, 1);
lcd.print(String(amountToInjectNL)+"nl to inject");
lcd.setCursor(0, 2);
lcd.print(String(SPEEDS_NL_PER_MINUTE[speedPreset])+"nl/min");
lcd.setCursor(0, 3);
lcd.print(String(amountInjectedNL,0)+" injected");


Serial.println(String(syringeVolumeUL)+"ul Syringe");
Serial.println(String(amountToInjectNL)+"nl to inject");
Serial.println(String(SPEEDS_NL_PER_MINUTE[speedPreset])+"nl/min");
Serial.println(String(amountInjectedNL,0)+" injected");

} else
{
  lcd.setCursor(0, 0);
    lcd.print("MANUAL MODE!!!");
  lcd.setCursor(0, 1);  
  if (mode_direction)
    lcd.print("PLUNGER UP");
  else
    lcd.print("PLUNGER DOWN");

  lcd.setCursor(0, 2);  
  lcd.print(String(amountInjectedNL/1000) + " ul withdrawn   ");

  Serial.println("MANUAL MODE!!!");
  if (mode_direction)
    Serial.println("PLUNGER UP");
  else
    Serial.println("PLUNGER DOWN");
  
}

}

void StartInjection() 
{
  long syringeVolumeNL = SYRINGE_VOLUMES_NL[syringeType];
  long syringeLengthUM = SYRINGE_LENGTH_UM[syringeType];
  
  long amountToInjectNL = QUANTITIES_TO_INJECT[quantityPreset];
  double speedNLperSec = SPEEDS_NL_PER_MINUTE[speedPreset]/60.0;
      
  double OneNanoLiterInUM = double(syringeLengthUM)/double(syringeVolumeNL);
  double OneNanoLiterInSteps = OneNanoLiterInUM * OneMicronInSteps;
  double OneStepInNanoLiter = 1.0/OneNanoLiterInSteps;

  
  double NanoliterLeftToInject = amountToInjectNL - amountInjectedNL;
  // translate that to steps
  // make sure num steps is a multiple of 8!  
  long NumSteps = floor(NanoliterLeftToInject * OneNanoLiterInSteps / 8)*8;

  
  
  Serial.println("OneNanoLiterInUM:"+String(OneNanoLiterInUM,5));
  Serial.println("OneNanoLiterInSteps:"+String(OneNanoLiterInSteps,5));
  Serial.println("OneStepInNanoLiter:"+String(OneStepInNanoLiter,5));

  Serial.println("One Microliter Liter In UM:"+String(1000*OneNanoLiterInUM,5));  
  Serial.println("Num Steps:"+String(NumSteps));
 
  double StepsPerSeconds = speedNLperSec * OneNanoLiterInSteps;
  double InterStepTimeUsec = 1000000.0/StepsPerSeconds;
  // translate speed (nl/sec) to steps / sec and find the inter-step interval
  
  digitalWrite(MOTOR_DIRECTION_PIN, DOWN_DIRECTION ? HIGH : LOW);
  digitalWrite(MOTOR_ENABLE_PIN, LOW);
  long Counter = 0;
 bool aborted = false;
 long t0;
 int st=0;
  while (true)
  {
    digitalWrite(MOTOR_STEP_PIN, HIGH);
    delayMicroseconds(MOTOR_TTL_USEC);
    digitalWrite(MOTOR_STEP_PIN, LOW);
    delayMicroseconds(MAX(MOTOR_TTL_USEC, InterStepTimeUsec-MOTOR_TTL_USEC));
    Counter++;
    amountInjectedNL += OneStepInNanoLiter;
    motorPosition++;

    if (Counter%3500 == 0)
    {
      digitalWrite(BUZZER_PIN,HIGH);
    }
    if (Counter%3510 == 0)    
    {
      digitalWrite(BUZZER_PIN,LOW);
    }
    
    if (Counter%500==0)
    {
       UpdateScreen(); 
    }
    
    if (Counter >= NumSteps)
    {
      // finished injecting the desired volume
      break;
    }
    
    if (digitalRead(START_BUTTON_PIN) == false && st == 0)
    {
     t0=millis();
     st=1;
    }
    
    if (digitalRead(START_BUTTON_PIN) && st == 1)
    {
     st=0;
    }    
    
    if (st == 1 && millis()-t0 > 500)
    {    
      // user aborted.
      aborted = true;
      break;
    }
    
  }

  digitalWrite(MOTOR_ENABLE_PIN, HIGH);
  lcd.clear();
  int numbeeps = 3;
  
      lcd.setCursor(0, 0);
      if (aborted) {
      lcd.print("ABORTED");
      numbeeps = 0;
      }
      else {
      lcd.print("FINISHED");
      numbeeps = 3;
      }


  for (int k=0;k<3;k++)
  {
     digitalWrite(BUZZER_PIN,HIGH);
       delay(500);    
       digitalWrite(BUZZER_PIN,LOW);
       delay(500);    
  }

   long timeElapsed=millis();
   while (digitalRead(START_BUTTON_PIN))
   {
        lcd.setCursor(0, 0);
      double secondsElapsed = (millis()-timeElapsed)/1000.0;
      double minutesElapsed = (millis()-timeElapsed)/1000.0/60.0;      
      if (minutesElapsed < 1)
        lcd.print("FINISHED "+String(secondsElapsed)+" sec   ");       
      else
        lcd.print("FINISHED "+String(minutesElapsed)+" min   ");       
        
      delay(100);  
   }
   
   digitalWrite(BUZZER_PIN,LOW);
    UpdateScreen();   
//   writeVariablesToROM();
   delay(100);
}

void updateButtons()
{

   int new_reset_button_state = digitalRead(RESET_BUTTON_PIN);
   if (new_reset_button_state != reset_button_state)
   {
       reset_button_state = new_reset_button_state;
       amountInjectedNL = 0;
       UpdateScreen();   
   }

   int new_mode = analogRead(MODE_BUTTON_APIN) > AnalogToDigitalThreshold;
   if (new_mode != mode)
   {
       mode = new_mode;
       UpdateScreen();     
   }
   
//    int new_volume_button_state = digitalRead(VOLUME_BUTTON_PIN);
    int new_volume_button_state = analogRead(VOLUME_BUTTON_APIN)>AnalogToDigitalThreshold;
    if (volume_button_state != new_volume_button_state)
    {
      volume_button_state=new_volume_button_state;
      if (mode == 0)
      {
        quantityPreset++;
        if (quantityPreset >= NUM_QUANTITIES_PRESETS)
           quantityPreset = 0;
      } else
      {
        // set manual movement plunger direction
        mode_direction = 0;
         digitalWrite(MOTOR_DIRECTION_PIN, HIGH);
         
      }
      
      UpdateScreen();     
      delay(500);
    }
   
   

//    int new_speed_button_state = digitalRead(SPEED_BUTTON_PIN);
    int new_speed_button_state = analogRead(SPEED_BUTTON_APIN) > AnalogToDigitalThreshold;
    if (speed_button_state != new_speed_button_state)
    {
      speed_button_state=new_speed_button_state;      
      if (mode == 0)
        {
          speedPreset++;
          if (speedPreset >= NUM_SPEEDS_PRESETS)
             speedPreset = 0;
        } else
        {
            mode_direction = 1;
          digitalWrite(MOTOR_DIRECTION_PIN, LOW);
             
            
        }
     
      UpdateScreen();     
      delay(500);
    }   
     
}

void ManualMode()
{
  // move motor up/down....
         
      int motorstepunit = (  mode_direction == 0) ? 1 : -1;
      UpdateScreen();
      
    if (  mode_direction == 0)
         digitalWrite(MOTOR_DIRECTION_PIN, HIGH);
     else
         digitalWrite(MOTOR_DIRECTION_PIN, LOW);
       
      int buzzerCounter = 0;
      digitalWrite(MOTOR_ENABLE_PIN, LOW);

      updateButtons();
      
  long syringeVolumeNL = SYRINGE_VOLUMES_NL[syringeType];
  long syringeLengthUM = SYRINGE_LENGTH_UM[syringeType];
  
  double OneNanoLiterInUM = double(syringeLengthUM)/double(syringeVolumeNL);
  double OneNanoLiterInSteps = OneNanoLiterInUM * OneMicronInSteps;
  double OneStepInNanoLiter = 1.0/OneNanoLiterInSteps;

      
      while (digitalRead(START_BUTTON_PIN))
      {
         
         
         digitalWrite( MOTOR_STEP_PIN,HIGH);
         delayMicroseconds(MOTOR_TTL_USEC_FAST);
         digitalWrite( MOTOR_STEP_PIN,LOW);
         delayMicroseconds(MOTOR_TTL_USEC_FAST);
         
         motorPosition+=motorstepunit;
         amountInjectedNL += OneStepInNanoLiter;
          
         
         if ((motorPosition%15000)==0)
         {
            lcd.setCursor(0, 2);
            lcd.print(String(amountInjectedNL/1000) + " ul withdrawn   ");
         }
         /*
         buzzerCounter++;
         if (buzzerCounter < 500)
         {
          digitalWrite(BUZZER_PIN,HIGH);
         } else if  (buzzerCounter < 5000)
         {
            digitalWrite(BUZZER_PIN,LOW);           
         } else if  (buzzerCounter < 700000)
         {
           buzzerCounter = 0;
         }
         */
         
      }
      digitalWrite(BUZZER_PIN,LOW);
      digitalWrite(MOTOR_ENABLE_PIN, HIGH);
      UpdateScreen();
      delay(500);
}

void loop() {
  
  updateButtons();
     
  if (digitalRead(START_BUTTON_PIN)) 
  {
    if (mode == 0)
    {
      StartInjection();
    } else 
    {
      ManualMode();
    }
  }
 
}
