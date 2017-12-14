#include <Wire.h>

#define DACaddr                         (0x62)  // I2C address of 4726 DAC (second is at 61)
#define MCP4726_CMD_WRITEDAC            (0x40)  // Writes data to the DAC
#define MCP4726_CMD_WRITEDACEEPROM      (0x60)  // Writes data to the DAC and the EEPROM (persisting the assigned value after reset)

void setup()
{
  Serial.begin(115200);
  Serial.println("Initializing");
  // put your setup code here, to run once:
  Wire.begin();
  setDAC(0);
  Serial.println("Init Done");
}



/*  setDAC(output, channel)
    Sets the output voltage to a fraction of source vref
    output 0 to 4095
    Buckpuck is full on below 1v and full off above 4v, nonlinear curve
    Off point value is about 650 depending on LED and supply voltage
*/

void setDAC_mV( uint16_t mv)
{
  setDAC(mv/1000.0 / 5.0 * 4095 );
}
void setDAC( uint16_t output)
{

  Serial.println("outputiing "+String(output));
  Wire.beginTransmission(DACaddr +1);  // select DAC0, 1, etc
  Wire.write((MCP4726_CMD_WRITEDAC));
  Wire.write(output / 16);                   // Upper data bits          (D11.D10.D9.D8.D7.D6.D5.D4)
  Wire.write((output % 16) << 4);            // Lower data bits          (D3.D2.D1.D0.x.x.x.x)
  Wire.endTransmission();
}




void loop()
{
  Serial.println("0");
  setDAC_mV(0);
  delay(3000);
  Serial.println("5V");
  setDAC_mV(5000);
  delay(3000);
  Serial.println("4V");
  setDAC_mV(4000);
  delay(3000);
  Serial.println("3V");
  setDAC_mV(3000);
  delay(3000);
  
}
 
