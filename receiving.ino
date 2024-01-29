//import XBee library 
#include <XBee.h>
#include <SoftwareSerial.h>
#define MAX_FRAME_DATA_SIZE 110
//The XBee object provides functions for sending and receiving packets.
XBee xbee = XBee();

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  xbee.setSerial(Serial);
}

Rx16Response rx16 = Rx16Response();
void loop() {
  // put your main code here, to run repeatedly:
  xbee.readPacket();
  //xbee.readPacket(100) ;
  //check if a packet was received:
  if (xbee.getResponse().isAvailable()) {
        if (xbee.getResponse().getApiId() == RX_16_RESPONSE) {
                xbee.getResponse().getRx16Response(rx16);
        }
  rx16.getRemoteAddress16();
  rx16.getRssi();}
  for (int i = 0; i < rx16.getDataLength(); i++) { 
         Serial.println(rx16.getData(i), BIN); 
       }

} 

 //error handling
  //for (int i = 0; i < rx.getDataLength(); i++) { 
 // nss.print(rx.getData(i), BYTE); } 
 // if (xbee.getResponse().isError()) {
 //   // get the error code
 //   xbee.getResponse().getErrorCode()
 // } 
  

