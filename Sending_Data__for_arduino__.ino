//import XBee library 
#include <XBee.h>

//The XBee object provides functions for sending and receiving packets.
XBee xbee = XBee();

void setup() {
  //In the setup function, initialize a serial port with a baud rate and provide to the library
  Serial.begin(9600);
  xbee.setSerial(Serial);
}

  //There a several different types of transmit (TX) packets available. 
  //A list of all TX packets can be found in the API documentation. 
  //All classes that end in "Request" are TX packets.
  //create an array to contain the data to be sent.
  // uint8_t payload[] = { 0, 0 };
  uint8_t payload[] = {0};
  //The data type is uint8_t, which is an unsigned byte. 
  //This array has a length of two. You should create an array that is properly sized to 
  //support that amount of data you want to send. Max payload size: 100 bytes for Series 1

  //create a TX packet. The TX packet contains the payload, address of the remote XBee that 
  //should receive it, and a few other options.
  Tx16Request tx = Tx16Request(0x5678, payload, sizeof(payload));
  //Here we are specifying the payload to send and the 16-bit address of the radio that will receive the packet.
  //This address must equal the MY value of the receiving radio!!!!!
  //ANDREA: MY Value of receiver is 5678 (Defined in XCTE software)
void loop() {
  // put your main code here, to run repeatedly:
  // In the loop function we get an analog reading and store it in the payload:
  // pin5 = analogRead(5);
  // payload[0] = pin5 >> 8 & 0xff;
  // payload[1] = pin5 & 0xff;
  //ANDREA: MAYBE I should try it with a push button first? 
  //Because it's only on and off so only one byte and it's a digital signal so I would have to change lines 33-35
  pinMode(2, INPUT_PULLUP);
  payload[0]=digitalRead(2);

  xbee.send(tx);
}
