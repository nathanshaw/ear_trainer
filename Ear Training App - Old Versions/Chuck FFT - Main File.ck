//sets up the FFT analysis chain
adc => FFT fft => blackhole;
fft =^ RMS rms => blackhole;
//the fill in for the samples i will convert to.
SndBuf piano => dac;
1 => piano.rate;
//SawOsc saw => dac;
//0 => saw.gain;
0 => int startingMIDI;
0 => int indexNumber;
0 => int adChance;
0 => int tonePlaceholder;
0 => int tempR => int tempG;
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
orec.event("/events/replaytone, f") @=> OscEvent toneTrigger;
orec.event("/events/newtone, f") @=> OscEvent newTone;
0.0 => float toneEvent;//used to send bangs to the SND buff instrument
0.0 => float newToneEvent;
//declaring unit analysis objects
UAnaBlob blobRMS;
UAnaBlob blobPitch;
//setting up RMS
0 => int rmsGate;
0.3 => float rmsThreshold;

44100.0 => float SAMPLE_RATE;
//Impliment this next step //VoicForm referenceTone => dac;

//fft set-up
4096 => fft.size => int FFT_SIZE;//frequency resolution
1024 => int WINDOW_SIZE;//time domain samples
Windowing.hann(WINDOW_SIZE) => fft.window;//creates actual window
WINDOW_SIZE/2 => int HOP_SIZE;

//set up for setting the reference tone
0 => int startInterval;
0 => int targetInterval;
0.0 => float targetFreq;
//arrays for the different registers
[48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72] @=> int pianoTones[];
[0,2,4,5,7,9,11,12] @=> int ascendingIntervals[];
[0,1,3,5,7,8,10,12] @=> int descendingIntervals[]; 



//spork my listening functions
spork ~ newTones();
spork ~ startingTone();

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
    if(toneEvent > 0){
        piano_samples[indexNumber] => piano.read;
        0 => piano.pos;
        <<<"tone event bang">>>;
        1::second => now;
    }
    
    
    if(rmsInfo > rmsThreshold){
        for(0 => int i; i < Z.cap(); i++){
            fft.fval(i) => Z[i];   
        }
        
        MaxIndex(Z) => MaxI;
        Bin2freq(MaxI, SAMPLE_RATE, FFT_SIZE) => float freq;
        <<<"You are singing at : ",freq," Hertz" >>>;
        xmit.startMsg( "/pitchinfo", "ii");
        255 - Math.abs(targetFreq - freq) => tempR;
         tempR => xmit.addInt;
        tempG => xmit.addInt;
        <<<"r", 200,"g", 155>>>;
        <<<"Your target Frequency is :", targetFreq, " Hertz">>>;
        //freq => saw.freq;
        if (freq == targetFreq){
            <<<"Congrats you Are Nailing it!!!">>>;   
        }
    }
    //<<<HOP_SIZE>>>;
    HOP_SIZE::samp => now;
}


//functions
fun float targetFrequency(int startTone){
    startTone => tonePlaceholder;
    //piano_samples[tonePlaceholder] => piano.read;
    <<<"target frequency function running">>>;
    //0 => piano.pos;
    Math.random2(0,1) => adChance;
    if(tonePlaceholder > 17){
        startTone - descendingIntervals[Math.random2(0,7)] => targetInterval;
        Std.mtof(targetInterval) => targetFreq; 
    }
    else if(tonePlaceholder < 11){
        startTone + ascendingIntervals[Math.random2(0,7)] => targetInterval; 
        Std.mtof(targetInterval) => targetFreq; 
    }
    else{
        if (adChance == 1){
            startTone - descendingIntervals[Math.random2(0,7)] => targetInterval;
            Std.mtof(targetInterval) => targetFreq; 
        }
        else{
            startTone + ascendingIntervals[Math.random2(0,7)] => targetInterval; 
            Std.mtof(targetInterval) => targetFreq;  
        }
    }
    return targetFreq;
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
            <<<"OSC in">>>;
            piano_samples[indexNumber] => piano.read;
            0 => piano.pos;
            1.0 => piano.rate;
            //1::second => now;            //toneTrigger.getFloat() => newToneEvent;
            <<<toneEvent>>>;
        }
        // 1::samp => now;
        
    }
}

fun void newTones(){
    while(1){
        newTone => now;
        if (newTone.nextMsg() != 0){
            <<<"new tone">>>;
            newTone.getFloat() => newToneEvent;   
            Math.random2(0,29) => indexNumber;
            <<<indexNumber>>>;
            pianoTones[indexNumber] => startingMIDI;
            targetFrequency(startingMIDI) => targetFreq;
            piano_samples[indexNumber] => piano.read;
            <<< "Your Target Pitch is :", targetFreq>>>;
            0 => piano.pos;
            //1::second => now;
        }   
        //1::samp => now;
    }   
}