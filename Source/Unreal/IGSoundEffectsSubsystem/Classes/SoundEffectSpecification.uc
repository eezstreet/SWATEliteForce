class SoundEffectSpecification extends IGEffectsSystem.EffectSpecification
    config(SoundEffects)
    PerObjectConfig
    abstract
    native;

// ============================================================================
// SoundEffectSpecification
//  
// A SoundEffectSpecification is an EffectSpecification that handles how a sound
// should be played.  It is the main class that the sound designer will deal with 
// in the editor.  It's a generic template for sounds that are played matching 
// this specification. Subclasses contain a list of sounds that can be randomly 
// chosen from and played according to the given parameters.
//
// ============================================================================

const kNoTime                       = 1000000000.0;

// NOTICE!: These are the sound flags from UnAudio.h
// They need to be kept in sync...
const SF_Looping                    = 2;
const SF_Streaming                  = 4;
const SF_LoopingStream              = 8;
const SF_No3D                       = 16;
const SF_UpdatePitch                = 32;
const SF_NoUpdates                  = 64;
const SF_RootMotion		            = 128;
const SF_NoOverride                 = 256;
const SF_VolumePriority             = 512;

// Specific categories for sounds, used mainly for having category-specific volume sliders
const SF_Ambient                    = 1024;
const SF_Voice                      = 2048;
const SF_Music                      = 4096;
const SF_VOIP						= 16384;

enum EVolumeCategory
{
    VOL_Normal,
    VOL_Ambient,
    VOL_Voice,
    VOL_Music
};
var protected config EVolumeCategory VolumeCategory;

// ============================================================================
// Config variables that the sound designer directly has access to...
// ============================================================================
var protected config int                      SampleRate;          // The samplerate of the sound.  This should be eventually handled in hardware
var protected config float                    OuterRadius;         // The radius of which the sound will stop playing
var protected config float                    InnerRadius;         // The inner radius where the sound will play at full value
var protected config int                      Volume;              // The volume this sound should play at 
var protected config float                    Pitch;               // The pitch multiplier, off of 1.0
var protected config float                    Delay;               // How long to wait before starting this sound
var protected config float                    Pan;                 
var protected config Range                    PitchRange;          // The pitch will be randomly selected from this range, and on top of the Pitch
var protected config Range                    PanRange;            // The pan will be randomly selected from this range

// Looping controls...
// MonoLoop:
// Loops the schema. The n n is a range of delay (in seconds) between loops. The amount of delay is randomly 
// chosen within the range each time the schema loops. The delay is from the END of the first sound to the 
// BEGINNING of the next sound.If n n is set to 0 0, the sound is cached so that is can loop seamlessly. In 
// this case if multiple sounds are listed, the first sound is chosen is looped and the other sounds will not 
// play... until the schema is triggered again.
var protected config Range                    Monoloop;            // Explanation above             

// PolyLoops:
// Also loops the schema. The difference is that multiple sounds can play at a time. The n n is a range of 
// delay (in seconds) from the BEGINNING of the first sound to the BEGINNING of the next sound. This means that 
// the sounds will overlap if the delay is shorter than the length of the first sound.The m is a max limit of 
// sounds that can play at a time. Any sounds played over this limit will cut off the oldest playing sound.
struct native PolyLoopStruct                                       // This struct encapsulates a PolyLoop
{
    var config Range PolyLoopRange;
    var config int   LoopSoundLimit;
};
var protected config PolyLoopStruct           Polyloop;            // Explanation above

var protected config int                      LoopCount;           // The amount of times this sound should loop

var protected config float                    AISoundRadius;
var protected config Name                     SoundCategory;  
var protected config bool                     Local;               // If true this sound will not have any 2d panning
var protected config bool                     NoRepeat;            // This schema will never play the same sound twice in a row
var protected config bool                     NeverRepeat;         // This schema will play all of its sounds before repeating any of them
var protected config bool                     PlayOnce;            // Schema only plays once 
var protected config bool                     Retriggerable;      // If true, this specification will not restart if it tries to play again on the same actor 
var protected config float                    FadeInTime;          // When played, this sound's volume will attenuate to full volume over this time (counting in distance attenuation)
var protected config float                    FadeOutTime;         // When stopped, this sound's volume will attenuate to 0 volume over this time, and will be fully unregistered at the end of the FadeOutTime

// Monophonic sounds
// If Monophonic is set to be more than 0, it is considered to be in a group with all the other schemas in the file with 
// the same monophonic number.Only one monophonic sound from a group can be played at a time by a particluar object. 
// When a new monophonic sound from the same group is played, it will cut off the old one.
var protected config int                      Monophonic;           // Explanation above
// MonophonicPriority: Used as part of the monophonic system, if a new sound is played on a Monophonic set it will play only if the 
// MonophonicPriority is higher than or equal to the currently playing one.  
var protected config int                      MonophonicPriority;   // Explanation above
// If MonophonicToClass is set and this schema has a monophonic setting, then monophonic checks will be done per class, instead of per-instance
var protected config bool                     MonophonicToClass;
var protected config int                      Priority;             // The priority this sound will play at

