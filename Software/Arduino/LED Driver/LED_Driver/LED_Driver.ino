const int PIN_TRIGGER = 2;
const int PIN_BUTTON = 3;
const int PIN_SWITCH = 6;
const int PIN_OUTPUT = 13;

bool ButtonPressed = false;
bool Triggered = false;

void TriggerInterrupt()
{
  Triggered = true;
}

void ButtonInterrupt()
{
   ButtonPressed = true;  
}

void setup() {
  // put your setup code here, to run once:
  pinMode(PIN_OUTPUT, OUTPUT);
  pinMode(PIN_TRIGGER, INPUT);
  pinMode(PIN_BUTTON, INPUT);
  pinMode(PIN_SWITCH, INPUT);
  analogWrite(PIN_OUTPUT, 1023);
  attachInterrupt(0, TriggerInterrupt, RISING);
  attachInterrupt(1, ButtonInterrupt, RISING);  
  Serial.begin(115200);
}

void loop() {
//  Serial.println(analogRead(1));
 if (Triggered)
 {
   digitalWrite(PIN_OUTPUT, LOW);
   delay(1000);
   digitalWrite(PIN_OUTPUT, HIGH);     
   Triggered = false;
 }
 
 if (ButtonPressed)
 {
 //  Serial.println("Button pressed");
    digitalWrite(PIN_OUTPUT, LOW);
    while (digitalRead( PIN_BUTTON))
    {      
    }
    digitalWrite(PIN_OUTPUT, HIGH);    
  // Serial.println("Button released");    
    delay(200);
    ButtonPressed = false;
 }
 
 

}
