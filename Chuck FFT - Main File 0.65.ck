//sets up the FFT analysis chain
adc => FFT fft => blackhole;
fft =^ RMS rms => blackhole;
//the fill in for the samples i will convert to.
SndBuf piano => dac;
1 => piano.rate;
//SawOsc saw => dac;
//0 => saw.gain;
0 => int targetIndex;
0 => int testInterval;//for feedback on the musical designation needed.
0 => int startingMIDI;
0 => int indexNumber;
0 => int adChance;
0 => int tonePlaceholder;
0 => float tempR => float tempG;
string piano_samples[30];
me.dir() + "/audio/piano/G2.wav" => piano_samples[0];
me.dir() + "/audio/piano/G#2.wav" => piano_samples[1];
me.dir() + "/audio/piano/A2.wav" => piano_samples[2];
me.dir() + "/audio/piano/A#2.wav" => piano_samples[3];
me.dir() + "/audio/piano/B2.wav" => piano_samples[4];
me.dir() + "/audio/piano/C3.wav" => piano_samples[5];
me.dir() + "/audio/piano/C#3.wav" => piano_samples[6];
me.dir() + "/audio/piano/D3.wav" => piano_samples[7];
me.dir() + "/audio/piano/D#3.wav" => piano_samples[8];
me.dir() + "/audio/piano/E3.wav" => piano_samples[9];
me.dir() + "/audio/piano/F3.wav" => piano_samples[10];
me.dir() + "/audio/piano/F#3.wav" => piano_samples[11];
me.dir() + "/audio/piano/G3.wav" => piano_samples[12];
me.dir() + "/audio/piano/G#3.wav" => piano_samples[13];
me.dir() + "/audio/piano/A3.wav" => piano_samples[14];
me.dir() + "/audio/piano/A#3.wav" => piano_samples[15];
me.dir() + "/audio/piano/B3.wav" => piano_samples[16];
me.dir() + "/audio/piano/C4.wav" => piano_samples[17];
me.dir() + "/audio/piano/C#4.wav" => piano_samples[18];
me.dir() + "/audio/piano/D4.wav" => piano_samples[19];
me.dir() + "/audio/piano/D#4.wav" => piano_samples[20];
me.dir() + "/audio/piano/E4.wav" => piano_samples[21];
me.dir() + "/audio/piano/F4.wav" => piano_samples[22];
me.dir() + "/audio/piano/F#4.wav" => piano_samples[23];
me.dir() + "/audio/piano/G4.wav" => piano_samples[24];
me.dir() + "/audio/piano/G#4.wav" => piano_samples[25];
me.dir() + "/audio/piano/A4.wav" => piano_samples[26];
me.dir() + "/audio/piano/A#4.wav" => piano_samples[27];
me.dir() + "/audio/piano/B4.wav" => piano_samples[28];
me.dir() + "/audio/piano/C5.wav" => piano_samples[29];

//setup for OSC coniation
OscRecv orec;
"localhost" => string hostname;
14002 => int port;//sending
10000 => orec.port;//receiving port
orec.listen();
//this is where i will put the events i will be receiving.
OscSend xmit;
xmit.setHost(hostname, port);
orec.event("/events/targettone, f") @=> OscEvent tarToneTrigger;
orec.event("/events/replaytone, f") @=> OscEvent toneTrigger;
orec.event("/events/newtone, f") @=> OscEvent newTone;
0.0 => float toneEvent;//used to send bangs to the SND buff instrument
0.0 => float newToneEvent;
0.0 => float percentOff;
//declaring unit analysis objects
UAnaBlob blobRMS;
UAnaBlob blobPitch;
//setting up RMS
0 => int rmsGate;
0.2 => float rmsThreshold;

44100.0 => float SAMPLE_RATE;
//Impliment this next step //VoicForm referenceTone => dac;

//fft set-up
8192 => fft.size => int FFT_SIZE;//frequency resolution
1024 => int WINDOW_SIZE;//time domain samples
Windowing.hann(WINDOW_SIZE) => fft.window;//creates actual window
WINDOW_SIZE/2 => int HOP_SIZE;

//set up for setting the reference tone
0 => int startInterval;
0 => int targetInterval;
0 => int targetFreq;
//arrays for the different registers
//[43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84] @=> int pianoTones[];
[55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84] @=> int pianoTones[];

[0,2,4,5,7,9,11,12] @=> int ascendingIntervals[];
[0,1,3,5,7,8,10,12] @=> int descendingIntervals[]; 



