/*
 Author: Benjamin Low
 
 Description: Standard program used for interfacing Arduino with Flash. 
 Server echoes the serial port and echoes the client to the serial port. 
 Data used are all strings, including text and numerical data. Arduino 
 should use "Serial.print" instead of "Serial.write" to send integers
 as strings and text strings as text strings. Client should send all data 
 in the form of strings as well, including numbers. 
 
 Reads a coded string from 3 Arduino Sparkfun RFID readers such as "r1a1", 
 where r1 means 'reader 1' and a1 means 'audio 1'. There is r1 to r3, and 
 then for the tags a1 to a3, v1 to v3, w1 to w3. This is will be sent to the 
 server port to the client program.
 
 The client program, e.g. Flash, will send a string to control the three neopixel 
 strips depending on the RFID readouts. The string will be in the format such as "pulse_1" 
 (waiting indication mode for reader 1), "wrong_3" (wrong light indication for reader 3) 
 or "correct_2" (correct light indication for reader 2). 
 
 Translation function included for SCS E3. Used to control three NeoPixel
 strips. Translates commands from the socket to into a number to send to 
 the serial port for the Arduino.  
 
 Last updated: 3 Dec 2015
 */

import processing.net.*;
import processing.serial.*;

//USER DEFINED SETTINGS
final int NUM_PORTS = 1; 
final int NEOPIXEL_PORT_INDEX = 0; //which line index in the settings file is for the neopixel port

//averaging the readings
final int NUM_OF_READINGS = 5; //the higher the number, the smoother the transition, but more laggy
int[] array_readings = new int[NUM_OF_READINGS];
int average_sensor_value = 0;
int total_value = 0;
int my_index;

//network parameters
//String rfid1_portname, rfid2_portname, rfid3_portname, neopixel_portname;
Serial[] my_ports;
String[] portnames;
//Serial rfid1_port, rfid2_port, rfid3_port, neopixel_port;
Server my_server;
int server_port_num;
int baud_rate;

//for incoming serial data
String in_string, client_string;
int charvalue;
String buf="";
int cr = 13;  // ASCII return   == 13 //
int lf = 10;  // ASCII linefeed == 10 //
byte eol = 0;
int NEWLINE = 10;
byte nullByte = 0;

void setup() {

  size(600, 350);

  printArray(Serial.list());

  String[] lines = loadStrings("settings.txt");
  String[] my_line;
  
  portnames = new String[NUM_PORTS];

  for (int i=0; i<NUM_PORTS; i++) {
    my_line = split(lines[i], '=');
    portnames[i] = my_line[1];
  }

  my_line = split(lines[lines.length-2], '=');
  baud_rate = int(my_line[1]);

  my_line = split(lines[lines.length-1], '=');
  server_port_num = int(my_line[1]);

  my_server = new Server(this, server_port_num);

  my_ports = new Serial[NUM_PORTS];

  for (int i=0; i<NUM_PORTS; i++) {
    my_ports[i] = new Serial(this, portnames[i], baud_rate);
  }        

  for (int i=0; i<NUM_PORTS; i++) {
    print("PORT " + i + ": " + portnames[i]);
  }
  print("BAUD RATE = ");
  println(baud_rate);
  print("SERVER PORT = ");
  println(server_port_num);
}

void draw() 
{
  background(0);

  textSize(20);
  for (int i=0; i<NUM_PORTS; i++) {
    text("port name " + i + ": " + portnames[i], 20, 20+i*30);
  }
  text("baud rate: " + baud_rate, 20, 140);
  text("server port: " + server_port_num, 20, 170);

  // frame.setLocation(100, 100); //change to (-1000, -1000) to hide it

  String string_buffer = "";

  for (int i=0; i<NUM_PORTS; i++) {

    while (my_ports[i].available () > 0) { //read from serial port

      string_buffer = my_ports[i].readStringUntil(10);

      if (string_buffer != null) {

        in_string = trim(string_buffer);

        //smooth_data(); //averaging filter. Outputs average_sensor_value. Can comment out if not needed.

        my_server.write(in_string); //echo to server port
        my_server.write("\n");
      }
    }
  }

  if (NUM_PORTS > 1) text("From Arduino: " + in_string, 20, 250); 

  Client this_client = my_server.available();  //read from client 

  if (this_client != null) {

    if (this_client.available() > 0) 
    {           
      String a_string_buffer = this_client.readString();      

      if (a_string_buffer != null) {

        int translated = translation_table(a_string_buffer.trim());
        client_string = a_string_buffer.trim();

        //println(translated);

        my_ports[NEOPIXEL_PORT_INDEX].write(48 + translated); //write to the neopixel Arduino Mega serial port

        //                                serialPort.write(another_string_buffer); //echo to serial port
      }
    }
  }

  text("From client: " + client_string, 20, 300);
}


void smooth_data() { //averaging filter

  total_value = total_value- array_readings[my_index];

  array_readings[my_index] = int(in_string);

  total_value = total_value + array_readings[my_index];

  my_index = my_index + 1;

  if (my_index >= NUM_OF_READINGS) {

    my_index = 0;
    average_sensor_value = total_value / NUM_OF_READINGS;
  }
}

int translation_table (String _string) {

  int translated = -1;

  //println("string: " + _string);

  if (_string.equals("off_all")) {
    translated = 0;
  } else if (_string.equals("pulse_1")) {
    translated = 1;
  } else if (_string.equals("pulse_2")) {
    translated = 2;
  } else if (_string.equals("pulse_3")) {
    translated = 3;
  } else if (_string.equals("wrong_1")) {
    translated = 4;
  } else if (_string.equals("wrong_2")) {
    translated = 5;
  } else if (_string.equals("wrong_3")) {
    translated = 6;
  } else if (_string.equals("correct_1")) {
    translated = 7;
  } else if (_string.equals("correct_2")) {
    translated = 8;
  } else if (_string.equals("correct_3")) {
    translated = 9;
  } 

  return translated;
}

/* TEST PROGRAM TO CREATE CLIENT
 import processing.net.*; 
 Client myClient; 
 String in_string;
 
 void setup() { 
 size(200, 200); 
 // Connect to the local machine at port 5204.
 // This example will not run if you haven't
 // previously started a server on this port.
 myClient = new Client(this, "127.0.0.1", 5331);
 } 
 
 void draw() { 
 
 background(0);
 
 if (myClient.available() > 0) { 
 in_string = myClient.readString();
 } 
 if (in_string != null) {
 textSize(30);
 text("received: ", 20, 50);
 text(in_string, 20, 80);
 }
 }
 
 
 void keyPressed() {
 if (key == 'a') {
 myClient.write("0");
 }
 if (key == 's') {
 myClient.write("1");
 }
 }
 */