const int RELAYPIN = 13;
const int LEDPIN = 12;
const int ON_SEC = 5;
const int OFF_SEC = 10;
void setup() {
  // put your setup code here, to run once:
  pinMode(RELAYPIN,OUTPUT);
  pinMode(LEDPIN,OUTPUT);
  digitalWrite(LEDPIN,LOW);
  digitalWrite(RELAYPIN,LOW);
}

void loop() {
  // put your main code here, to run repeatedly:

  // Give a heat pulse for 5 sec.
  digitalWrite(RELAYPIN,HIGH);
  unsigned long t0 = millis();
  while (millis() - t0 < ON_SEC*1000)
  {
      digitalWrite(LEDPIN,HIGH);
      delay(100);
      digitalWrite(LEDPIN,LOW);
      delay(100);
  }
  digitalWrite(RELAYPIN,LOW);
  t0 = millis();
  while (millis() - t0 < OFF_SEC*1000)
  {
      digitalWrite(LEDPIN,HIGH);
      delay(1000);
      digitalWrite(LEDPIN,LOW);
      delay(1000);
  }
}
