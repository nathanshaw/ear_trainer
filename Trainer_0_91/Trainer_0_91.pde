import oscP5.*;
import netP5.*;
//set up OSC info
OscP5 oscP5;
NetAddress myRemoteLocation;
float targetTone = 0.0;
float replayTone = 0.0;
float changeTone = 0.0;
//for background
int red = 0;
int green = 0;


void setup() {
  background (255,255,0);
  size(500, 600);
  //sets up osc for 
  oscP5 = new OscP5(this, 14002);//listening
  
  myRemoteLocation = new NetAddress("127.0.0.1", 10000);//sending
  
  OscMessage eventsend = new OscMessage("/events/newtone");
  eventsend.add(1.0);
  //println("signal sent");
  oscP5.send(eventsend, myRemoteLocation);
}

void draw() {

  frameRate(86);//how many times a second we get out FFT bins in chuck 

  background (red, green, 0);
  //background(255,255,0);
}

void eventSend() {
  if( replayTone > 0 ){
  OscMessage eventsend = new OscMessage("/events/replaytone");
  eventsend.add(1.0);
  //println("signal sent");
  oscP5.send(eventsend, myRemoteLocation);
  }
}


void oscEvent(OscMessage theOscMessage) {
  println("Pattern: "+ theOscMessage.addrPattern()); 
  String addr = theOscMessage.addrPattern();
  
  if (addr.equals("/1/push1")) {
    float val = theOscMessage.get(0).floatValue();
    replayTone = val;
    if(replayTone > 0){
    OscMessage eventsend = new OscMessage("/events/replaytone");
  eventsend.add(replayTone);
  oscP5.send(eventsend, myRemoteLocation);
  //println("signal sent");
    
    }
  }
  else if (addr.equals("/1/push2")) {
    float val = theOscMessage.get(0).floatValue();
    changeTone = val;
    if (changeTone > 0){
    OscMessage eventsend = new OscMessage("/events/newtone");
  eventsend.add(changeTone);
  oscP5.send(eventsend, myRemoteLocation);
  //println("signal sent");
    }
  }
  else if (addr.equals("/1/push3")){
    float val = theOscMessage.get(0).floatValue();
    targetTone = val;
    if(targetTone > 0){
    OscMessage eventsend = new OscMessage("/events/targettone");
    eventsend.add(targetTone);
    oscP5.send(eventsend, myRemoteLocation);
  //println("signal sent");
    }
  }
  else if (addr.equals("/pitchinfo")) {
    red = int(theOscMessage.get(0).floatValue());
    green = int(theOscMessage.get(1).floatValue());
    println("Red : " + red);
    println("Green : " + green);
  }
}

