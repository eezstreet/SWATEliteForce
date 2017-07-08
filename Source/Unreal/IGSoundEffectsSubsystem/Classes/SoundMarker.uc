class SoundMarker extends SoundMarkerBase
    native
    placeable;

/*=============================================================================
A SoundMarker is an area defined by a radius around a point that causes sounds to
be played when the Player enters it. If the sound is already being played by ANY OTHER
SoundMarker (or SoundVolume) it will be ignored. In this way, all the SoundMarkers in
the level sort of act as a single object.

Functions:

 event  Touch (Actor Other)     - Plays its sound schemas
==============================================================================*/

var() string    Schema1;
var() string    Schema2;


simulated function PlayEffects()
{
    SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).PlayMarkerSounds(self, Schema1, Schema2);
}

