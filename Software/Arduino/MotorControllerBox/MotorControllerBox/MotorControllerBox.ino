#include <AccelStepper.h>

#include <Wire.h> 
#include <LiquidCrystal_I2C_Due_Compatible.h>
#include <Encoder.h>

#define MAX(a,b)(a)>(b)?(a):(b)

const float MaxTravelPositionUm = 25000; // 25 mm

const float MICROMETER_FULL_ROTATION_UM = 500.0; // Full rotation of manipulator in micrometers
const long ENCODER_STEPS_FULL_REVOLUSTION = 1600;    // single step in degrees
const long MOTOR_STEPS_FULL_REVOLUSTION = 3200;
const int EEPROM_ADDR = 0;

const int SERIAL_SPEED = 115200;
const int DOWN_DIRECTION = 0;         // positive is down (ventral).
const int MOTOR_WAIT_TIME_USEC = 200; // TTL length
const float MAX_STEP_SIZE_UM = 50.0;
const float MAX_SPEED_UM_SEC = 500.0;
const float MICRONS_UPDATE_LCD = 20.0;
const bool UPDATE_SCREEN_WHILE_MOVING = false;

const int STEP_WAIT_USEC = 10000;

// SERIAL COMMANDS
const int CMD_GET_POSITION_MICRONS = 1;
const int CMD_SET_ABSOLUTE_POS_MICRONS = 2;
const int CMD_SET_RELATIVE_POS_MICRONS = 3;

const int CMD_STEP_DOWN = 4;
const int CMD_STEP_UP = 5;
const int CMD_SET_STEP_SIZE = 6;
const int CMD_SET_SPEED = 7;
const int CMD_DISABLE_POTENTIOMETER = 8;
const int CMD_ENABLE_POTENTIOMETER = 9;
const int CMD_RESET_POSITION = 10;
const int CMD_RESET_SCREEN = 11;
const int CMD_PING = 12;
const int CMD_GET_STEP_SIZE = 13;
const int CMD_GET_SPEED = 14;
const int CMD_GET_POSITION_STEPS = 15;
const int CMD_SET_ABSOLUTE_POS_STEPS = 16;
const int CMD_SET_RELATIVE_POS_STEPS = 17;
const int CMD_GET_MIN_STEP_SIZE_MICRONS = 18; 



const int CMD_STORE_POS = 19; 
const int CMD_RECALL_POS = 20; 
const int CMD_GO_HOME = 21; 


const int PIN_MOTOR_POWER = 12;
const int PIN_MOTOR_DIRECTION = 11;
const int PIN_MOTOR_STEP = 10;
const int PIN_STORE_POS = 9;
const int PIN_RECALL_POS = 8;
const int PIN_BUTTON_DOWN =  7;
const int PIN_BUTTON_UP =  6;
const int PIN_CONTINUOUS = 5;

const int PIN_ENCODER_A =  3;
const int PIN_ENCODER_B = 2;

const int PIN_POTENTIOMETER = 6;


LiquidCrystal_I2C lcd(0x3F,20,2);  // set the LCD address to 0x3F for a 16 chars and 2 line display

bool upPressed = false;
bool downPressed = false;
bool continuousMovement = false;

float deltaPosition = 0.5;
float speedValue = 0;
float stepSizeUm = 0;
bool potentiometerEnabled = true;

#define MAX_BUFFER 128
int buffer_index = 0;
char packetBuffer[MAX_BUFFER]; //buffer to hold incoming packet,

#include <EEPROM.h>


class myStepperClass
{
public:

  myStepperClass(int PinStep, int PinDirection, int PinEnable, int PinEncoderA, int PinEncoderB, 
                              int _EEPROMaddress, long EncoderStepsFullRevolution, long MotorStepsFullRevolution, float MicroManipulatorFullRevolutionInUm);
  ~myStepperClass();
  
