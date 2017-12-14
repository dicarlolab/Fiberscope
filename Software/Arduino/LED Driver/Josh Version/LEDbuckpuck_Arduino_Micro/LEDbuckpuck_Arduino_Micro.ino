
/* Produce variable LED output for a determined time when triggered
   Two trigger channels
   I2C control output to MPC4725 to 0-5V x2
   0-5V dim control to Backpuck 3021-D-E-700 x2

   Original code by Josh Wardell
   Serial comms by Shay Ohayon
   Interrupts and timing optimizations by Josh Wardell

   5-6/2016 JLW Original code
*/



#include <Wire.h>
#define MAX_OUTPUT 2048 // assuming linear mapping, 4096 is 5V, which would correspond to 700mA.
#define MAX_BUFFER 128
int buffer_index = 0;
char packetBuffer[MAX_BUFFER]; //buffer to hold incoming packet,

const int PIN_BUTTON = 7;


const int SET_DURATION_ON = 1;
const int SET_DURATION_OFF = 2;
const int SET_NUM_PULSES = 3;
const int SET_INTENSITY = 4;
const int TURN_ON = 5;
const int TURN_OFF = 6;
const int SIMULATE_TRIGGER = 7;

#define DACaddr                         (0x60)  // I2C address of 4726 DAC (second is at 61)
#define MCP4726_CMD_WRITEDAC            (0x40)  // Writes data to the DAC
#define MCP4726_CMD_WRITEDACEEPROM      (0x60)  // Writes data to the DAC and the EEPROM (persisting the assigned value after reset)
#define NUM_CHANNELS 1


const int Interrupts[NUM_CHANNELS] = {0};
const int DAC_channels[NUM_CHANNELS] = {2};

bool TrigFlags[NUM_CHANNELS] = {0};
uint8_t TrigStates[NUM_CHANNELS] = {0};

uint8_t TrainTTLOutputChannels[NUM_CHANNELS] = {11};

uint16_t Intensities[NUM_CHANNELS] = {800};
unsigned long FSM_timer[NUM_CHANNELS] = {0};
unsigned long DurationsON[NUM_CHANNELS] = {50000}; // default 50 ms on
unsigned long DurationsOFF[NUM_CHANNELS] = {50000}; // default 50 ms off
unsigned long NumPulses[NUM_CHANNELS] = {1};
unsigned long pulseCounter[NUM_CHANNELS] = {0};
void trigA()
{
  if (TrigStates[0] == 0)
    TrigFlags[0] = true;
}

void trigB()
{
  if (TrigStates[1] == 0)
    TrigFlags[1] = true;
}

int triggerCOUNTER = 0;
void setup()
{
    Serial.begin(115200);

pinMode(PIN_BUTTON, INPUT);

  // put your setup code here, to run once:
  Wire.begin();
 // attachInterrupt(Interrupts[0], trigA, RISING);
 // attachInterrupt(Interrupts[1], trigB, RISING);

  Serial.println("Calling DAC init");
 // setDACandKeepInMemory(4096, DAC_channels[0]);
 setDAC(0,0);
  pinMode(TrainTTLOutputChannels[0], OUTPUT);
  digitalWrite(TrainTTLOutputChannels[0], LOW);  
 

  Serial.println("Init Done");
TrigFlags[0] = true;
}


/*  setDAC(output, channel)
    Sets the output voltage to a fraction of source vref
    output 0 to 4095
    Buckpuck is full on below 1v and full off above 4v, nonlinear curve
    Off point value is about 650 depending on LED and supply voltage
*/

void setDACandKeepInMemory( uint16_t output, uint8_t channel )
{
  if (output > MAX_OUTPUT) {
    output = MAX_OUTPUT;
  }
  output = 4095 - output;                    // buckpuck takes inverted 5 to 0 v
  Wire.beginTransmission(DACaddr + DAC_channels[channel]);  // select DAC0, 1, etc
   Wire.write(MCP4726_CMD_WRITEDACEEPROM);
  Wire.write((MCP4726_CMD_WRITEDAC));
  Wire.write(output / 16);                   // Upper data bits          (D11.D10.D9.D8.D7.D6.D5.D4)
  Wire.write((output % 16) << 4);            // Lower data bits          (D3.D2.D1.D0.x.x.x.x)
  Wire.endTransmission();
}


