// Controls two step motors for turning both filter wheel and a shutter
// Coded by Shay Ohayon, DiCarlo Lab, MIT
// 
// Changes:
// ??? - Initial implementation
// 12/1/2015 - Support for multiple shutters.

const int DEBUG = 1;
const int DIRECTION1_PIN = 10;
const int STEP1_PIN = 9;
const int ENABLE1_PIN = 8;
const int SHUTTER_STEPS = 40;

const int DIRECTION2_PIN = 12;
const int STEP2_PIN = 11;
const int ENABLE2_PIN = 7;

const int ENABLE_PINS[2] = {ENABLE1_PIN, ENABLE2_PIN};
const int DIRECTION_PINS[2] = {DIRECTION1_PIN, DIRECTION2_PIN};
const int STEP_PINS[2] = {STEP1_PIN, STEP2_PIN};
 
const int STEP_LEFT_PIN = 6;
const int STEP_RIGHT_PIN = 4;
const int SHUTTER_PIN = 5;

const int SHUTTER3_PWM = 13;
const int SHUTTER2_PWM = 3;
const int SHUTTER1_PWM = 2;

const float SERVO_ON_POSITION = 0;
const float SERVO_OFF_POSITION = 0.5;

bool ShutterStates[3] = {false,false,false};
bool SavedShutterStates[3]= {false,false,false};
// PK motor: 360.0/3173.0, TTL:200

const double MotorStepInDeg = 360.0/16384.0; //0.176 / 8;// % 
const int TTL_WAIT_USECS = 60;
long motorPositions[2] = {0,0}; // absolute number of motor steps taken since it was initialized (reset)

// to convert motor position to micrometer. multiply by StepSizeDeg/360 and multiply by RotationToUm
#define MIN(a,b)(a)<(b)?(a):(b)
#define MAX(a,b)(a)>(b)?(a):(b)
#include <EEPROM.h>
#define MAX_BUFFER 128
int buffer_index = 0;
char packetBuffer[MAX_BUFFER]; //buffer to hold incoming packet,

int fastmotorDelay = 200;
int prevShutterPinValue;
const int CMD_GET_FILTER_POS = 1;
const int CMD_SET_FILTER_POS = 2;
const int CMD_STEP_LEFT = 3;
const int CMD_STEP_RIGHT = 4;
const int MANUAL_STEP_COUNT = 400;

const int CMD_SHUTTER_ON = 6;
const int CMD_SHUTTER_OFF = 7;
const int CMD_GET_SHUTTER_STATE = 8;

const int CMD_CALIB = 9;

const int NUM_WHEEL_POSITIONS = 6;


 const int CMD_FAST_ROTATION_START = 10;
 const int CMD_FAST_ROTATION_STOP = 11;
  

bool EEPROM_writebool(int ee, const bool& value)
{
  const byte* p = (const byte*)(const void*)&value;
  unsigned int i;
  for (i = 0; i < sizeof(value); i++)
    EEPROM.write(ee++, *p++);
  return i;
}

bool EEPROM_readbool(int ee, bool& value)
{
  byte* p = (byte*)(void*)&value;
  unsigned int i;
  for (i = 0; i < sizeof(value); i++)
    *p++ = EEPROM.read(ee++);
  return i;
}





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

int motorPositionToWheelPosition(int motorIndex)
// MotorIndex is 1 or 2
{
  return ( ((long)(motorPositions[motorIndex-1] * MotorStepInDeg) % 360) / (360 / NUM_WHEEL_POSITIONS)) % NUM_WHEEL_POSITIONS;
}

void saveShutterConfiguration()
{
  SavedShutterStates[0] = ShutterStates[0];
  SavedShutterStates[1] = ShutterStates[1];
  SavedShutterStates[2] = ShutterStates[2];
}


void recoverShutterConfiguration()
{
  Shutter(SavedShutterStates[0],1);
  Shutter(SavedShutterStates[1],2);
  Shutter(SavedShutterStates[2],3);
}