  void resetPosition(); // writes "0" as current encoder location.
  float getMotorPositionInMicrons();

  long getMotorPositionInEncoderSteps();
  long micronsToPosition(float pos)  ;
  float getMinimumStepSizeMicrons();
  
  float setAbsolutePositionMicrons(float newPositionMicrons);
  float setRelativePositionMicrons(float deltaMicrons);
  
  long setAbsolutePositionSteps(long newPosition);
  long setRelativePositionSteps(long deltaSteps);

  void initializMove(bool downDirection);
  void moveIteration();
  void finishMove();

  
  float setMotorSpeed(float speedUmPerSec);
  void motorPower(bool state);
  
private:
  long setAbsolutePositionStepsMyImplementation(long newPosition);
  float positionToMicrons(long pos);
  void moveIterationMs();

  int EEPROM_writeLong(int ee, const long& value);
  int EEPROM_readLong(int ee, long& value);


  Encoder *motorEncoder;
  AccelStepper *stepper; 

  int pinStep, pinDirection, pinEnable, pinEncoderA, pinEncoderB;
  long encoderStepsFullRevolution, motorStepsFullRevolution;


  long accuracy_steps, max_attempts;
  int EEPROMaddress;
  float singleEncoderStepUm, microManipulatorFullRevolutionInUm,speedUmSec, delayValueUsec;
};

myStepperClass *motor;

myStepperClass::myStepperClass(int PinStep, int PinDirection, int PinEnable, int PinEncoderA, int PinEncoderB, 
                              int _EEPROMaddress, long EncoderStepsFullRevolution, long MotorStepsFullRevolution, float MicroManipulatorFullRevolutionInUm) :
  pinStep(PinStep), pinDirection(PinDirection), pinEnable(PinEnable), pinEncoderA(PinEncoderA), pinEncoderB(PinEncoderB),
  EEPROMaddress(_EEPROMaddress),  encoderStepsFullRevolution(EncoderStepsFullRevolution), motorStepsFullRevolution(MotorStepsFullRevolution), microManipulatorFullRevolutionInUm(MicroManipulatorFullRevolutionInUm)
{
  pinMode(pinStep, OUTPUT);
  pinMode(pinDirection, OUTPUT);
  pinMode(pinEnable, OUTPUT);
  pinMode(pinEncoderA, INPUT);
  pinMode(pinEncoderB, INPUT);
  stepper = new AccelStepper(1, PinStep,  PinDirection);
  motorEncoder = new Encoder(PinEncoderA,PinEncoderB);
  long initial_pos;
  EEPROM_readLong(EEPROMaddress, initial_pos);
  
  motorEncoder->write(initial_pos);  
  motorPower(false);
  
  speedUmSec = 10;
  accuracy_steps = 0;
  max_attempts = 5;
  delayValueUsec = 0;
  
  singleEncoderStepUm = (float)microManipulatorFullRevolutionInUm / (float)encoderStepsFullRevolution;
}



float myStepperClass::positionToMicrons(long pos)
// Converts ENCODER steps to micron (not motor steps!!!)
{
  return  float(pos)*singleEncoderStepUm; 
}


long myStepperClass::micronsToPosition(float pos)
// converts microns to ENCODER steps (not motor setps!!!)
{
  return pos/singleEncoderStepUm; 
}

float myStepperClass::setMotorSpeed(float speedUmPerSec)
{
  speedUmSec = speedUmPerSec;
}

