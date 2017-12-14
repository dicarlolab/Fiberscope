/* Produce delayed 500kHz pulses for the 1608GX
 * On rising edge of D2, wait 22uS then pulse D13 10x (1us high, 1us low)
 * 
 * Original code by Shay Ohayon
 * Interrupts and timing optimizations by Josh Wardell
 * 
 * 02/29/2016 JLW Change to 1us high and low output, remove pullup, tweak interrupt
 * 02/26/2016 JLW Documentation, cleanup, removal of libraries and unused code 
 * 02/25/2016 JLW Timing tweaks, disabled Timer0 to remove occasional jitter
 * 02/24/2016 JLW Rewrite to use hardware interrupt, attempt multiple libraries
 * ??/??/???? S?O Original code
 */

 /* Global constant and variable declarations */

const int PIN_OUT = 13;       /* Output pin 13 NOTE must also changed bitbanged PORTB in OutputPulses */
const int PIN_IN = 2;         /* Input trigger pin 2 */
//volatile int state;


/*  OutputPulses()
 *  Initial day to 22us after trigger
 *  Output ten TTL pulses on D13
 *  Bit-banged for precise timing of 1us high, 2us low
 *  Removed loop due to timing inconsistencies
 *  PORTB used instead of digitalWrite for speed
 */

void OutputPulses() {
  delayMicroseconds(18);      /* Initial delay to get to 22us after trigger */
  __asm__("nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t""nop\n\t"); /* Get closer to 22us */
  
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  delayMicroseconds(1);       /* Stay low 2us */
  PORTB |= B00100000;         /* Set 13 high */
  delayMicroseconds(1);       /* Stay high 1us */
  PORTB &= B11011111;         /* Set 13 low */
  //state = 0;                  /* Set state to note we are not busy */
}

/*  TriggerISR()
 *  Function activated by D2 trigger hardware interrupt
 *  Call OutputPulses() to output TTL pulses
 *  Use state flag to verify we are not still busy with output
 */

void TriggerISR() {
  EIMSK = 0x00;               /* Disable interrupt during output */
  OutputPulses();             /* Run output pulse function */
  EIMSK = 0x01;               /* Re-enable interrupt */
}

/*  setup()
 *  Setup IO, interrupts, and global variables
 */

void setup() {
  pinMode(PIN_OUT, OUTPUT);   /* Setup output pulse pin */
  pinMode(PIN_IN, INPUT);     /* Setup input trigger pin */
  digitalWrite(PIN_OUT, LOW); /* Initial state of output low */
  /*digitalWrite(PIN_IN, HIGH); /* Enable pull-up so pin is not floating */
  //state = 0;                  /* Initialize state flag to not busy */
  TIMSK0 &= ~_BV(TOIE0);      /* Disable timer0 overflow interrupt so trigger interrupt is not interrupted */
  attachInterrupt(digitalPinToInterrupt(PIN_IN), TriggerISR, RISING); /* Interrupt on pin 2, run TriggerIS, on pin 2 rising edge */
}

/*  loop()
 *  Main loop does nothing, all activity performed by interrupts
 */

void loop() {
  while(1);
/*  if (state == 0)             /* State machine flag to make sure we are not interrupting previous output */
/*  {
    if (digitalRead(PIN_IN) == LOW)
    {
      attachInterrupt(digitalPinToInterrupt(PIN_IN), TriggerISR, RISING); /* Interrupt on pin 2, run TriggerIS, on pin 2 rising edge */
/*    }
  }*/
}
