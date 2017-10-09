class DynamicMusicManager extends IGSoundEffectsSubsystem.DynamicMusicManagerBase
    implements  IInterested_GameEvent_GrenadeDetonated,
                IInterested_GameEvent_EnemyFiredWeapon,
                IInterested_GameEvent_C2Detonated
	config(SwatGame);

var Timer           DynamicMusicTimer;
var config float    DynamicMusicTime;
var config name     DynamicContextName;
var config name     MusicEffectEvent;

#define DEBUG_DYNAMIC_MUSIC 0

simulated function PostBeginPlay()
{
    local SwatGameInfo GameInfo;
    Super.PostBeginPlay();

    DynamicMusicTimer = Spawn(class'Timer');
    DynamicMusicTimer.TimerDelegate = DynamicMusicTimerTimeout;

    GameInfo = SwatGameInfo( Level.Game );

    if ( GameInfo != None && GameInfo.GameEvents != None )
    {
        GameInfo.GameEvents.GrenadeDetonated.Register(self);
		GameInfo.GameEvents.EnemyFiredWeapon.Register(self);
		GameInfo.GameEvents.C2Detonated.Register(self);
    }
}

function OnGrenadeDetonated( Pawn GrenadeOwner, SwatGrenadeProjectile Grenade )
{   
#if DEBUG_DYNAMIC_MUSIC
    log( "[DynamicMusicManager] On grenade detonated!" );
#endif
    if ( Level.NetMode == NM_Standalone )
        TriggerDynamicMusic();
    else
        SwatGameReplicationInfo(Level.GetGameReplicationInfo()).ServerTriggerDynamicMusic();
}

function OnEnemyFiredWeapon( Pawn Enemy, Actor Target )
{
    if ( Target.IsA( 'SwatPlayer' ) || Target.IsA( 'SwatOfficer' ) )
    {
#if DEBUG_DYNAMIC_MUSIC
        log ( "[DynamicMusicManager] EnemyFiredWeapon towards officer!" );
#endif
    if ( Level.NetMode == NM_Standalone )
        TriggerDynamicMusic();
    else
        SwatGameReplicationInfo(Level.GetGameReplicationInfo()).ServerTriggerDynamicMusic();
    }
}

function OnC2Detonated( Pawn C2Owner, DeployedC2ChargeBase C2 )
{   
#if DEBUG_DYNAMIC_MUSIC
    log( "[DynamicMusicManager] On C2 detonated!" );
#endif
    if ( Level.NetMode == NM_Standalone )
        TriggerDynamicMusic();
    else
        SwatGameReplicationInfo(Level.GetGameReplicationInfo()).ServerTriggerDynamicMusic();
}

simulated function TriggerDynamicMusic()
{
    local MusicMarker LastMusicMarker;
#if DEBUG_DYNAMIC_MUSIC
    log( "Trigger dynamicmusic!!!" );
#endif
    DynamicMusicTimer.StartTimer( DynamicMusicTime, false, true );
    Level.EffectsSystem.AddPersistentContext( DynamicContextName );
    
    LastMusicMarker = SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).LastMusicMarker;
    if ( LastMusicMarker != None )
        LastMusicmarker.TriggerEffectEvent( MusicEffectEvent );
    else
        TriggerEffectEvent(MusicEffectEvent);
}

simulated function DynamicMusicTimerTimeout()
{
    local MusicMarker LastMusicMarker;

#if DEBUG_DYNAMIC_MUSIC
    log( "[DynamicMusicManager] MusicTimer timed out!");
#endif
    LastMusicMarker = SoundEffectsSubsystem(EffectsSystem(Level.EffectsSystem).GetSubsystem('SoundEffectsSubsystem')).LastMusicMarker;

    
    if ( LastMusicMarker != None )
    {
        EffectsSystem(Level.EffectsSystem).RemovePersistentContext( DynamicContextName );
        LastMusicMarker.TriggerEffectEvent( MusicEffectEvent );
    } else
        UnTriggerEffectEvent( MusicEffectEvent );
}

simulated event Destroyed()
{
    local SwatGameInfo GameInfo;

    GameInfo = SwatGameInfo( Level.Game );

    if ( GameInfo != None && GameInfo.GameEvents != None )
    {
        GameInfo.GameEvents.GrenadeDetonated.UnRegister(self);
		GameInfo.GameEvents.EnemyFiredWeapon.UnRegister(self);
		GameInfo.GameEvents.C2Detonated.UnRegister(self);
    }

    if (DynamicMusicTimer != None)
    {
        DynamicMusicTimer.Destroy();
        DynamicMusicTimer = None;
    }

    Super.Destroyed();
}

defaultproperties
{
    DynamicMusicTime=5.0
    DynamicContextName=Dynamic
    MusicEffectEvent=GameStateMusic
}