void  setWheelPosition(int desiredPosition, int motorIndex)
{
  int currentWheelPosition = motorPositionToWheelPosition(motorIndex);

  if (desiredPosition < 0)
    desiredPosition += 6;
    
  int steps[6][6] = { {0,1,2,3,-2, -1},
                      {-1,0,1,2,3,-2},
                      {-2,-1,0,1,2,3},
                      {3,-2,-1,0,1,2} ,                     
                      {2,3,-2,-1,0,1}  , 
                      {1,2,3,-2,-1,0}};
  // shift steps by currentWheelPosition
 int numWheelSteps = steps[currentWheelPosition][desiredPosition];
 /*  
  int distForward = desiredPosition - currentWheelPosition;

  // assume current < desired
  int numStepsForward = desiredPosition - currentWheelPosition;
  if (numStepsForward < 0)
    numStepsForward += NUM_WHEEL_POSITIONS;

  int numStepsBackward = currentWheelPosition - desiredPosition;
  if (numStepsBackward < 0)
    numStepsBackward += NUM_WHEEL_POSITIONS;

  long numWheelSteps = MIN(numStepsForward, numStepsBackward);
  
  bool ForwardDirection = numStepsForward < numStepsBackward;
  if (numWheelSteps < 0)
  {
    numWheelSteps *= -1;
    ForwardDirection = !ForwardDirection;
  } */
  
  bool ForwardDirection = numWheelSteps > 0 ;
  
  digitalWrite(ENABLE_PINS[motorIndex-1], LOW); delay(10);
  if (DEBUG){
    Serial.println("Setting direction pin " + String(DIRECTION_PINS[motorIndex-1]) + " to "+String( ForwardDirection ? "HIGH" : "LOW"));
  }
  
  
  long numMotorSteps = abs(numWheelSteps) * 360.0 / NUM_WHEEL_POSITIONS / MotorStepInDeg;
  if (DEBUG)
  {
   Serial.println("Current Motor Position : "+String(motorPositions[motorIndex-1])+" ("+String(motorPositions[motorIndex-1]* MotorStepInDeg,5)+" deg)");
   Serial.println("Current Wheel Position : "+String(currentWheelPosition));
   Serial.println("Destination Wheel Position : "+String(desiredPosition));
   Serial.println("Num Wheel Steps: "+String(numWheelSteps)+" in direction " + (ForwardDirection? "Forward":"Backward"));
   Serial.println("Num Motor Steps: "+String(numMotorSteps));
  }

if (numMotorSteps >0)
{
  saveShutterConfiguration();
  
  Shutter(false,1);
  Shutter(false,2);
  Shutter(false,3);
  
  digitalWrite(DIRECTION_PINS[motorIndex-1], ForwardDirection ? HIGH : LOW);
   
 

  for (int k = 0; k < numMotorSteps; k++)
  {
    digitalWrite(STEP_PINS[motorIndex-1], HIGH);
    delayMicroseconds(TTL_WAIT_USECS);
    digitalWrite(STEP_PINS[motorIndex-1], LOW);
    delayMicroseconds(TTL_WAIT_USECS);
  }
  motorPositions[motorIndex-1] += ForwardDirection ? numMotorSteps : -numMotorSteps;

  recoverShutterConfiguration();
  //Shutter(true);
}

  digitalWrite(ENABLE_PINS[motorIndex-1], HIGH);
if (DEBUG)
{
  Serial.println("Wheel is is now at position "+String(motorPositionToWheelPosition(motorIndex))+", motor is "+String(motorPositions[motorIndex-1])+" ("+String(motorPositions[motorIndex-1]* MotorStepInDeg,5)+" deg)");
}

  EEPROM_writeLong(0, motorPositions[0]);
  EEPROM_writeLong(4, motorPositions[1]);
}


void ManualStepMotor(int motorIndex, long numSteps)
{
  bool stepRight = numSteps > 0;
     digitalWrite(ENABLE_PINS[motorIndex-1], LOW);    delay(50);
     if (DEBUG) {
      Serial.println("Setting direction pin " + String(DIRECTION_PINS[motorIndex-1]) +" to " +  String(stepRight? "LOW" : "HIGH"));
     }
      digitalWrite(DIRECTION_PINS[motorIndex-1], stepRight ? LOW : HIGH);
      Serial.println("Doing " + String(numSteps) +" steps");
      for (long k = 0; k < fabs(numSteps); k++)
      {
        digitalWrite(STEP_PINS[motorIndex-1], HIGH);
        delayMicroseconds(TTL_WAIT_USECS);
        digitalWrite(STEP_PINS[motorIndex-1], LOW);
        delayMicroseconds(TTL_WAIT_USECS);
      }
      digitalWrite(ENABLE_PINS[motorIndex-1], HIGH);    
}


void StepMotor(int motorIndex, bool stepRight)
{
     digitalWrite(ENABLE_PINS[motorIndex-1], LOW);    delay(10);
     if (DEBUG) {
      Serial.println("Setting direction pin " + String(DIRECTION_PINS[motorIndex-1]) +" to " +  String(stepRight? "LOW" : "HIGH"));
     }
      digitalWrite(DIRECTION_PINS[motorIndex-1], stepRight ? LOW : HIGH);
      for (int k = 0; k < MANUAL_STEP_COUNT; k++)
      {
        digitalWrite(STEP_PINS[motorIndex-1], HIGH);
        delayMicroseconds(TTL_WAIT_USECS);
        digitalWrite(STEP_PINS[motorIndex-1], LOW);
        delayMicroseconds(TTL_WAIT_USECS);
      }
      digitalWrite(ENABLE_PINS[motorIndex-1], HIGH);    
}

