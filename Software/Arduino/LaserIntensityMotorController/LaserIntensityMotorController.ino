const int DEBUG = 0;
const int DIRECTION_PIN = 5;
const int STEP_PIN = 6;
const int STEP_LEFT_PIN = 7;
const int STEP_RIGHT_PIN = 8;

const double MotorStepInDeg = 7.5 / 8; //0.176 / 8;// % 
const int TTL_WAIT_USECS = 2000;
long motorPosition = 0; // absolute number of motor steps taken since it was initialized (reset)
// to convert motor position to micrometer. multiply by StepSizeDeg/360 and multiply by RotationToUm
#define MIN(a,b)(a)<(b)?(a):(b)
#define MAX(a,b)(a)>(b)?(a):(b)
#include <EEPROM.h>
#define MAX_BUFFER 128
int buffer_index = 0;
char packetBuffer[MAX_BUFFER]; //buffer to hold incoming packet,

const int CMD_GET_FILTER_POS = 1;
const int CMD_SET_FILTER_POS = 2;
const int CMD_STEP_LEFT = 3;
const int CMD_STEP_RIGHT = 4;
const int MANUAL_STEP_COUNT = 8;
const int CMD_CALIBRATE_FILTER_POS = 5;

const int NUM_WHEEL_POSITIONS = 6;

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

int motorPositionToWheelPosition()
{
  return ( ((long)(motorPosition * MotorStepInDeg) % 360) / (360 / NUM_WHEEL_POSITIONS)) % NUM_WHEEL_POSITIONS;
}


void  setWheelPosition(int desiredPosition)
{
  int currentWheelPosition = motorPositionToWheelPosition();
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
  }


  digitalWrite(DIRECTION_PIN, ForwardDirection ? HIGH : LOW);

  long numMotorSteps = numWheelSteps * 360.0 / NUM_WHEEL_POSITIONS / MotorStepInDeg;
  if (DEBUG)
  {
   Serial.println("Current Motor Position : "+String(motorPosition)+" ("+String(motorPosition* MotorStepInDeg,5)+" deg)");
   Serial.println("Current Wheel Position : "+String(currentWheelPosition));
   Serial.println("Destination Wheel Position : "+String(desiredPosition));
   Serial.println("Num Wheel Steps: "+String(numWheelSteps)+" in direction " + (ForwardDirection? "Forward":"Backward"));
   Serial.println("Num Motor Steps: "+String(numMotorSteps));
  }

  for (int k = 0; k < numMotorSteps; k++)
  {
    digitalWrite(STEP_PIN, HIGH);
    delayMicroseconds(TTL_WAIT_USECS);
    digitalWrite(STEP_PIN, LOW);
    delayMicroseconds(TTL_WAIT_USECS);
  }
  motorPosition += ForwardDirection ? numMotorSteps : -numMotorSteps;

if (DEBUG)
{
  Serial.println("Wheel is is now at position "+String(motorPositionToWheelPosition())+", motor is "+String(motorPosition)+" ("+String(motorPosition* MotorStepInDeg,5)+" deg)");
}

  EEPROM_writeLong(0, motorPosition);


}

byte apply_command()
{

  long desiredPosition;
  int command = (packetBuffer[0] - '0') * 10 + packetBuffer[1] - '0';
  switch (command)
  {
    case CMD_GET_FILTER_POS:
      Serial.println("OK! " + String(motorPositionToWheelPosition()));
      break;
    case CMD_STEP_RIGHT:
      digitalWrite(DIRECTION_PIN, LOW);
      for (int k = 0; k < MANUAL_STEP_COUNT; k++)
      {
        digitalWrite(STEP_PIN, HIGH);
        delayMicroseconds(TTL_WAIT_USECS);
        digitalWrite(STEP_PIN, LOW);
        delayMicroseconds(TTL_WAIT_USECS);
      }

      Serial.println("OK!");
      break;
    case CMD_STEP_LEFT:
      digitalWrite(DIRECTION_PIN, HIGH);
      for (int k = 0; k < MANUAL_STEP_COUNT; k++)
      {
        digitalWrite(STEP_PIN, HIGH);
        delayMicroseconds(TTL_WAIT_USECS);
        digitalWrite(STEP_PIN, LOW);
        delayMicroseconds(TTL_WAIT_USECS);
      }
      Serial.println("OK!");
      break;
      case CMD_CALIBRATE_FILTER_POS:
      desiredPosition = atoi(packetBuffer + 3);
      motorPosition = desiredPosition * (360 / NUM_WHEEL_POSITIONS)/MotorStepInDeg;
      EEPROM_writeLong(0, motorPosition);
      Serial.println("OK!");
      break;
    case CMD_SET_FILTER_POS:
      desiredPosition = atoi(packetBuffer + 3);
      setWheelPosition(desiredPosition);
      Serial.println("OK!");

      break;
  }

}
void setup() {
  // put your setup code here, to run once:
  pinMode(DIRECTION_PIN, OUTPUT);
  pinMode(STEP_PIN, OUTPUT);
  pinMode(STEP_LEFT_PIN, OUTPUT);
  pinMode(STEP_RIGHT_PIN, OUTPUT);

  pinMode(STEP_LEFT_PIN, LOW);
  pinMode(STEP_RIGHT_PIN, LOW);
  
  digitalWrite(DIRECTION_PIN, HIGH);
  digitalWrite(STEP_PIN, LOW);
  Serial.begin(115200);
  EEPROM_readLong(0, motorPosition);
}

void loop() {
  // put your main code here, to run repeatedly:
  fnHandleSerialCommunication() ;
  if (digitalRead(STEP_LEFT_PIN))
  {
   // Serial.println("LEFT\n");        
     digitalWrite(DIRECTION_PIN, HIGH);
      for (int k = 0; k < MANUAL_STEP_COUNT; k++)
      {
        digitalWrite(STEP_PIN, HIGH);
        delayMicroseconds(TTL_WAIT_USECS);
        digitalWrite(STEP_PIN, LOW);
        delayMicroseconds(TTL_WAIT_USECS);
      }    
     while (digitalRead(STEP_LEFT_PIN));
      delay(100);
    
  }
  if (digitalRead(STEP_RIGHT_PIN))
  {
    //Serial.println("RIGHT\n");
       digitalWrite(DIRECTION_PIN, LOW);
      for (int k = 0; k < MANUAL_STEP_COUNT; k++)
      {
        digitalWrite(STEP_PIN, HIGH);
        delayMicroseconds(TTL_WAIT_USECS);
        digitalWrite(STEP_PIN, LOW);
        delayMicroseconds(TTL_WAIT_USECS);
      }   
     while (digitalRead(STEP_RIGHT_PIN));
      delay(100);
       
  }
}