#if IG_CAPTIONS
var protected config localized string         Caption;
var protected config name                     Speaker;
#endif

// ============================================================================
// Variables initialized based on the data above
// ============================================================================
// Query variables
var protected bool                            IsPitchRange;         // True if pitchrange is valid
var protected bool                            IsPanRange;           // True if panrange is valid


var protected bool                            IsMonoloop;           // True if a monoloop
var protected bool                            IsPolyloop;           // True if a polyloop

var protected bool                            IsSeamlessLoop;       // True if seamlessloop
var protected bool                            IsEndPredictable;     // True if end can be predicted (non-looping sounds, or sounds that loop without a random delay)

// Private variables
var protected bool                            Killable;             // True if sound can be killed (non-looping sounds)
var protected Range                           LoopDelayRange;       // Gotten from a valid monoloop or polyloop data
var protected int                             LoopSoundLimit;       // Same as above
var protected int                             NativeFlags;          // Flags which the sound will be played with
var protected array<SoundSet>                 SoundSets;            // Dynamic array of sets of sounds grouped by flag that will be randomly played

var private   bool                            IsFullyInitialized;   // True if this SoundEffectSpecification has been fully loaded.  This will be used to allow lazy loading of sounds that this spec references

// NativeInit gets called from the script call to Init() from the EffectsSubsystem
native private final function NativeInitialize(SoundEffectsSubsystem SoundEffectsSubsystem);

// Constructs a sound instance based on the random data listed above.
// Optionally constructed with a sepcific sound.
native final function bool ConstructSoundInstance(SoundInstance inInstance, int inTextureFlags, Actor inSource, bool inGameStarted, Vector inWorldLocation, optional int SpecificSoundRef);

// True if this sound loops at all, whether a polyloop, a monoloop, or a seamlessloop
native final function bool WantsToLoop();

// These hook events are called on subclasses to handle any subclass-specific code.  They can happen anywhere, but 
// can be thought of as happening after the data-initialization in each function
simulated protected event SetNativeFlagsHook();
simulated protected event InitHook();
simulated protected event PopulateSoundsHook();
simulated final native function SoundRef PickSoundToPlay( int inTextureFlags, optional int SpecificSoundRef );

// Called by the EffectsSubsystem to initalize this specificiation.
simulated function Init (EffectsSubsystem inSubsystem)
{
    NativeInitialize(SoundEffectsSubsystem(inSubsystem));
}


// String tokenizer function
// Removes the first part of the source string up to the first delimiter string
// and returns it.
simulated function string ExtractToken (out string ioSourceString, string inDelimiter)
{
    local string strToken; 
    local int iOffset;

    if (Len(ioSourceString) == 0)
        Warn("[SOUND]: WARNING: Ran out of tokens!");

    // Look for the delimiter (denoting the end of the token)
    iOffset = InStr (ioSourceString, inDelimiter);
    if (iOffset != -1)
    {
        // Extract the token
        strToken = Left (ioSourceString, iOffset);
        ioSourceString = Mid (ioSourceString, iOffset + Len(inDelimiter));
    }
    else
    {
        // No delimiter was found, the source string IS the token
        strToken = ioSourceString;
        ioSourceString = "";
    }

    return strToken;
}

// Converts this specification to a string, based on the specification's name
simulated function String toString() 
{
    return "{Name=\""$Name$"}";
}

function float GetOuterRadius()
{
    return OuterRadius;
}

function bool IsLocal()
{
    return Local;
}

#if IG_SWAT //dkaplan: accessors to specification information needed without an instance being created
function int GetNativeFlags()
{
    return NativeFlags;
}

function float GetAISoundRadius()
{
    return AISoundRadius;
}

function Name GetSoundCategory()
{
    return SoundCategory;
}
#endif

// Native c++ .h interface
cpptext
{
    ULevel*         GetLevel();
    void            ParseVariables();
    void            SetNativeFlags();
    void            PopulateSoundSets();
    class USoundRef* PickSoundToPlay(INT inTextureFlags, INT SpecificSoundRef=-1);
    void            HandleLazyInitialization();
    void            HandleLoopingSoundInstance(ASoundInstance* inInstance, FLOAT inCurrentTime);
    void            HandleStartTimeSoundInstance(ASoundInstance* inInstance, FLOAT inCurrentTime, UBOOL inGameStarted);
    void            HandleEndTimeSoundInstance(ASoundInstance* inInstance, FLOAT inCurrentTime);
    void            UpdateHistory(USoundRef* inSoundJustPlayed, INT inTextureFlags);
    USoundSet*      GetAppropriateSoundSet(INT inTextureFlags);
    UBOOL           WantsToLoop();
}

defaultproperties
{
    SampleRate=24000
    OuterRadius=3000.0
    InnerRadius=0.0
    Volume=100.0
    Pitch=1.0
    Priority=1
    Killable=true
    // Default MonophonicPriority to 2 as a happy median so Eric can make sounds with a lower and higher priority without
    // having to change every sound
    MonophonicPriority=2
    Retriggerable=true
    VolumeCategory=VOL_Voice
}