byte apply_command()
{

  long motorIndex;
  long desiredPosition;
  long desiredShutter;
  long dummyPosition = 0;
  int command = (packetBuffer[0] - '0') * 10 + packetBuffer[1] - '0';
  switch (command)
  {
    case CMD_CALIB:
      motorIndex = atoi(packetBuffer + 3);
      desiredPosition = atol(packetBuffer + 6);
      ManualStepMotor(motorIndex,desiredPosition);
      delay(1000);
      ManualStepMotor(motorIndex,-desiredPosition);
      Serial.println("OK! ");
      EEPROM_writeLong(0, dummyPosition);
      EEPROM_writeLong(4, dummyPosition);
      motorPositions[0] = 0;
      motorPositions[1] = 0;
    
      break;
    case CMD_GET_FILTER_POS:
      motorIndex = atoi(packetBuffer + 3);
      Serial.println("OK! " + String(motorPositionToWheelPosition(motorIndex)));
      break;
    case CMD_STEP_RIGHT:
      motorIndex = atoi(packetBuffer + 3);
      StepMotor(motorIndex, true);
      Serial.println("OK!");
       break;
    case CMD_STEP_LEFT:
      motorIndex = atoi(packetBuffer + 3);
      StepMotor(motorIndex, false);
      Serial.println("OK!");
      break;
      case CMD_SHUTTER_ON:
        desiredShutter = atoi(packetBuffer + 3);
        Shutter(false,desiredShutter);      
        Serial.println("OK!");
      break;
      case CMD_SHUTTER_OFF:
        desiredShutter = atoi(packetBuffer + 3);
        Shutter(true,desiredShutter);
        Serial.println("OK!");
      break;
      case CMD_GET_SHUTTER_STATE:
      Serial.println("OK! " + String(ShutterStates[0]) + String(" ") + String(ShutterStates[1]) + " " + String(ShutterStates[2]));
      break;      
    case CMD_SET_FILTER_POS:
      motorIndex = atoi(packetBuffer + 3);
      desiredPosition = atol(packetBuffer + 6);
      setWheelPosition(desiredPosition,motorIndex);
      Serial.println("OK!");
  }

}

/*
void ShutterUsingTwoMotors(bool state)
{
   if (state)
      digitalWrite(DIRECTION2_PIN,HIGH);
    else
      digitalWrite(DIRECTION2_PIN,LOW);
      
    digitalWrite(ENABLE2_PIN,LOW);  delay(10);
    for (int k=0;k<SHUTTER_STEPS;k++)
    {
             digitalWrite(STEP2_PIN, HIGH);
        delayMicroseconds(500);
        digitalWrite(STEP2_PIN, LOW);
        delayMicroseconds(500);
 
    }
    digitalWrite(ENABLE2_PIN,HIGH);    
}

*/

void setServo(float fraction,int servo)
{

int pulseMin = 800;
int pulseMax = 2200;
int pulse = fraction* (  pulseMax-pulseMin) + pulseMin;
if (servo == 1)
  {
      PORTD |= B00000100; // HIGH
      delayMicroseconds(pulse);
      PORTD &= ~B00000100; // LOW
  } else if (servo == 2)
  {
      PORTD |= B00001000; // HIGH
      delayMicroseconds(pulse);
      PORTD &= ~B00001000; // LOW
  } else if (servo == 3)
  {
      PORTB |= B0010000; // HIGH
      delayMicroseconds(pulse);
      PORTB &= ~B00100000; // LOW
  }
  
  delay(100); // Allow 100 ms for shutter to settle.s
}


void ShutterUsingServo(bool state, int servo)
{
  if (state)
    setServo(SERVO_ON_POSITION,servo);
  else
    setServo(SERVO_OFF_POSITION,servo);
}

void Shutter(bool state, int servonumber)
// Servonumber between 1 and 3.
// 
// True = light goes through
// False = beam block
{
  if (servonumber <= 0 || servonumber > 3)
  return;
  
if (ShutterStates[servonumber-1] != state)
  {
    ShutterStates[servonumber-1] = state;
    ShutterUsingServo(state, servonumber);
    //ShutterUsingTwoMotors(state);
    
    EEPROM_writebool(7+servonumber, ShutterStates[servonumber-1]);
  }
}

