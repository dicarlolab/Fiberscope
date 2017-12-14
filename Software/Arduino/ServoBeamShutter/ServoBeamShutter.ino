int i;
int pulsewidth;
int angle;
void setup()
{
  pinMode(11, OUTPUT);
 Serial.begin(9600);

}

void setServo(float fraction)
{

int pulseMin = 800;
int pulseMax = 2200;
int pulse = fraction* (  pulseMax-pulseMin) + pulseMin;
  PORTB |= B00001000; // HIGH
    delayMicroseconds(pulse);
    PORTB &= ~B00001000; // LOW
}

void loop()
{
 //igitalWrite(11,HIGH);
 setServo(0);
  Serial.println("Now 0");
delay(1000);  
 //igitalWrite(11,LOW);
  Serial.println("Now 0.7");
  setServo(0.7);  
delay(1000);  
 
}

