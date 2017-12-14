
const int PIN_OUT = 3;
const int PIN_IN = 2;
int NUM_TTLS = 1;
 
long cnt = 0;
bool numTTLSset = true;
bool  triggered = false;

long triggerCounter = 0;

void setup() {
  pinMode(PIN_OUT, OUTPUT);
  pinMode(PIN_IN,INPUT);
  attachInterrupt(0, InterruptFunction, RISING);
  digitalWrite(PIN_OUT,LOW);
  Serial.begin(115200);
  
  // Allow up to 10 seconds for initialization... 
  long t0 = millis();
  while (millis()-t0 <5000 && numTTLSset) {
    fnHandleSerialCommunication();
  }
 
 // noInterrupts();
 
}

#define MAX_BUFFER 128
int buffer_index = 0;
char packetBuffer[MAX_BUFFER]; //buffer to hold incoming packet,

const int CMD_SET_NUM_TTLS = 1;

byte apply_command()
{
  long tempLong;
  int command = (packetBuffer[0]-'0') * 10 + packetBuffer[1]-'0';
  switch (command) 
  {
        case CMD_SET_NUM_TTLS:
         
         NUM_TTLS = atol(packetBuffer+3);
         numTTLSset = false;
        Serial.println("OK! "+String(NUM_TTLS));
        Serial.flush();
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
void InterruptFunction()
{
  triggerCounter++;
}

long t0;
bool first = true;
void loop() {
   {
       if (triggerCounter >= NUM_TTLS || (first && triggerCounter>0) )
      {
        delayMicroseconds(5); // allow settle of DMD mirrors
        first = false;
        triggerCounter = 0;
        PORTD = B00001000;
        delayMicroseconds(5);
        PORTD = B00000000;   
        
       }
   }
 
}