void setup() {
  
  // put your setup code here, to run once:
  pinMode(DIRECTION1_PIN, OUTPUT);
  pinMode(STEP1_PIN, OUTPUT);
  pinMode(DIRECTION2_PIN, OUTPUT);
  pinMode(STEP2_PIN, OUTPUT);
  
  pinMode(ENABLE1_PIN, OUTPUT);    
  digitalWrite(ENABLE1_PIN, HIGH);    

  pinMode(ENABLE2_PIN, OUTPUT);    
  digitalWrite(ENABLE2_PIN, HIGH);    

  
  pinMode(STEP_LEFT_PIN, OUTPUT);
  pinMode(STEP_RIGHT_PIN, OUTPUT);

  pinMode(STEP_LEFT_PIN, LOW);
  pinMode(STEP_RIGHT_PIN, LOW);
  
  pinMode(SHUTTER_PIN, INPUT);
  
  pinMode(SHUTTER1_PWM, OUTPUT);
  digitalWrite(SHUTTER1_PWM, LOW);

  pinMode(SHUTTER2_PWM, OUTPUT);
  digitalWrite(SHUTTER2_PWM, LOW);

  pinMode(SHUTTER3_PWM, OUTPUT);
  digitalWrite(SHUTTER3_PWM, LOW);

        
  digitalWrite(DIRECTION1_PIN, HIGH);
  digitalWrite(STEP1_PIN, LOW);
  digitalWrite(DIRECTION2_PIN, HIGH);
  digitalWrite(STEP2_PIN, LOW);

    long tmp = 0;
    bool tmpb = 0;

  if (digitalRead(STEP_LEFT_PIN))
  {

    EEPROM_writeLong(0, tmp);
    EEPROM_writeLong(4, tmp);

    EEPROM_writebool(8, tmp);
    EEPROM_writebool(9, tmp);
    EEPROM_writebool(10, tmp);
    
  }
   
   
  EEPROM_readbool(8, tmpb);
  ShutterStates[0] = tmpb;
  EEPROM_readbool(9, tmpb);
  ShutterStates[1] = tmpb;
  EEPROM_readbool(10, tmpb);
  ShutterStates[2] = tmpb;

  Serial.begin(115200);
  
  EEPROM_readLong(0, tmp);
  motorPositions[0] = tmp;
  EEPROM_readLong(4, tmp);
  motorPositions[1] = tmp;  

 // testShutters();
  
}

void testShutters() {
  while (1)
  {
     ShutterUsingServo(true, 1);
     ShutterUsingServo(true, 2);
     ShutterUsingServo(true, 3);
     delay(1000);
     ShutterUsingServo(false, 1);
     ShutterUsingServo(false, 2);
     ShutterUsingServo(false, 3);
     delay(1000);
     
  }

}
void loop() {
  // put your main code here, to run repeatedly:
  fnHandleSerialCommunication() ;
  if (digitalRead(SHUTTER_PIN) != prevShutterPinValue)
  {
    prevShutterPinValue = digitalRead(SHUTTER_PIN);
    Shutter(prevShutterPinValue,1);
    Shutter(prevShutterPinValue,2);
    Shutter(prevShutterPinValue,3);
    delay(100);
  }
  
  /*
  if (digitalRead(STEP_LEFT_PIN))
  {
    
       
     digitalWrite(ENABLE1_PIN, LOW);        delay(10);
     digitalWrite(DIRECTION1_PIN, HIGH);
      for (int k = 0; k < MANUAL_STEP_COUNT; k++)
      {
        digitalWrite(STEP1_PIN, HIGH);
        delayMicroseconds(TTL_WAIT_USECS);
        digitalWrite(STEP1_PIN, LOW);
        delayMicroseconds(TTL_WAIT_USECS);
      }    
     while (digitalRead(STEP_LEFT_PIN));
    digitalWrite(ENABLE1_PIN, HIGH);         
      delay(100);
    
  }
  if (digitalRead(STEP_RIGHT_PIN))
  {
      digitalWrite(ENABLE1_PIN, LOW);        delay(10);
       digitalWrite(DIRECTION1_PIN, LOW);
      for (int k = 0; k < MANUAL_STEP_COUNT; k++)
      {
       // Serial.print('*');
        digitalWrite(STEP1_PIN, HIGH);
        delayMicroseconds(TTL_WAIT_USECS);
        digitalWrite(STEP1_PIN, LOW);
        delayMicroseconds(TTL_WAIT_USECS);
      }   
     while (digitalRead(STEP_RIGHT_PIN));
     digitalWrite(ENABLE1_PIN, HIGH);         
      delay(100);
       
  }
 */ 
  
}
