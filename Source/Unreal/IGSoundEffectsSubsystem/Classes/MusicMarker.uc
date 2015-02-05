class MusicMarker extends SoundMarkerBase
    placeable;
    
var() name MusicContext "This context will be set as the current MusicContext in the sound system.  Note: MusicContext's are mutually exclusive.";

simulated function PlayEffects()
{
    SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).SetMusicContext(MusicContext);
    SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).LastMusicMarker = Self;
    TriggerEffectEvent( 'MusicMarkerTriggered' );
}