void setup() {
  // put your setup code here, to run once:
  analogReadResolution(12);
  Serial.begin(115200);
  pinMode(13, OUTPUT);
  pinMode(13, LOW);
}

void loop() {
  // put your main code here, to run repeatedly:
  double avg;
  int N = 100;
  avg = 0;
  for (int k = 0; k < N; k++)
  {
    avg += analogRead(0);
  }
  digitalWrite(13, avg / N > 800 ? HIGH : LOW);
}
