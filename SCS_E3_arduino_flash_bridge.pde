/*
 Author: Benjamin Low
 
 Description: Standard program used for interfacing Arduino with Flash. 
 Server echoes the serial port and echoes the client to the serial port. 
 Data used are all strings, including text and numerical data. Arduino 
 should use "Serial.print" instead of "Serial.write" to send integers
 as strings and text strings as text strings. Client should send all data 
 in the form of strings as well, including numbers. 
 
 Translation function included for SCS E3. Used to control three NeoPixel
 strips. Translates commands from the socket to into a number to send to 
 the serial port for the Arduino.  
 
 Last updated: 26 Nov 2015
 */

import processing.net.*;
import processing.serial.*;

//averaging the readings
final int NUM_OF_READINGS = 5; //the higher the number, the smoother the transition, but more laggy
int[] arrayReadings = new int[NUM_OF_READINGS];
int averageSensorValue = 0;
int totalValue = 0;
int my_index;

// Define for setting file
String[] lines;
int a = 0;//index of comport
int b = 1;//index of baud rate
int c = 2;//index of server port
int index = 0;

// Define your Serial port from the Arduino IDE, tools - serialport
String portname = "COM1";
Serial serialPort;
int BR = 9600;

String buf="";
int cr = 13;  // ASCII return   == 13 //
int lf = 10;  // ASCII linefeed == 10 //

// the Network stuff
int port = 9001;
Server myServer;

//for incoming serial data
String in_string;
int charvalue;

//ASCII code for sending
byte eol = 0;
int NEWLINE = 10;
byte nullByte = 0;

void setup() {
        size(400, 400);
        printArray(Serial.list());

        lines = loadStrings("setting.txt");
        if (index < lines.length) {
                String[] comport = split(lines[a], '=');
                portname = comport[1];
                print("COMPORT=");
                println(comport[1]);
                String[] br = split(lines[b], '=');
                BR = int(br[1]);
                print("BR=");
                println(br[1]);
                String[] serverPort = split(lines[c], '=');
                port = int(serverPort[1]);
                print("SERVER PORT=");
                println(serverPort[1]);
        }    


        myServer = new Server(this, port);
        serialPort = new Serial(this, portname, BR);
        println("set up");
}

void draw() 
{
        background(0);

        textSize(20);
        text("Port name: " + portname, 20, 20);
        text("baud rate: " + BR, 20, 50);
        text("port: " + port, 20, 80);

        // frame.setLocation(100, 100); //change to (-1000, -1000) to hide it

        String string_buffer = "";

        while (serialPort.available () > 0) { //read from serial port

                string_buffer = serialPort.readStringUntil(10);
                if (string_buffer != null) {
                        in_string = trim(string_buffer);
                        //smooth_data(); //averaging filter. Can comment out if not needed.
                }
        }

        myServer.write(str(averageSensorValue)); //echo to server port
        myServer.write("\n");
        //println(in_string);
        text("From Arduino: " + averageSensorValue, 20, 200);

        Client thisClient = myServer.available();  //read from client 

        String another_string_buffer = "";

        if (thisClient != null) {
                if (thisClient.available() > 0) 
                {           
                        another_string_buffer = thisClient.readString();      

                        if (another_string_buffer != null) {
                                int translated = translation_table(another_string_buffer.trim());
                                println(translated);
                                serialPort.write( 48 + translated );
//                                serialPort.write(another_string_buffer); //echo to serial port
                        }
                }
        }
        text("From client: " + another_string_buffer, 20, 300);
}


void smooth_data() { //averaging filter

        totalValue = totalValue- arrayReadings[my_index];

        arrayReadings[my_index] = int(in_string);

        totalValue = totalValue + arrayReadings[my_index];

        my_index = my_index + 1;

        if (my_index >= NUM_OF_READINGS) {
                my_index = 0;
                averageSensorValue = totalValue / NUM_OF_READINGS;
        }
}

int translation_table (String _string) {

        int translated = 0;
        
        println("string: " + _string);

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
