class SoundRef extends Core.Object
	abstract
    native;

// ============================================================================
// SoundRef
//  
// A soundref object is a simple wrapper for the low level engine specifics
// of playing a sound or a stream.  This is the abstract base class.  There is 
// also a StreamSoundRef and a NormalSoundRef, which are wrappers for streaming 
// sounds and normal unreal usound objects respectively.  This class is used 
// across multiple classes and specifically helps decouple SoundSets, SoundSpecifications,
// and SoundInstances.
//
// This abstract base class is mainly for the shared C++ code between the subclasses
// as can be seen in cpptext.
// ============================================================================

// UGLY!! Index into the SoundSet which owns this SoundRef
var int SoundSetIndex;

// Simple equality, base classes can override 
simulated function bool Equals (SoundRef inOtherRef)
{
	return (self == inOtherRef);
}

simulated event string toString();

cpptext
{
    // These can't be abstract virtual functions because unreal instantiates a uobject in 
    // a declare class macro.  I could make this class noexport and use DECLARE_ABSTRACT_CLASS
    // but that's a major pain in the ass.
    // TODO: Make these functions either static or truely immutable...
    virtual INT Play(ASoundInstance* inInstance)   { check(false); return 0; }
    virtual void Stop(ASoundInstance* inInstance)   { check(false); }
    virtual void Mute(ASoundInstance* inInstance)   { check(false); }
    virtual void UnMute(ASoundInstance* inInstance) { check(false); }

    virtual void SetPitch(ASoundInstance* inInstance, FLOAT inPitch) { check(false); }
    virtual void SetVolume(ASoundInstance* inInstance, FLOAT inVolume) { check(false); }
    
    virtual FLOAT GetDuration(ASoundInstance* inInstance) { check(false); return 0.0f; }

    // TODO: make the uscrip Equals call the c++ Equals...
    virtual UBOOL Equals(class USoundRef* inOther)
    {
        return this == inOther;
    }
}
