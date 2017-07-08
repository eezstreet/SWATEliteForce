class NormalSoundRef extends SoundRef
    native;

// ============================================================================
// NormalSoundRef
//  
// A NormalSoundRef.  Encapsulates a normal usound object.  Handles the low
// level unreal call to play a sound, and also manages it's own usound object
// reference.
// ============================================================================

// Reference to the USound object this SoundRef refers to.
var Sound Sound;

// This is called from C++ so we can call the already established Actor::PlaySound function 
// which contains custom code for handling ai behavior and such.  There's no easy way to call
// a native function from C++ that takes parameters, and this allows us to have the best of 
// both worlds.  It's private so only a NormalSoundRef can call it anyways.
simulated private event INT PlayMySound(Soundinstance inInstance)
{
	if (Sound != None)
		return inInstance.Source.PlaySound( Sound, inInstance.Volume / 100.0, false, inInstance.InnerRadius, inInstance.OuterRadius, inInstance.Pitch, inInstance.NativeFlags, inInstance.FadeInTime, !inInstance.Local, inInstance.AISoundRadius, inInstance.SoundCategory);
	else
		return -1;	// return INVALID_SOUND_INDEX if we have no sound
}

simulated event string toString()
{
    return "NormalSoundRef playing USound: "$Sound;
}

cpptext
{
    virtual INT Play(ASoundInstance* inInstance);
    virtual void Stop(ASoundInstance* inInstance);

    virtual void Mute(ASoundInstance* inInstance);
    virtual void UnMute(ASoundInstance* inInstance);

    virtual FLOAT GetDuration(ASoundInstance* inInstance);

    virtual void SetPitch(ASoundInstance* inInstance, FLOAT inPitch);
    virtual void SetVolume(ASoundInstance* inInstance, FLOAT inVolume);
}

defaultproperties
{
}