void myStepperClass::initializMove(bool downDirection)
{
  motorPower(true);
   float singleMotorStepUm = (float)microManipulatorFullRevolutionInUm / (float)motorStepsFullRevolution;

   float NumStepsInOneMicron = (float)motorStepsFullRevolution / (float)microManipulatorFullRevolutionInUm;

   float NumStepsPerSec = speedUmSec * NumStepsInOneMicron;
   
   delayValueUsec = MAX(0,  1e6 / NumStepsPerSec  - MOTOR_WAIT_TIME_USEC);
  //delayValueUsec = 1e6/(speedUmSec/singleMotorStepUm) - MOTOR_WAIT_TIME_USEC;// neglecting digitalWrite...

   
  if (downDirection)
     digitalWrite(pinDirection, !DOWN_DIRECTION);
   else
     digitalWrite(pinDirection, DOWN_DIRECTION);
  
}

  void myStepperClass::moveIteration()
  {
      digitalWrite(pinStep, HIGH);
        delayMicroseconds(MOTOR_WAIT_TIME_USEC);
        digitalWrite(pinStep, LOW);
        delayMicroseconds(delayValueUsec); // STEP_WAIT_USEC
     
  }

  
  void myStepperClass::moveIterationMs()
  {
      digitalWrite(pinStep, HIGH);
        delayMicroseconds(MOTOR_WAIT_TIME_USEC);
        digitalWrite(pinStep, LOW);
        delay(delayValueUsec/1e3); 
     
  }
  
  void myStepperClass::finishMove()
  {
   long reachedPosition = getMotorPositionInEncoderSteps();
   
    EEPROM_writeLong(EEPROMaddress,reachedPosition);

    motorPower(false);
    
  }


long myStepperClass::setAbsolutePositionStepsMyImplementation(long newPosition)
{
  long reachedPosition;
  int num_attempts = 0;
  while (1)
  {
  
  long currPos = getMotorPositionInEncoderSteps();
  
  bool downDirection = newPosition > currPos;
  initializMove(downDirection);
   
   long numEncoderSteps = abs(currPos - newPosition);
   long numMotorSteps = numEncoderSteps * motorStepsFullRevolution/ (float)encoderStepsFullRevolution;

   if (delayValueUsec > 65530)
   {
    for (long k=0;k<numMotorSteps;k++) {
        moveIterationMs();
    }
    
   } else
   {
    for (long k=0;k<numMotorSteps;k++) {
     moveIteration();
    }
    
   }
    
    reachedPosition = getMotorPositionInEncoderSteps();
    num_attempts++;
    if ( (abs(reachedPosition - newPosition) <= accuracy_steps) || (num_attempts > max_attempts) )
        {
          break;
        }
        delay(100); // allow time for the shaft to relax
    }
    finishMove();
    return reachedPosition;
}

long  myStepperClass::setAbsolutePositionSteps(long newPosition)
{
  /*
   motorPower(true);
   // SpeedValue is in um/sec. Convert to steps per second
   // 1 um = X steps
   
   stepper->setMaxSpeed(speedUmSec/singleEncoderStepUm); // in steps per second
   stepper->setAcceleration(300.0); 
   stepper->runToNewPosition(2*newPosition);
  // motorPower(false);
   delay(100); 
   // now try to fix with my code (?)
   */
   return setAbsolutePositionStepsMyImplementation(newPosition);
   
//   long reachedPosition = getMotorPositionInEncoderSteps();
//   stepper->setCurrentPosition(2*reachedPosition);
//   EEPROM_writeLong(EEPROMaddress,reachedPosition);
   
 //  return reachedPosition;
}

float myStepperClass::setRelativePositionMicrons(float deltaMicrons)
{
   return motor->setAbsolutePositionMicrons(motor->getMotorPositionInMicrons()+deltaMicrons);
}

long myStepperClass::setRelativePositionSteps(long deltaSteps)
{
    long encoderLocation = motorEncoder->read();
    return setAbsolutePositionSteps(encoderLocation+deltaSteps);
}
  
float myStepperClass::setAbsolutePositionMicrons(float newPositionMicrons)
{
  
  long newPosition = micronsToPosition(newPositionMicrons);
  return positionToMicrons(setAbsolutePositionSteps(newPosition));
}

float myStepperClass::getMinimumStepSizeMicrons()
{
  return singleEncoderStepUm;
}
  
