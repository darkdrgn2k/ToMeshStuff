// Feather9x_TX
// -*- mode: C++ -*-
// Example sketch showing how to create a simple messaging client (transmitter)
// with the RH_RF95 class. RH_RF95 class does not provide for addressing or
// reliability, so you should only use RH_RF95 if you do not need the higher
// level messaging abilities.
// It is designed to work with the other example Feather9x_RX

#include <SPI.h>
#include <RH_RF95.h>

/* for feather32u4 */
#define RFM95_CS 8
#define RFM95_RST 4
#define RFM95_INT 7

// Change to 434.0 or other frequency, must match RX's freq!
#define RF95_FREQ 915.0

// Singleton instance of the radio driver
RH_RF95 rf95(RFM95_CS, RFM95_INT);

void setup() 
{
  pinMode(RFM95_RST, OUTPUT);
  digitalWrite(RFM95_RST, HIGH);

  Serial.begin(115200);
  while (!Serial) {
    delay(1);
  }
  Serial1.begin(115200);

  delay(100);

  Serial.println("Starting");
  Serial1.println("Starting");

  // manual reset
  digitalWrite(RFM95_RST, LOW);
  delay(10);
  digitalWrite(RFM95_RST, HIGH);
  delay(10);

  while (!rf95.init()) {
    Serial.println("LoRa radio init failed");
    Serial1.println("LoRa radio init failed");
    while (1);
  }
  Serial.println("LoRa radio init OK!");
  Serial1.println("LoRa radio init OK!");

  // Defaults after init are 434.0MHz, modulation GFSK_Rb250Fd250, +13dbM
  if (!rf95.setFrequency(RF95_FREQ)) {
    Serial.println("setFrequency failed");
    Serial1.println("setFrequency failed");
    while (1);
  }
  Serial.print("Set Freq to: "); Serial.println(RF95_FREQ);
  Serial1.print("Set Freq to: "); Serial1.println(RF95_FREQ);
  
  // Defaults after init are 434.0MHz, 13dBm, Bw = 125 kHz, Cr = 4/5, Sf = 128chips/symbol, CRC on

  // The default transmitter power is 13dBm, using PA_BOOST.
  // If you are using RFM95/96/97/98 modules which uses the PA_BOOST transmitter pin, then 
  // you can set transmitter powers from 5 to 23 dBm:
  rf95.setTxPower(23, false);
}

int16_t packetnum = 0;  // packet counter, we increment per xmission
char readLine[RH_RF95_MAX_MESSAGE_LEN];

void writeLora(char *val,int len) {
  rf95.send((uint8_t *)val, len+1);
  Serial.print("<");
  Serial.print(len, DEC);
  Serial.print("<");  
  Serial.println((char*)val);

  Serial1.print("<");
  Serial1.println((char*)val);

  delay(10);
  rf95.waitPacketSent();
}

void loop()
{

  int incomingByte;
  int pos=0;
  while (Serial.available()) {
    incomingByte = Serial.read();
    readLine[pos] = incomingByte;
    pos++;
  }
  readLine[pos] = 0;  
  if (pos >0) writeLora(readLine,pos);
  pos=0;
  while (Serial1.available()) {
    incomingByte = Serial1.read();
    readLine[pos] = incomingByte;
    pos++;
  }
  readLine[pos] = 0;  
  if (pos >0) writeLora(readLine,pos);
  


  // Now wait for a reply
  uint8_t buf[RH_RF95_MAX_MESSAGE_LEN];
  uint8_t len = sizeof(buf);

  if (rf95.available())
  { 
    if (rf95.recv(buf, len))
   {
      buf[len]=0;
      Serial.print(rf95.lastRssi(), DEC);
      Serial.print(">");
      Serial.print(len, DEC);
      Serial.print(">");
      Serial.println((char*)buf);
      Serial1.print(rf95.lastRssi(), DEC);
      Serial1.print(">");
      Serial1.println((char*)buf);
    }
    else
    {
      Serial.println("Receive failed");
      Serial1.println("Receive failed");
    }
  }
}
