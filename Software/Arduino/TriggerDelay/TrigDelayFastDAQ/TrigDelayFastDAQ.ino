const int PIN_OUT = 3;       /* Output pin 13 NOTE must also changed bitbanged PORTB in OutputPulses */
const int PIN_IN = 2;         /* Input trigger pin 2 */

/*  setup()
 *  Setup IO, interrupts, and global variables
 */

void setup() {
  pinMode(PIN_OUT, OUTPUT);   /* Setup output pulse pin */
  pinMode(PIN_IN, INPUT);     /* Setup input trigger pin */
 }


void loop() {
   PORTD |= (1<<3); 
  PORTD &= ~(1<<3);

  PORTD |= (1<<3); 
  PORTD &= ~(1<<3);

 PORTD |= (1<<3); 
  PORTD &= ~(1<<3);  
}  
