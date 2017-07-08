class StreamSoundRef extends SoundRef
    native;

// ============================================================================
// StreamSoundRef
//  
// A StreamSoundRef.  Encapsulates a streaming sound.  Handles the low
// level unreal call to play a streaming sound.
// ============================================================================

// Stream is the full pathname and filename of the stream.
var string Stream;              
var float  StreamDuration;

// These calls were moved in here because this will be the only class that will manage the 
// low level details of how to play a stream.
native private final function PlayStream(
    Actor  Actor,
    string Filename,
    optional int SampleRate,
    optional float Volume,
    optional float InnerRadius,
    optional float OuterRadius,
    optional float Pitch,
    optional int Priority,
    optional int Flags,
    optional float FadeInTime,
	optional float AISoundRadius,
	optional name SoundCategory);

native private final function StopStream(Actor Source, string Filename);
native private function bool PauseStream (Actor inActor, string inFilename);
native private function bool ResumeStream (Actor inActor, string inFilename);

simulated event string toString()
{
    return "StreamSoundRef playing Stream: "$Stream;
}

// Native c++ .h interface....
cpptext
{
    INT Play(ASoundInstance* inInstance);
    void Stop(ASoundInstance* inInstance);
    FLOAT GetDuration(ASoundInstance* inInstance);
    
    void Mute(ASoundInstance* inInstance);
    void UnMute(ASoundInstance* inInstance);
    void SetPitch(ASoundInstance* inInstance, FLOAT inPitch);
    void SetVolume(ASoundInstance* inInstance, FLOAT inVolume);
    void Recompile();
private:
    INT PlayStream(AActor* Actor, FString Filename, INT SampleRate, FLOAT Volume, FLOAT InnerRadius, FLOAT OuterRadius, FLOAT Pitch, INT Priority, INT Flags, FLOAT FadeInTime, FLOAT AISoundRadius, FName SoundCategory);
    void StopStream(ASoundInstance* inInstance);
}