//spork my listening functions
spork ~ newTones();
spork ~ startingTone();
spork ~ targetTone();
//main loop
while (true){
    
    float Z[FFT_SIZE/2];
    int MaxI;//stores highest index value in FFT
    
    //calculate FFT
    rms.upchuck() @=> blobRMS;
    fft.upchuck() @=> blobPitch;
    //stores FFT data into array z (the magnitude)
    blobRMS.fval(0) * 1000 => float rmsInfo;
    //<<<"rms value :", rmsInfo>>>;
    /*if(toneEvent > 0){
        piano_samples[indexNumber] => piano.read;
        0 => piano.pos;
        <<<"tone event bang">>>;
        1::second => now;
    }*/
    
    
    if(rmsInfo > rmsThreshold){
        for(0 => int i; i < Z.cap(); i++){
            fft.fval(i) => Z[i];   
        }
        //for the FFT analysis
        MaxIndex(Z) => MaxI;
        Bin2freq(MaxI, SAMPLE_RATE, FFT_SIZE) => float freq;
        <<<"You are singing at : ",freq," Hertz" >>>;
        //this determines the percent off pitch you are from the target
        (Std.fabs(freq - Std.mtof(targetFreq)))/Std.mtof(targetFreq) => percentOff;
        
       //opens the message for data input 
        xmit.startMsg( "/pitchinfo", "ff");
        if (percentOff > 0.17){
            255 => xmit.addFloat;
      0 => xmit.addFloat;
        }
        else if (percentOff > 0.06){
         255 - (percentOff - 0.06)/(0.17/255) => xmit.addFloat;
      0 => xmit.addFloat;   
        }
        else if (percentOff > 0.029){
            (percentOff - 0.029)/(0.17/255) => xmit.addFloat;
      255 - (percentOff - 0.029)/(0.17/255) => xmit.addFloat;
        }
        else {
            
         0 => xmit.addFloat;
      255 - percentOff/(0.029/255) => xmit.addFloat;   
        }
       
       //Prints Out User Feedback Data
        <<<"Your Given Frequency is :", Std.mtof(startingMIDI)>>>;
        <<< "Your Target Pitch is :", Std.mtof(targetFreq)>>>;
        <<<"">>>;
        <<<"You are ", percentOff, "Off Pitch">>>;
        <<<"">>>;
        //if you are close it congratulates you
        if ((freq < Std.mtof(targetFreq) +3) && (freq > Std.mtof(targetFreq) - 3)){
            <<<"Congrats you Are Nailing it!!!">>>;   
            2::second => now;
        }
    }
    //<<<HOP_SIZE>>>;
    HOP_SIZE::samp => now;
}


//functions
fun int targetFrequency(int startTone){
    <<<"Starting Tone :", startTone>>>;
    //piano_samples[tonePlaceholder] => piano.read;
    //<<<"target frequency function running">>>;
    //0 => piano.pos;
    Math.random2(0,1) => adChance;
    if(startTone >= 60){
        startTone - descendingIntervals[Math.random2(0,7)] => startTone;
        //Std.mtof(targetInterval) => targetFreq; 
        startTone => targetIndex;
        return startTone;
        <<<"over 63">>>;
    }
    if(startTone < 60){
        startTone + ascendingIntervals[Math.random2(0,7)] => startTone; 
        //Std.mtof(targetInterval) => targetFreq; 
        startTone => targetIndex;
        return startTone;
        <<<"under 50">>>;
    }
    /*else{
        if (adChance == 1){
            startTone - descendingIntervals[Math.random2(0,7)] => startTone;
            //Std.mtof(targetInterval) => targetFreq; 
            return startTone;
            <<<"chance lowers">>>;
        }
        else{
            startTone + ascendingIntervals[Math.random2(0,7)] => startTone; 
            //Std.mtof(targetInterval) => targetFreq;  
            return startTone;
            <<<"chance raises">>>;
        }
    }*/
    
}

fun int MaxIndex(float A[]){
    0.0 => float tempMaxValue;
    0 => int tempMaxIndex;
    
    for ( 0=> int i; i < A.cap(); i++){
        if (tempMaxValue < A[i])
        {
            i => tempMaxIndex;
            A[i] => tempMaxValue;   
        }   
    }   
    return tempMaxIndex;
}

fun float Bin2freq(int bin, float sr, int fftsize){
    float freq;
    (bin * sr) / fftsize => freq;
    return freq;   
}

fun void startingTone(){
    while(true){
        toneTrigger => now;
        if(toneTrigger.nextMsg() != 0){
           // <<<"OSC in">>>;
            piano_samples[indexNumber] => piano.read;
            0 => piano.pos;
            1.0 => piano.rate;
            //1::second => now;            //toneTrigger.getFloat() => newToneEvent;
            //<<<toneEvent>>>;   
    }
    }
}

fun void targetTone(){
    while(true){
        tarToneTrigger => now;
        if (tarToneTrigger.nextMsg() != 0){
            <<<targetIndex>>>;
         piano_samples[targetIndex - 55] => piano.read;
         0 => piano.pos;
         1.0 => piano.rate; 
         <<<"tartone Trigger">>>;  
        }
    }   
}

fun void newTones(){
    while(1){
        newTone => now;
        if (newTone.nextMsg() != 0){
            <<<"new tone">>>;
            newTone.getFloat() => newToneEvent;   
            Math.random2(0,29) => indexNumber;
            //<<<"index number :", indexNumber>>>;
            pianoTones[indexNumber] => startingMIDI;
            <<<"Your Given MIDI Note is :", startingMIDI>>>;
            <<<"Your Given Frequency is :", Std.mtof(startingMIDI)>>>;
            targetFrequency(startingMIDI) => targetFreq;
            targetFreq - startingMIDI => testInterval;
            <<<"Sing ", testInterval, "semitones away from the given tone">>>;
            piano_samples[indexNumber] => piano.read;
            <<< "Your Target MIDI note is :", targetFreq>>>;
            <<< "Your Target Pitch is :", Std.mtof(targetFreq)>>>;
            0 => piano.pos;
            //1::second => now;
        }   
    }   
}