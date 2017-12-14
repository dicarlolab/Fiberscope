#define LED 13
void setup() {
  // put your setup code here, to run once:
Serial.begin(115200);
pinMode(LED,OUTPUT);
}

void loop() {
  // put your main code here, to run repeatedly:
  digitalWrite(LED,HIGH);
  delayMicroseconds(1000000);  
  digitalWrite(LED,LOW);
  delayMicroseconds(1000000);  
}
