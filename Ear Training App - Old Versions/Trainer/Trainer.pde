import oscP5.*;
import netP5.*;
//set up OSC info
OscP5 oscP5;
NetAddress myRemoteLocation;

float replayTone = 0.0;
float changeTone = 0.0;

void setup(){
  background (255);
  size(200,200);
 
 oscP5 = new OscP5(this, 14002);
 myRemoteLocation = new NetAddress("127.0.0.1", 14000);
}

void draw(){
  
  frameRate(86);//how many times a second we get out FFT bins in chuck 
 
  
  
}

void eventSend(){
  OscMessage eventsend = new OscMessage("/events");
  eventsend.add(replayTone);
  eventsend.add(changeTone);
  println("signal sent");
  oscP5.send(eventsend, myRemoteLocation);
 
}


void oscEvent(OscMessage theOscMessage){
 
  println("Pattern: "+ theOscMessage.addrPattern()); 
  String addr = theOscMessage.addrPattern();
  float val = theOscMessage.get(0).floatValue();
  if (addr.equals("/1/push1")){
    replayTone = val;
  }
  else if (addr.equals("/1/push2")){
    changeTone = val;
  }
}
