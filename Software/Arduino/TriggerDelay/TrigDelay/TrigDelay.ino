/* This hacky crap will produce a pulses that are delayed by ~11-12 useconds
relative to trigger. Each pulse last ~980ns (high time)
with inter-pulse separation of 2052 ns, i.e., slightly longer
than the 2 usec sampling time of 500kHz the 1608GX supports...
This will only work on arduino nano! (Test if used on another board!*/

bool  triggered = false;
const int DELAY_USEC = 0;
const int PIN_DELAY = 12;
const int PIN_OUT = 13;
const int PIN_IN = 2;
const int INTERRUPT = 0;
const int TTL_LENGTH_USEC = 10;
const int INTER_TTL_DELAY_USEC = 200;
 int NUM_TTLS = 10;
 
//const int ON_REP = 5;
//const int OFF_REP = 4;
//const int OFF_REP2 = 3;
//const int DELAY_REP = 12*3; //12 * 3; // this equals to ~16 useconds...


const int DELAY_REP = 18 * 3; // this equals to ~14 useconds...
long cnt = 0;
bool numTTLSset = true;

void Pulse()
{
  triggered = true;
}

void setup() {
  pinMode(PIN_OUT, OUTPUT);
  pinMode(PIN_IN,INPUT);
  pinMode(PIN_DELAY, OUTPUT);
  digitalWrite(PIN_OUT,LOW);
  /*
  Serial.begin(115200);
  // Allow up to 10 seconds for initialization... 
  long t0 = millis();
  while (millis()-t0 <5000 && numTTLSset) {
    fnHandleSerialCommunication();
  }
 */
 
  noInterrupts();
 
}

#define MAX_BUFFER 128
int buffer_index = 0;
char packetBuffer[MAX_BUFFER]; //buffer to hold incoming packet,

const int CMD_SET_NUM_TTLS = 1;
const int CMD_GET_NUM_TTLS = 2;

byte apply_command()
{
  long tempLong;
  int command = (packetBuffer[0]-'0') * 10 + packetBuffer[1]-'0';
  switch (command) 
  {
        case CMD_SET_NUM_TTLS:
        
       // sscanf (packetBuffer,"%d %d %ld",&command, &NUM_TTLS, &triggerCameraCounterValue);
        
         NUM_TTLS = atol(packetBuffer+3);
         numTTLSset = false;
        Serial.println("OK! "+String(NUM_TTLS));
     
        
        Serial.flush();
        delay(500);
        break;
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

long t0;
void loop() {
  
  if (PIND & B00000100)
  {
      PORTB = B00010000;
      for (int x=0;x<DELAY_REP;x++)
          PORTB &= B11011111;
 
      for (int k=0;k< NUM_TTLS;k++)
      {
        PORTB |= B00100000;
        PORTB |= B00100000;
        PORTB |= B00100000;
        PORTB |= B00100000;
        PORTB |= B00100000;
        PORTB |= B00100000;
    
        PORTB &= B11011111;       
        PORTB &= B11011111;       
        PORTB &= B11011111;       
        PORTB &= B11011111;       
        PORTB &= B11011111;       
   
      }  
 
      while (PIND & B00000100); // wait until trigger is down               
      PORTB = B00000000;      
     }
 
}
