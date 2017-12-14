const int NPN_FOR_PUMP_PIN = 4;
const int BNC_PIN = 2;
const int BUTTON_PIN = 3;
const int LED_PIN = 13;

bool triggered1 = false;
bool triggered2 = false;
void triggered_isr1()
{
  triggered1 = true;
}
void triggered_isr2()
{
  triggered2 = true;
}
void setup() {
  // put your setup code here, to run once:
  pinMode(NPN_FOR_PUMP_PIN, OUTPUT);
  pinMode(BNC_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT);
  attachInterrupt(0, triggered_isr1, RISING);
  attachInterrupt(1, triggered_isr2, RISING);
    digitalWrite(NPN_FOR_PUMP_PIN, HIGH);
    digitalWrite(LED_PIN, LOW);
  Serial.begin(115200);
}

long led_timer = millis();
int led_state = 0;
void loop() {
  if (triggered1)
  Serial.println("BNC Trig");
  if (triggered2)
  Serial.println("BUT Trig");

  
  if (millis() - led_timer > 3000 && led_state == 0)
  {
    led_state = 1;
    led_timer = millis();
     digitalWrite(LED_PIN, HIGH);
  }

 if (millis() - led_timer > 1000 && led_state == 1)
  {
    led_state = 0;
    led_timer = millis();
     digitalWrite(LED_PIN, LOW);
  }
  
  // put your main code here, to run repeatedly:
  if (triggered1 || triggered2) {
    digitalWrite(NPN_FOR_PUMP_PIN, LOW);
    digitalWrite(LED_PIN, HIGH);
    while (digitalRead(BNC_PIN) || digitalRead(BUTTON_PIN));
    digitalWrite(NPN_FOR_PUMP_PIN, HIGH);
    digitalWrite(LED_PIN, LOW);
    triggered1 = false;
     triggered2 = false;
  }
}
