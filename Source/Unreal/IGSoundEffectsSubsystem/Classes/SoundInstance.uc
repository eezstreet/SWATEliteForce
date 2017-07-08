class SoundInstance extends Engine.Actor
    native;

// =============================================================================
//  SoundInstance
//  
//  A SoundInstance is created when a schema starts to play, and is destroyed when
//  the schema stops playing. This means that even if the sound is set to loop with
//  a 3 second delay (for example), the instance will be around until the sound is
//  told to stop, even during the pauses when there is nothing coming from the speakers.
//  SoundInstances themselves don't know how to play a sound, that functionality is 
//  encapsulated by whatever SoundRef object this instance refers to.
//
// ==============================================================================

// Note, const here means that these values can not be modified in unrealscript, only in c++
var transient const IEffectObserver             Observer;             // Class which can recieve callbacks based on EffectState
var transient const SoundEffectsSubsystem       Manager;              // A reference to the SoundEffectsSubsystem usefull for things like playing sounds.
var transient const SoundRef					ActualSound;          // The sound that is currently being controlled by this instance
var const SoundEffectSpecification				Schema;               // The SoundEffectsSpecification that this is an instance of

// Source management
var transient const Actor                       Source;               // The source actor that this Instance is being played on.
var transient const Vector                      SavedSourceLocation;  // The last known location of the source actor, in case it's been destroyed

// Timing variables
var const float                       StartTime;            // When this Instance should get started
var const float                       EndTime;              // When this Instance should get stopped
var const float                       NextPlayTime;         // NextPlayTime controls when to start after a delay in a loop
var const float                       NextStopTime;         // The next time that this sound is set to stop playing, for non-native loops
var const float                       Delay;                // The delay before the sound plays the first time
var const int                         CurrentLoopCount;     // How many times this instance has looped
var const Range                       LoopRange;            // Used to calculate delay between non-seamless loop samples
var const float                       FadeInTime;           // How long it takes for this sound to fade it's volume in
var const float                       FadeOutTime;          // ... and out.
// Controllable variables at runtime
var float                             Pitch;                // The current pitch of this soundinstance, can be modified at runtime
var float                             Volume;               // The current volume of this sound, can be changed dynamically

// Distance based variables
var const float                       OuterRadius;          // Controls when sounds become too distant to hear.
var const float                       InnerRadius;          // Controls when sounds become too close to hear...

// flag variables
var const bool                        Retriggerable;        // True if the sound retriggers itself when already playing on the same actor
var const bool		                  Paused;               // True if the instance is paused
var const bool		                  Muted;                // True if the instance is muted, or too far away to hear but still playing
var const bool                        Local;                // True if this sound plays without 2d attenuation
var const bool                        IsEndPredictable;     // True if this sound either plays once, or plays a known amount of times
var const bool                        IsMonoloop;           // True if this sound is a monophonic loop
var const bool                        IsPolyloop;           // True if this sound is a polyphonic loop
var const bool                        IsSeamlessLoop;       // True if this sound loops without delays

var const float                       AISoundRadius;
var const name                        SoundCategory;

// misc...
var const int                         Monophonic;           // SoundInstances with this value will cut out others with the same value
var const int                         MonophonicPriority;   // Modifies the above so a sound will cut off only if it's priority is greater than or equal
var const int                         Priority;             // What priority this sound should be played it.
var const bool                        MonophonicToClass;    // Will test monophonic settings on a per-class basis and not on a per-instance basis
var const int                         NativeFlags;          // The flags this sound is played with if applicable

var const int                         SoundHandle;

// Note that a sound could be Updating but not playing, but must be Updating to be playing.  This 
// is enforced internally by the SoundInstance
var const bool                        IsPlaying;             // True if this sound instance is playing.
var const bool		                  IsUpdating;            // True if this sound instance is updating.  

// Instances are responsible for starting and stopping themselves.  At least as far as the SoundEffectsSubsystem knows
native final function Play();
native final function Stop();
native final function SetObserver(IEffectObserver inObserver);

native final function SetPitch(float inPitch);
native final function SetVolume(float inVolume);

native final function float GetDuration();

// Conversion to string, mainly used for debugging, and kept in unrealscript for easy editing.
simulated event String toString() 
{
    local String SourceString;
    local String StringRep;

    SourceString = "{"$Self$", Name="$Source.Name$", Class="$Source.Class.Name$"}";
    StringRep = "[In Use: Source="$SourceString$", Spec="$Schema.name$", Updating="$IsUpdating$", Paused="$Paused$", Muted="$Muted$"]";
    
    if ( ActualSound == None )
        StringRep = StringRep$"SoundRef is NONE";
    else
    	StringRep = StringRep$" SoundRef Playing is: "$ActualSound.toString();

    return StringRep;
}

simulated function OnFinishedInitialized()
{
    if ( Observer != None )
        Observer.OnEffectInitialized(Self);
}


// Native .h exporting...
cpptext
{
private:
    // Returns wether the sound was stopped during the update
    UBOOL   HandleUpdating(FLOAT DeltaTime);
    void    UpdateSourceLocation();
    void    HandleDistanceMuting();
    
    void    CalculateNextPlayTime(FLOAT inCurrentTime);
    friend class USoundEffectSpecification;

public:
    virtual UBOOL Tick( FLOAT DeltaTime, enum ELevelTick TickType );
    void    PlaySound();
    void    StopSound();

    void    MuteSound();
    void    UnMuteSound();

    UBOOL    WantsToLoop();
    FLOAT    GetDuration();

    void    CleanupForDeposit();
}

defaultproperties
{
    bHidden=true
    bStasis=false
    bCollideActors=false
    bCollideWorld=false
    DrawType=DT_None
    RemoteRole=Role_None
    Pitch=1.0
    SoundHandle=-1
    bAlwaysTick=true
    // always tick so we get ticks while the game is paused...
}
