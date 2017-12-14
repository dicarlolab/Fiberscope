const float MIN_FREQ = 0.5;
const float MAX_FREQ = 140;
const float MIN_DUTY = 30;
const float MAX_DUTY = 100;

void setup() {
  Serial.begin(115200);
  // put your setup code here, to run once:
  pinMode(5, OUTPUT); // 1A
  pinMode(6, OUTPUT); // 2A
  pinMode(7, OUTPUT); // EN
  pinMode(8, INPUT); // 2A
  pinMode(9, INPUT); // EN
  digitalWrite(7, HIGH);    
  digitalWrite(5, LOW);
  digitalWrite(6, LOW);  
  noInterrupts();
}

void loop() {
  // put your main code here, to run repeatedly:
  bool start = digitalRead(8);
  bool dir = digitalRead(9);
  int value = analogRead(0);
  float Speed = (value/1023.0) * MAX_FREQ + MIN_FREQ;
  float DutyCycle = (value/1023.0) * (MAX_DUTY-MIN_DUTY) + MIN_DUTY;  
 
  float Freq = 0.5;
  float Duty = DutyCycle;
  
  float pulseInMs = 1000/Freq;
  float onTime = pulseInMs * Duty/100.0;
  float offTime = pulseInMs * (1.0-Duty/100.0);
  Serial.println(String(DutyCycle) + "   "+String(onTime,2) + "   "+String(offTime));
  if (start)
  {
   int pin = dir ? 5 : 6;
   digitalWrite(pin, HIGH);
   delay(onTime);
   digitalWrite(pin, LOW);
   delay(offTime);
  }
  // if delay is 0, maximum rate is 1ml/sec
//  delay(1000);  // this will do 1ml/minute (good for mice?)
  delay(10000);    // this will do 2 ml / minute
}