void setDAC( uint16_t output, uint8_t channel )
{
  if (output > 4095) {
    output = 4095;
  }
  output = 4095 - output;                    // buckpuck takes inverted 5 to 0 v
  Wire.beginTransmission(DACaddr + DAC_channels[channel]);  // select DAC0, 1, etc
  Wire.write((MCP4726_CMD_WRITEDAC));
  Wire.write(output / 16);                   // Upper data bits          (D11.D10.D9.D8.D7.D6.D5.D4)
  Wire.write((output % 16) << 4);            // Lower data bits          (D3.D2.D1.D0.x.x.x.x)
  Wire.endTransmission();
}



/*  TriggerA()
    Trigger A state machine, watch for trigger and handle output timing
*/

void handleTrigFSM(int channel)
{
  unsigned long currentMillis;

  switch (TrigStates[channel]) {   /* Trigger A state machine */
    case 1:
    //  Serial.println("Channel " + String(channel) + " Sending " + String(NumPulses[channel]) + " pulses with intensity " + String(Intensities[channel]));
    //  Serial.println("ON : " + String( DurationsON[channel]) + " OFF : " + String( DurationsOFF[channel]));
      pulseCounter[channel] = 0;
      TrigStates[channel] = 2;
      break;
    case 2:
   //   Serial.println("Pulse " + String(pulseCounter[channel]));
      digitalWrite(TrainTTLOutputChannels[0], HIGH);  
      setDAC(Intensities[channel], DAC_channels[channel]);
      FSM_timer[channel] = micros();
      TrigStates[channel] = 3;
      break;
    case 3:
      if (micros() - FSM_timer[channel] > DurationsON[channel])
      {
        digitalWrite(TrainTTLOutputChannels[0], LOW);  
        setDAC(0, DAC_channels[channel]);
        FSM_timer[channel] = micros();
        TrigStates[channel] = 4;      }
      break;
    case 4:
      if (micros() - FSM_timer[channel] > DurationsOFF[channel])
      {
        pulseCounter[channel]++;

        if (pulseCounter[channel] < NumPulses[channel])
        {
          TrigStates[channel] = 2;
        } else
        {
          TrigStates[channel] = 0;
         // Serial.println("Finished");
        }
      }
      break;
  }
}


bool lightON = false;

byte apply_command()
{
  unsigned long durationON;
  unsigned long durationOFF;
  unsigned long channel;
  unsigned long count;
  int command = (packetBuffer[0] - '0') * 10 + packetBuffer[1] - '0';
  // 01234567890123456
  // 00 01 100000
  switch (command)
  {
    case SET_DURATION_ON:
      channel = atoi(packetBuffer + 3);
      durationON = atol(packetBuffer + 6);
      DurationsON[channel] = durationON;
      Serial.println("OK!");
      break;
    case SET_DURATION_OFF:
      channel = atoi(packetBuffer + 3);
      durationOFF = atol(packetBuffer + 6);
      DurationsOFF[channel] = durationOFF;
      Serial.println("OK!");
      break;
    case SET_NUM_PULSES:
      channel = atoi(packetBuffer + 3);
      count = atol(packetBuffer + 6);
      NumPulses[channel] = count;
      Serial.println("OK!");
      break;
    case SET_INTENSITY:
      channel = atoi(packetBuffer + 3);
      count = atol(packetBuffer + 6);
      Serial.println("Setting Channel " + String(channel) + " To : " + String(count));
      Intensities[channel] = count;
      if (lightON)
         setDAC(Intensities[channel], channel);
      Serial.println("OK!");
      break;
    case TURN_ON:
      channel = atoi(packetBuffer + 3);
      digitalWrite(TrainTTLOutputChannels[channel], HIGH);  
      setDAC(Intensities[channel], channel);
      Serial.println("OK!");
      lightON = true;
      break;
    case TURN_OFF:
      channel = atoi(packetBuffer + 3);
      digitalWrite(TrainTTLOutputChannels[channel], LOW);  
      setDAC(0, channel);
      TrigStates[channel] = 0;
      Serial.println("OK!");
      lightON = false;
      break;
    case SIMULATE_TRIGGER :
      channel = atoi(packetBuffer + 3);
      TrigStates[channel] = 1;
      Serial.println("OK!");
     // Serial.println("Triggering channel " + String(channel));
      break;
  }
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

int k = 0;
int PrevButtonValue = 0;

int ButtonValue;

long wdt = millis();
void loop()
{

  ButtonValue = digitalRead(PIN_BUTTON);
 
  if (ButtonValue && PrevButtonValue == 0)
  {
    if (TrigStates[0]==0) {
      TrigStates[0] = 1;
      //Serial.println("BUT TRIG");
    }
  }

  PrevButtonValue = ButtonValue;
 
  
    handleTrigFSM(0);
  
  fnHandleSerialCommunication();
}
