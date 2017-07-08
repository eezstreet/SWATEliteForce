class NormalSoundEffectSpecification extends SoundEffectSpecification
    config(SoundEffects)
    PerObjectConfig
    native;

// ============================================================================
// NormalSoundEffectSpecification
//  
// A NormalSoundEffectSpecification is an SoundEffectSpecification that handles creation
// of normal unreal USound objects, and the data the sound designer needs to edit for their creation.
//
// ============================================================================

// FlaggedSound is a struct that encapsulates a USound with a flag the sound plays for.  The flag is 
// set to the sound designer's preference to match the flag that a material would have.  When a sound
// is requested to be played based on a material, the FlaggedSound with the matching flag will play.
// If set to 0, the sound will play if no other flagged sound matches material wise, or if no flag for
// the material will play.  
struct native FlaggedSound
{
    var config Sound SoundToPlay;
    var config int   Flag;
};
// As will all SoundEffectSpecifications, the sound is picked randomly from this list.
var config array<FlaggedSound> FlaggedSounds;

// This overriden hook function sets up the flags to be used for the engine call to PlaySound
simulated protected event SetNativeFlagsHook()
{
    local int i;
    if (IsSeamlessLoop)
    {
        NativeFlags += SF_Looping;

//        if (Outer.bDebugSounds)
//			Log("[SeamlessLoop] "$Self);
        // Set native looping on all samples
        for (i = 0; i < FlaggedSounds.Length; i++)
        {
            //Log(" - [SeamlessLoop] "$FlaggedSounds[i].SoundToPlay);
            if (FlaggedSounds[i].SoundToPlay != None)
                class'SoundEffectsSubsystem'.static.SetNativeLooping (Level, FlaggedSounds[i].SoundToPlay);
        }
    }
}

// Initialize hook...
simulated protected event InitHook()
{
    // Sanity checks
    if ((NoRepeat || NeverRepeat) && !(FlaggedSounds.Length > 1))
    {
      Log ("[SOUND] WARNING!: Schema <"$":"$name$"> has NoRepeat/NeverRepeat but only has 1 sound!");
        NoRepeat = false;
        NeverRepeat = false;
    }
}

// Add all the flagged sounds to the soundsets array from a normal SoundEffectSpecification.  Note, sounds are added
// to a soundset based on their flag, which is also their index into the soundsets array.
simulated protected event PopulateSoundsHook()
{
    local int i;
    local int iSetToInsert;
    local NormalSoundRef newNormalRef;

    if (FlaggedSounds.Length == 0)
    {
        assertWithDescription(false, "NormalSoundEffectSpecification "$Name$" has no FlaggedSounds specified. This will cause a crash if ignored.");
        assert(false);
    }

    for (i = 0; i < FlaggedSounds.Length; i++)
    {
        assertWithDescription(FlaggedSounds[i].SoundToPlay != None, "The sound at index "$i$" in SoundEffectSpecification '"$name$"' was not found.");

        iSetToInsert = FlaggedSounds[i].Flag;

        // Make sure the SoundSets array is long enough to at least hold the sounds for this flag 
        if ( SoundSets.Length <= iSetToInsert )
            SoundSets.Length = iSetToInsert + 1;

        // Create a new sound ref if necessary
        if ( SoundSets[iSetToInsert] == None ) 
            SoundSets[iSetToInsert] = new(self) class'SoundSet';

        newNormalRef = new(self) class'NormalSoundRef';
        newNormalRef.Sound = FlaggedSounds[i].SoundToPlay;

        SoundSets[iSetToInsert].AddSoundRef (newNormalRef);
    }
}
