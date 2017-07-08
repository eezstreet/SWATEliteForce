class SoundMarkerBase extends Engine.Actor
    native
    abstract;

var private bool QueuedTillStartup;
var private bool GameStarted;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    RegisterNotifyGameStarted();

}

simulated function OnGameStarted()
{
    GameStarted = true;
    if ( QueuedTillStartup )
    {
        log( "Sound is queued and played in "$Self );
        PlayEffects();
    }
}

simulated event Touch (Actor Other)
{
	Super.Touch (Other);

	if (Other.IsA('Pawn') && Pawn(Other).IsPlayerPawn())
	{
        if ( GameStarted ) 
            PlayEffects();
        else
            QueuedTillStartup = true;
    }
}

simulated function PlayEffects();

defaultproperties
{
    Texture=texture'IGEffectsSystem_EditorTextures.SoundEffectsSubsystem.SoundMarker'
    bCollideActors=true
    bCollideWorld=false
    bBlockActors=false
    bBlockPlayers=false
    bBlockZeroExtentTraces=false
    bBlockNonZeroExtentTraces=true
    bBlockKarma=false
	bHidden=true
	bStasis=true
	DrawType=DT_Sprite
	Physics=PHYS_None
    RemoteRole=ROLE_None
    bNoDelete=true
    bAlwaysRelevant=true
}
