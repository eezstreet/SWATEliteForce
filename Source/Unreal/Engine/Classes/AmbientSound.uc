class AmbientSound extends Keypoint;

#if IG_SWAT // ckline: tribes does this differently
simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    RegisterNotifyGameStarted();
}

simulated function OnGameStarted()
{
    TriggerEffectEvent('Started');
}
#endif

defaultproperties
{
    RemoteRole=ROLE_None
//#if IG_SHARED // carlos: allow spawned/alive events to play on MP clients
    bStatic=false
    bNoDelete=true
//#endif
}