float myStepperClass::getMotorPositionInMicrons()
{
  long encoderLocation = motorEncoder->read();
  return positionToMicrons(encoderLocation);
}

long myStepperClass::getMotorPositionInEncoderSteps()
{
  return motorEncoder->read();
}

void myStepperClass::resetPosition()
{
  motorEncoder->write(0);  
  EEPROM_writeLong(EEPROMaddress, 0);
}


myStepperClass::~myStepperClass()
{
  delete motorEncoder;
}


void myStepperClass::motorPower(bool state)
// controls the enable line on easy driver.
// if state is TRUE, it provides motor current by setting the Enabled to LOW
{
  digitalWrite(PIN_MOTOR_POWER, state ? LOW : HIGH);
  delay(5);
}




int myStepperClass::EEPROM_writeLong(int ee, const long& value)
{
    const byte* p = (const byte*)(const void*)&value;
    unsigned int i;
    for (i = 0; i < sizeof(value); i++)
          EEPROM.write(ee++, *p++);
    return i;
}

 int myStepperClass::EEPROM_readLong(int ee, long& value)
{
    byte* p = (byte*)(void*)&value;
    unsigned int i;
    for (i = 0; i < sizeof(value); i++)
          *p++ = EEPROM.read(ee++);
    return i;
}


void setup()
{
  Serial.begin(115200);
 // Serial.println("Started");
  lcd.init();                      // initialize the lcd 
  lcd.init();                      // initialize the lcd 
  // Print a message to the LCD.
  lcd.backlight();
  
  pinMode(PIN_BUTTON_UP, INPUT);
  pinMode(PIN_BUTTON_DOWN, INPUT);
  pinMode(PIN_CONTINUOUS, INPUT);
   
  pinMode(PIN_STORE_POS, INPUT);
  pinMode(PIN_RECALL_POS, INPUT);
  
  pinMode(PIN_MOTOR_POWER, OUTPUT);
  digitalWrite(PIN_MOTOR_POWER, LOW);
  // reset position
  
  motor = new myStepperClass(PIN_MOTOR_STEP, PIN_MOTOR_DIRECTION, PIN_MOTOR_POWER, PIN_ENCODER_A, PIN_ENCODER_B,
                             EEPROM_ADDR,ENCODER_STEPS_FULL_REVOLUSTION,MOTOR_STEPS_FULL_REVOLUSTION,MICROMETER_FULL_ROTATION_UM);

  if (digitalRead(PIN_BUTTON_UP) || digitalRead(PIN_BUTTON_DOWN))
  {
    lcd.setCursor(0,0);
    lcd.print("Pos Reset");
    motor->resetPosition();
    delay(1000);    
  }
  updateSpeedAndStep();  
  updateScreen();
  
}

void updateScreen()
{
  lcd.setCursor(0,0);
//  lcd.print("Pos: "+String(motor->getMotorPositionInMicrons()/1000.0,3)+" mm  ");
lcd.print(String(motor->getMotorPositionInEncoderSteps())+"        ");
  lcd.setCursor(0,1);
  
  if (potentiometerEnabled)
  {
    
  if (continuousMovement)
  {
      lcd.print("Speed:"+String(speedValue,0) + " um/sec    ");
  } else
  {   
    
    lcd.print("Step: "+String(stepSizeUm,0) + " um    ");
  }
  } else
  {
      lcd.print("PC:"+String(speedValue,0) + " um/sec    ");
  }
  
}

void updateSpeedAndStep()
{
  continuousMovement = digitalRead(PIN_CONTINUOUS);
  if (potentiometerEnabled)
  {
    int  V=analogRead(PIN_POTENTIOMETER);
    if (continuousMovement)
    {
       speedValue = float(V) / 1023.0 * MAX_SPEED_UM_SEC;
       motor->setMotorSpeed(speedValue);
    } else
    {
       stepSizeUm = round(float(V) / 1023.0 * MAX_STEP_SIZE_UM);
    }
  }
}


