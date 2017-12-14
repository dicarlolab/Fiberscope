#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x3F, 2, 1, 0, 4, 5, 6, 7, 3, POSITIVE);  // Set the LCD I2C address


const int MOTOR_TTL_USEC = 40;

const int MOTOR1_STEP = 9;
const int MOTOR1_DIR = 8;
const int MOTOR1_EN = 7;

const int MOTOR2_STEP = 6;
const int MOTOR2_DIR = 5;
const int MOTOR2_EN = 4;

const int JOYSTICK_BTN = 10;
const int JOYSTICK_X = 0;
const int JOYSTICK_Y = 1;
int baselineJoystickX = 0;
int baselineJoystickY = 0;
const int JoystickNoise = 30;
const int NumSteps = 100;

unsigned long motor1ticks = 0;
unsigned long motor2ticks = 0;

unsigned long prev_motor1ticks = 0;
unsigned long prev_motor2ticks = 0;

void setup() {
  lcd.begin(20, 4);  // initialize the lcd for 16 chars 2 lines, turn on backlight
  lcd.backlight();
  lcd.setCursor(0, 0); //Start at character 4 on line 0
  lcd.print("Initializing");

  // put your setup code here, to run once:
  pinMode(MOTOR1_STEP, OUTPUT);
  pinMode(MOTOR1_DIR, OUTPUT);
  pinMode(MOTOR1_EN, OUTPUT);
  pinMode(MOTOR2_STEP, OUTPUT);
  pinMode(MOTOR2_DIR, OUTPUT);
  pinMode(MOTOR2_EN, OUTPUT);
  // turn off motors
  digitalWrite(MOTOR1_EN, HIGH);
  digitalWrite(MOTOR2_EN, HIGH);

  // estimate joystick base values
  unsigned long tmpX = 0;
  unsigned long tmpY = 0;
  int numSamples = 100;
  for (int k = 0; k < numSamples; k++)
  {
    tmpX += analogRead(JOYSTICK_X);
    tmpY += analogRead(JOYSTICK_Y);
  }
  baselineJoystickX = tmpX / numSamples;
  baselineJoystickY = tmpY / numSamples;
  // Ser*ial.println("Base line is : " + String(baselineJoystickX)+ " " + String(baselineJoystickY));
  lcd.clear();
  updateScreen();

}

void updateScreen()
{
  // convet ticks to mm?
  const float TPI = 80;
  const long MOTOR_TICKS_FULL_REVOLUSTION = 3200;

  float OneTickInMM = 1.0 / MOTOR_TICKS_FULL_REVOLUSTION * 1.0 / (TPI / 25.4);
  lcd.setCursor(0, 0);
  lcd.print("X:" + String(motor2ticks * OneTickInMM, 3));
  lcd.setCursor(0, 1);
  lcd.print("Y:" + String(motor1ticks * OneTickInMM, 3));
  lcd.setCursor(0, 2);
  lcd.print(String(millis()));
}

unsigned long t0 = millis();

void loop() {

  if (millis() - t0 > 500)
  {
    if (prev_motor1ticks != motor1ticks || prev_motor2ticks != motor2ticks)
    {
      prev_motor1ticks = motor1ticks;
      prev_motor2ticks = motor2ticks;
      updateScreen();
      t0 = millis();
    }
  }

  // put your main code here, to run repeatedly:
  int Jx = -(analogRead(JOYSTICK_X) - baselineJoystickX);
  int Jy = -(analogRead(JOYSTICK_Y) - baselineJoystickY);

  if (fabs(Jx) > JoystickNoise )
  {
    
    digitalWrite(MOTOR1_DIR, Jx > 0 ? HIGH : LOW);
    digitalWrite(MOTOR1_EN, LOW);
    while (1) 
    {
      Jx = -(analogRead(JOYSTICK_X) - baselineJoystickX);
      if (fabs(Jx) < JoystickNoise )
        break;
    for (int k = 0; k < NumSteps; k++) {
      digitalWrite(MOTOR1_STEP, HIGH);
      delayMicroseconds(MOTOR_TTL_USEC);
      digitalWrite(MOTOR1_STEP, LOW);
      delayMicroseconds(MOTOR_TTL_USEC);
    }
    motor1ticks += NumSteps;
    }
  digitalWrite(MOTOR1_EN, HIGH);
  }

  if (fabs(Jy) > JoystickNoise )
  {
    digitalWrite(MOTOR2_DIR, Jy > 0 ? HIGH : LOW);
    digitalWrite(MOTOR2_EN, LOW);
    while (1)
    {
    Jy = -(analogRead(JOYSTICK_Y) - baselineJoystickY);
    if (fabs(Jy) < JoystickNoise )
      break;
    for (int k = 0; k < NumSteps; k++) {
      digitalWrite(MOTOR2_STEP, HIGH);
      delayMicroseconds(MOTOR_TTL_USEC);
      digitalWrite(MOTOR2_STEP, LOW);
      delayMicroseconds(MOTOR_TTL_USEC);
    }
    motor2ticks += NumSteps;
    }
    digitalWrite(MOTOR2_EN, HIGH);
  }
  

}
