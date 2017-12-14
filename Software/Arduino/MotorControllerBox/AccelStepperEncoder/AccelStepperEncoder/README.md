AccelStepperEncoder
===================

A subclass of Mike McCauley's excellent AccelStepper library (http://www.airspayce.com/mikem/arduino/AccelStepper) that uses an encoder to record and correct motion.

This is intended to be used where an encoder (such as http://www.coolcomponents.co.uk/rotary-encoder-200-p-r-quadrature.html) is coupled to the output of a stepper motor. In my case, as part of my Polargraph drawing machine project, I have a stepper motor that is pulling a length of beaded cord using a sprocket. This cord also passes over an idler sprocket attached to the encoder. 

From time to time (such as if a toddler begins to devour the cords), a motor step does not result in the cord moving, either because the motor is held still (dropping steps), or when the motor still manages to move, but the cord jumps through the teeth of the sprocket.

This subclass of AccelStepper rolls the encoder object into it, and will allow AccelStepper to spot failed steps and retry. At first, it will be as simple as that, because that's about as clever as I am, but I think a smarter guy might be able to do some PIDdy stuff to make it work a bit less naively.

The use case for this is:
=========================
Polargraph machine is half way through a 20 minute drawing, when a baby with preturnaturally long arms reaches out from its papoose, and grasps the shiny wriggling pen. Normally this means game over, and the rest of the drawing is painfully offset and distorted. With AccelStepperEncoder the machine spots that an instruction to move 1 step has resulted in a 10,000 step change in actual position, and concludes that there has been a "drawing exception", lifts the pen off the paper and works to return it to it's proper place, picking up where it left off.

Second use case:
================
I've just set off a portrait, but forgotten to put a new sheet of paper up, or it's fallen off as soon as I started, or something like that. Normally, pausing the machine locks the motors so that the position is not lost. This causes the motors to heat up, and means the pen is fixed right in the way of the paper. With AccelStepperEncoder, a pause will halt the command queue AND turn off the motors, so the pen can be moved safely out of the way.

Third use case:
===============
The machine is set up to draw a small feature once an hour (a la Matt Venn's Cursive Data energy monitor https://github.com/mattvenn/cursivedata). Currently, to stay calibrated, the motors must never be turned off, and that leads to all kinds of problems (heat mostly), as well as being a waste of lecky. Matt's solution to this is to turn the power of the motors down so that they are still just locked enough to stay in place, but there seem to be no off-the-shelf motor drivers that facilitate this kind of programmatic power control. This encoder approach is a completely over-engineered solution (as well as being MUCH more expensive). But, with AccelStepperEncoder, the motors can simply be turned off after each feature, and re-enabled before the next one, and it will pick up where it left off.

At least, that's the theory. Have to actually write it now.

I would be surprised if this problem is not already extremely well-solved in industrial contexts, with a proper hardware feedback loop.