byte apply_command()
{
  float tempFloat;
  long tempLong;
  int command = (packetBuffer[0]-'0') * 10 + packetBuffer[1]-'0';
  switch (command) 
  {
        case CMD_GET_POSITION_MICRONS:
        Serial.println("OK! "+String(motor->getMotorPositionInMicrons()));
        break;
        case CMD_GET_POSITION_STEPS:
        Serial.println("OK! "+String(motor->getMotorPositionInEncoderSteps()));
        break;
        case CMD_GET_STEP_SIZE:
        Serial.println("OK! "+String(stepSizeUm));
        break;
        case CMD_GET_SPEED:
        Serial.println("OK! "+String(speedValue));
        break;
        case CMD_GET_MIN_STEP_SIZE_MICRONS: 
        Serial.println("OK! "+String(motor->getMinimumStepSizeMicrons(),6));
        break;
      case CMD_SET_ABSOLUTE_POS_MICRONS:
        tempFloat = atof(packetBuffer+3);
        motor->setAbsolutePositionMicrons(tempFloat);
        Serial.println("OK!");        
        updateScreen();      
        break;  
     case CMD_SET_ABSOLUTE_POS_STEPS:
        tempLong = atol(packetBuffer+3);
        motor->setAbsolutePositionSteps(tempLong);
        Serial.println("OK!");        
        updateScreen();      
        break;  
     case CMD_GO_HOME:
        motor->setAbsolutePositionSteps(0);
        Serial.println("OK!");        
        updateScreen();      
        break;  
        
      case CMD_SET_RELATIVE_POS_MICRONS:
        tempFloat = atof(packetBuffer+3);
        motor->setRelativePositionMicrons(tempFloat);
        Serial.println("OK!");        
        updateScreen();      
        break;  
      case CMD_SET_RELATIVE_POS_STEPS:
        tempLong = atol(packetBuffer+3);
        motor->setRelativePositionSteps(tempLong);
        Serial.println("OK!");    
        updateScreen();          
        break;  
        
        
    case CMD_STORE_POS:
        SavePosition();
        Serial.println("OK! ");
        break;        

    case CMD_RECALL_POS:
        RecallPosition();
        Serial.println("OK! ");
        break;        
        
      case CMD_STEP_DOWN:
        tempFloat = motor->setRelativePositionMicrons(stepSizeUm);
        Serial.println("OK! "+String(tempFloat));
        updateScreen();
        break;        
      case CMD_STEP_UP:
        tempFloat = motor->setRelativePositionMicrons(-stepSizeUm);
        Serial.println("OK! "+String(tempFloat));
        updateScreen();        
        break;        
     case CMD_SET_STEP_SIZE:
       tempFloat = atof(packetBuffer+3);
       stepSizeUm = tempFloat;
       Serial.println("OK!");       
       break;
     case CMD_SET_SPEED:
       tempFloat = atof(packetBuffer+3);
       speedValue = tempFloat;
       motor->setMotorSpeed(speedValue);
       Serial.println("OK!"); 
       updateScreen();      
       break;
     case CMD_DISABLE_POTENTIOMETER:
       potentiometerEnabled = false;
       Serial.println("OK!");
       break;
     case CMD_ENABLE_POTENTIOMETER:
       potentiometerEnabled = true;     
       Serial.println("OK!");       
       break;       
       case CMD_RESET_POSITION:
       motor->resetPosition();
       updateScreen();
       Serial.println("OK!");       
       break;       
       case CMD_RESET_SCREEN:
        lcd.init();                      // initialize the lcd 
        lcd.backlight();
        updateScreen();
       Serial.println("OK!");       
       break;
       case CMD_PING:
       Serial.println("OK!");       
       break;
     default:
      Serial.println("NOK UnknownCommand "+String(packetBuffer));   
  }
}

