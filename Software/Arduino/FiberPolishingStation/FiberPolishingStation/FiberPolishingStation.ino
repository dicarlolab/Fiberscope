const int PIN_DIR = 12;
const int PIN_STEP = 11;
const int PIN_ENABLE = 10;
const int PIN_ONOFF = 9;
const int PIN_POT_MOTOR = 0;
const int PIN_LED = 7;
const int PIN_UP = 6;
const int PIN_DOWN = 5;
const int MOTOR_WAIT_TIME_USEC = 200; // TTL length

const float MICROMETER_FULL_ROTATION_UM = 500.0; // Full rotation of manipulator in micrometers
const long ENCODER_STEPS_FULL_REVOLUSTION = 1600;    // single step in degrees
const long MOTOR_STEPS_FULL_REVOLUSTION = 3200;


int dir = 1;
int numstepsperdirection = 1000;
int counter = 0;

void setup() {
  // put your setup code here, to run once:
  pinMode(PIN_DIR, OUTPUT);
  pinMode(PIN_STEP, OUTPUT);
  pinMode(PIN_ENABLE, OUTPUT);
  pinMode(PIN_ONOFF, INPUT);


  pinMode(PIN_UP, INPUT);
  pinMode(PIN_DOWN, INPUT);
  pinMode(PIN_LED, OUTPUT);

  digitalWrite(PIN_DIR, HIGH);
  digitalWrite(PIN_ENABLE, LOW);
  digitalWrite(PIN_LED, LOW);
  Serial.begin(115200);
}
float MotorSpeed =0;
void loop() {
  // put your main code here, to run repeatedly:
  bool OffButton = digitalRead(PIN_ONOFF);
  if (OffButton == 0)
  {
    bool UpButton = digitalRead(PIN_UP);
    bool DownButton = digitalRead(PIN_DOWN);
    if (UpButton || DownButton)
    {

      digitalWrite(PIN_LED, HIGH);
      while (digitalRead(PIN_UP) || digitalRead(PIN_DOWN)) ;
      digitalWrite(PIN_LED, LOW);

      digitalWrite(PIN_ENABLE, LOW);
      delay(100);
      digitalWrite(PIN_DIR, UpButton ? HIGH : LOW);


      float speedUmSec = 10;
      float singleMotorStepUm = (float)MICROMETER_FULL_ROTATION_UM / (float)MOTOR_STEPS_FULL_REVOLUSTION;
      float delayValueUsec = 1e6 / (speedUmSec / singleMotorStepUm) - MOTOR_WAIT_TIME_USEC; // neglecting digitalWrite...

      int StepAmplitudeUM = 100;
      int NumSteps = StepAmplitudeUM / singleMotorStepUm;
      int LED_Steps = 0;


      for (int k = 0; k < NumSteps; k++)
      {
        digitalWrite(PIN_STEP, HIGH);
        delayMicroseconds(MOTOR_WAIT_TIME_USEC);
        digitalWrite(PIN_STEP, LOW);
        delayMicroseconds(delayValueUsec); // STEP_WAIT_USEC

        LED_Steps++;
        if (LED_Steps == 10)
          digitalWrite(PIN_LED, HIGH);
        if (LED_Steps == 20)
          digitalWrite(PIN_LED, LOW);
        if (LED_Steps == 30)
          LED_Steps = 0;

      }
      digitalWrite(PIN_LED, LOW);


      digitalWrite(PIN_ENABLE, HIGH);
      delay(500);
    }
    return;
  }


  if (OffButton == 0)
    digitalWrite(PIN_ENABLE, HIGH);
  else
    digitalWrite(PIN_ENABLE, LOW);
  /*
    digitalWrite(PIN_DIR, dir ? HIGH : LOW);

    if (counter > numstepsperdirection )
    {
      counter = 0;
      dir = !dir;
    }
   */
   counter++;
    if (counter > 1000){
      MotorSpeed =  (analogRead(PIN_POT_MOTOR) / 1023.0);
     counter = 0;
}
  //Serial.println(MotorSpeed);
  digitalWrite(PIN_STEP, HIGH);
  delayMicroseconds(15);
  digitalWrite(PIN_STEP, LOW);
 // delayMicroseconds(55+30);
delayMicroseconds(85+MotorSpeed * 100);
  //

}
