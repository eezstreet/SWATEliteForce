//=============================================================================
// DemoRecSpectator - spectator for demo recordings to replicate ClientMessages
//=============================================================================

class DemoRecSpectator extends PlayerController;

var bool bTempBehindView;
var bool bFoundPlayer;

event PostBeginPlay()
{
	local class<HUD> HudClass;
	local class<Scoreboard> ScoreboardClass;

	// We're currently doing demo recording
	if( Role == ROLE_Authority && Level.Game != None )
	{
		HudClass = class<HUD>(DynamicLoadObject(Level.Game.HUDType, class'Class'));
		if( HudClass == None )
			log( "Can't find HUD class "$Level.Game.HUDType, 'Error' );
        ScoreboardClass = class<Scoreboard>(DynamicLoadObject(Level.Game.ScoreBoardType, class'Class'));
		if( ScoreboardClass == None )
			log( "Can't find HUD class "$Level.Game.ScoreBoardType, 'Error' );
		ClientSetHUD( HudClass, ScoreboardClass );
	}

	Super.PostBeginPlay();
	
	if ( PlayerReplicationInfo != None )
		PlayerReplicationInfo.bOutOfLives = true;
}

function InitPlayerReplicationInfo()
{
	Super.InitPlayerReplicationInfo();
	PlayerReplicationInfo.PlayerName="DemoRecSpectator";
	PlayerReplicationInfo.bIsSpectator = true;
	PlayerReplicationInfo.bOnlySpectator = true;
	PlayerReplicationInfo.bOutOfLives = true;
	PlayerReplicationInfo.bWaitingPlayer = false;
}

exec function ViewClass( class<actor> aClass, optional bool bQuiet, optional bool bCheat )
{
	local actor other, first;
	local bool bFound;

	first = None;

	ForEach AllActors( aClass, other )
	{
		if ( bFound || (first == None) )
		{
			first = other;
			if ( bFound )
				break;
		}
		if ( other == ViewTarget ) 
			bFound = true;
	}  

	if ( first != None )
	{
		SetViewTarget(first);
		bBehindView = ( ViewTarget != self );

		if ( bBehindView )
			ViewTarget.BecomeViewTarget();
	}
	else
		SetViewTarget(self);
}

//==== Called during demo playback ============================================

exec function DemoViewNextPlayer()
{
    local Controller C, Pick;
    local bool bFound;

    // view next player
    if ( PlayerController(RealViewTarget) != None )
		PlayerController(RealViewTarget).DemoViewer = None;

	foreach DynamicActors(class'Controller', C)
		if ( (C == self) || (PlayerController(C) == None) || !PlayerController(C).IsSpectating() )
		{
			if ( (GameReplicationInfo == None) && (PlayerController(C) != None) )
				GameReplicationInfo = PlayerController(C).GameReplicationInfo;
			if ( Pick == None )
				Pick = C;
			if ( bFound )
			{
				Pick = C;
				break;
			}
			else
				bFound = ( (RealViewTarget == C) || (ViewTarget == C) );
		}
    
    SetViewTarget(Pick);
    if ( PlayerController(RealViewTarget) != None )
		PlayerController(RealViewTarget).DemoViewer = self;
}

auto state Spectating
{
    exec function Fire()
    {
        bBehindView = false;
        demoViewNextPlayer();
    }

	event PlayerTick( float DeltaTime )
	{
		Super.PlayerTick( DeltaTime );

		// attempt to find a player to view.
		if( Role == ROLE_AutonomousProxy && (RealViewTarget==None || RealViewTarget==Self) && !bFoundPlayer )
		{
			DemoViewNextPlayer();
			if( RealViewTarget!=None && RealViewTarget!=Self ) 
				bFoundPlayer = true;		
		}
			
		// hack to go to 3rd person during deaths
		if( RealViewTarget!=None && RealViewTarget.Pawn==None )
		{
			if( !bTempBehindView )
			{
				bTempBehindView = true;
				bBehindView = true;
			}
		}
		else
		if( bTempBehindView )
		{
			bBehindView = false;
			bTempBehindView = false;
		}
	}   
}

event PlayerCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
{
	local Rotator R;
	
	if( RealViewTarget != None )
	{
		R = RealViewTarget.Rotation;
	}
	
	Super.PlayerCalcView(ViewActor, CameraLocation, CameraRotation );
	
	if( RealViewTarget != None )
	{
		if ( !bBehindView )
		{
			CameraRotation = R;
			if ( Pawn(ViewTarget) != None )
				CameraLocation.Z += Pawn(ViewTarget).BaseEyeHeight; // FIXME TEMP
		}
		RealViewTarget.SetRotation(R);
	}
}

defaultproperties
{
	RemoteRole=ROLE_AutonomousProxy
	bDemoOwner=1
}