void fnHandleSerialCommunication() 
{
  if (Serial.available() > 0) {
    // get incoming byte:
    char inByte = Serial.read();
    if (inByte == 10) 
      {  // new line
	  packetBuffer[buffer_index] = 0;
          if (buffer_index > 0)
              apply_command();
              
	  buffer_index = 0;
  	  
	} else {
    	  packetBuffer[buffer_index++] = inByte;
	  if (buffer_index >= MAX_BUFFER-1) {
	    buffer_index = MAX_BUFFER-1;
	  }
      }
  }
}

void handleUpKeyEvent()
{
    if (!continuousMovement)
    {
      motor->setRelativePositionMicrons(-stepSizeUm);
      updateScreen();
      while (digitalRead(PIN_BUTTON_UP));
    } else
    {
      motor->initializMove(false);




   if (delayValueUsec > 65530)
   {
    while (digitalRead(PIN_BUTTON_UP))
      {
        motor->moveIterationMs();
      }
    
   } else
   {
    while (digitalRead(PIN_BUTTON_UP))
      {
        motor->moveIteration();
      }
    
   }





      
      
      motor->finishMove();
      updateScreen();
    }
    delay(100);  
}      

void handleDownKeyEvent()
{
    if (!continuousMovement)
    {
      motor->setRelativePositionMicrons(stepSizeUm);
      updateScreen();
      while (digitalRead(PIN_BUTTON_DOWN));
    } else
    {
      motor->initializMove(true);


if (delayValueUsec > 65530)
   {
    while (digitalRead(PIN_BUTTON_DOWN))
      {
        motor->moveIterationMs();
      }
    
   } else
   {
    while (digitalRead(PIN_BUTTON_DOWN))
      {
        motor->moveIteration();
      }
    
   }

      motor->finishMove();
      updateScreen();
    }
    delay(100);  
  
}


long positionMemoryTimer;
int positionMemoryFSM = 0;
long savedMotorPosition = 0;
bool positionSaved = false;


void SavePosition()
{
     savedMotorPosition = motor->getMotorPositionInEncoderSteps();
      positionSaved = true;
      lcd.setCursor(0,1);
      lcd.print("Position Saved   ");
      delay(1000);
      updateScreen();
}

void RecallPosition()
{
      lcd.setCursor(0,1);
      lcd.print("Recalling Position   ");
      Serial.println("Position is now "+String(motor->getMotorPositionInEncoderSteps()) + " Going to "+String(savedMotorPosition));
      motor->setAbsolutePositionSteps(savedMotorPosition);
      updateScreen();
//      Serial.println("Position is now "+String(motorPosition));
}


void  handlePositionMemory()
{
  if (digitalRead(PIN_STORE_POS) && positionMemoryFSM ==0)
  {
    positionMemoryTimer = millis();
    positionMemoryFSM = 1;
  }
  
  if ( digitalRead(PIN_RECALL_POS) && positionMemoryFSM == 0 && positionSaved)
  {
   positionMemoryTimer = millis();
   positionMemoryFSM = 2;
  }
  
  if (positionMemoryFSM == 1)
  {
    if (millis()-positionMemoryTimer > 2000)
    {
      positionMemoryFSM = 0;
      SavePosition();
    }
  }
  
  if (positionMemoryFSM == 2)
  {
  if (millis()-positionMemoryTimer > 2000)
    {  
      positionMemoryFSM = 0;
      RecallPosition();
    }
  }
  
}
   

void loop()
{
  fnHandleSerialCommunication();
  
 if (digitalRead(PIN_BUTTON_UP))  
  {
     handleUpKeyEvent();
  }
  
  if (digitalRead(PIN_BUTTON_DOWN))  
  {
    handleDownKeyEvent();
  }
  updateSpeedAndStep();
  updateScreen();
  
  handlePositionMemory();
 
}
