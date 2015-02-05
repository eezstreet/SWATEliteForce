interface ISpeechClient
    dependsOn(SpeechManager);

import enum SpeechRecognitionConfidence from SpeechManager;

// Called when recognition of a phrase begins
function OnSpeechPhraseStart();

// Rule refers to the NAME of the RULE that was recognized
// Value refers to the VALSTR of the PHRASE that was recognized
function OnSpeechCommandRecognized(name Rule, Array<name> Value, SpeechRecognitionConfidence Confidence);

// Called when audio is received but nothing is recognized
function OnSpeechFalseRecognition();

// Called with the level of the microphone audio
function OnSpeechAudioLevel(int Value);