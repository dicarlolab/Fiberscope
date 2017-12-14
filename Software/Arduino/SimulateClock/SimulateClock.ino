/* 5/20/2014
   Small program to simulate the timing of the V-7000
   Shay Ohayon
*/
int Rate;
long SyncUsec;
int numPatterns;
int patternCounter;
int pulseWidthUsec;
int SYNC_PORT;
int GLOBAL_SYNC_PORT ;
int COUNTER_PORT;
long clocktimer;
long sequenceCounter;
void setup() {
 SYNC_PORT = 10;
 GLOBAL_SYNC_PORT =11 ;
 COUNTER_PORT = 9;

  // put your setup code here, to run once:
  pinMode(SYNC_PORT,OUTPUT);
  pinMode(GLOBAL_SYNC_PORT,OUTPUT);
  pinMode(COUNTER_PORT,OUTPUT);
  
  digitalWrite(SYNC_PORT,LOW);
  digitalWrite(GLOBAL_SYNC_PORT,LOW);  
  digitalWrite(COUNTER_PORT,LOW);
  sequenceCounter = 0;
  numPatterns = 1024;
  Rate = 1024; // Maximum is 22727; 
  SyncUsec = 1.0/Rate * 1000000;
  patternCounter = 0;
  pulseWidthUsec = SyncUsec/2; // need to be smaller than SyncUsec
  Serial.begin(115200);
  Serial.println("Rate  "+String(Rate)+ "Hz");
  Serial.println("Pulse width "+String(pulseWidthUsec) +"Usec");
  analogWriteResolution(12);
}

void loop() {
  // put your main code here, to run repeatedly:
  if (patternCounter == 0)
  {
    Serial.println("Starting sequence "+String(sequenceCounter));
    sequenceCounter=sequenceCounter+1;
    delay(5000);
    clocktimer = micros();
    analogWrite(DAC0,patternCounter);

    digitalWrite(GLOBAL_SYNC_PORT,HIGH);
    digitalWrite(SYNC_PORT, HIGH);
    digitalWrite(COUNTER_PORT, HIGH);
    delayMicroseconds(pulseWidthUsec);
    digitalWrite(GLOBAL_SYNC_PORT,LOW);
    digitalWrite(SYNC_PORT, LOW);
    digitalWrite(COUNTER_PORT, LOW);    
    patternCounter=patternCounter+1;
  } else
  {
      long clk = micros();
      if (clk-clocktimer > SyncUsec)
      {
        analogWrite(DAC0,4*patternCounter);
     
        digitalWrite(SYNC_PORT, HIGH);
        digitalWrite(COUNTER_PORT, HIGH);    
        delayMicroseconds(pulseWidthUsec);
        digitalWrite(SYNC_PORT, LOW);
        digitalWrite(COUNTER_PORT, LOW);    
        patternCounter=patternCounter+1;
        
        if (patternCounter>numPatterns) {
          Serial.println(String(patternCounter-1)+" patterns sent");
          patternCounter = 0;
          analogWrite(DAC0,0);          
        }
        
      }
  }
  
}
