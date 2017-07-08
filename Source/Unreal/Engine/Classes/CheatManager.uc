//=============================================================================
// CheatManager
// Object within playercontroller that manages "cheat" commands
// only spawned in single player mode
//=============================================================================

class CheatManager extends Core.Object within PlayerController
	native;

var rotator LockedRotation;
var private localized string LookingAtString;
 
/* Used for correlating game situation with log file
*/

exec function ReviewJumpSpots(name TestLabel)
{	
	if ( TestLabel == 'Transloc' )
		TestLabel = 'Begin';
	else if ( TestLabel == 'Jump' )
		TestLabel = 'Finished';
	else if ( TestLabel == 'Combo' )
		TestLabel = 'FinishedJumping';
	else if ( TestLabel == 'LowGrav' )
		TestLabel = 'FinishedComboJumping';
	log("TestLabel is "$TestLabel);
	Level.Game.ReviewJumpSpots(TestLabel);
}

exec function ListDynamicActors()
{
	local Actor A;
	local int i;
	
	ForEach DynamicActors(class'Actor',A)
	{
		i++;
		log(i@A);
	}
	log("Num dynamic actors: "$i);
}

// ckline note: this causes the game to go into pause mode after Delay seconds have elapsed
exec function FreezeFrame(float Delay)
{
	Level.Game.SetPause(true,outer);
	Level.PauseDelay = Level.TimeSeconds + Delay;
}

exec function WriteToLog()
{
	log("NOW!");
}

exec function SetFlash(float F)
{
	FlashScale.X = F;
}

exec function SetFogR(float F)
{
	FlashFog.X = F;
}

exec function SetFogG(float F)
{
	FlashFog.Y = F;
}

exec function SetFogB(float F)
{
	FlashFog.Z = F;
}

exec function KillViewedActor()
{
	if ( ViewTarget != None )
	{
		if ( (Pawn(ViewTarget) != None) && (Pawn(ViewTarget).Controller != None) )
			Pawn(ViewTarget).Controller.Destroy();	
		ViewTarget.Destroy();
		SetViewTarget(None);
	}
}

/* LogScriptedSequences()
Toggles logging of scripted sequences on and off
*/
exec function LogScriptedSequences()
{
#if !IG_SWAT // we don't support AIScript
	local AIScript S;

	ForEach AllActors(class'AIScript',S)
		S.bLoggingEnabled = !S.bLoggingEnabled;
#endif
}

/* Teleport()
Teleport to surface player is looking at
*/
exec function Teleport()
{
	local actor HitActor;
	local vector HitNormal, HitLocation;

	HitActor = Trace(HitLocation, HitNormal, ViewTarget.Location + 10000 * vector(Rotation),ViewTarget.Location, true);
	if ( HitActor == None )
		HitLocation = ViewTarget.Location + 10000 * vector(Rotation);
	else
		HitLocation = HitLocation + ViewTarget.CollisionRadius * HitNormal;

	ViewTarget.SetLocation(HitLocation);
}

/* 
Scale the player's size to be F * default size
*/
exec function ChangeSize( float F )
{
	if ( Pawn.SetCollisionSize(Pawn.Default.CollisionRadius * F,Pawn.Default.CollisionHeight * F) )
	{
		Pawn.SetDrawScale(F);
		Pawn.SetLocation(Pawn.Location);
	}
}

exec function LockCamera()
{
	local vector LockedLocation;
	local rotator LockedRot;
	local actor LockedActor;

	if ( !bCameraPositionLocked )
	{
		PlayerCalcView(LockedActor,LockedLocation,LockedRot);
		Outer.SetLocation(LockedLocation);
		LockedRotation = LockedRot;
		SetViewTarget(outer);
	}
	else
		SetViewTarget(Pawn);

	bCameraPositionLocked = !bCameraPositionLocked;
	bBehindView = bCameraPositionLocked;
	bFreeCamera = false;
}

exec function SetCameraDist( float F )
{
	CameraDist = FMax(F,2);
}

/* Stop interpolation
*/
exec function EndPath()
{
}

/* 
Camera and pawn aren't rotated together in behindview when bFreeCamera is true
*/
exec function FreeCamera( bool B )
{
	bFreeCamera = B;
	bBehindView = B;
}


exec function CauseEvent( name EventName )
{
	TriggerEvent( EventName, Pawn, Pawn);
}
	
exec function Fly()
{
	if ( Pawn == None )
		return;
	ClientMessage("You feel much lighter");
	Pawn.SetCollision(true, true , true);
	Pawn.bCollideWorld = true;
	bCheatFlying = true;
	Outer.GotoState('PlayerFlying');
}

exec function Walk()
{	
	if ( Pawn != None )
	{
		bCheatFlying = false;
		Pawn.SetCollision(true, true , true);
		Pawn.SetPhysics(PHYS_Walking);
		Pawn.bCollideWorld = true;
		ClientReStart();
	}
}

exec function Ghost()
{
	if( Pawn != None && !Pawn.IsA('Vehicle') )
	{
		ClientMessage("You feel ethereal");
		Pawn.SetCollision(false, false, false);
		Pawn.bCollideWorld = false;
		bCheatFlying = true;
		Outer.GotoState('PlayerFlying');
	}
	else
		Log("Can't Ghost In Vehicles");
}
	

exec function Invisible(bool B)
{
	Pawn.bHidden = B;

	if (B)
		Pawn.Visibility = 0;
	else
		Pawn.Visibility = Pawn.Default.Visibility;
}
	
exec function God()
{
#if IG_SWAT
    // Clients should never be able to set god mode
    if (Level.NetMode == NM_Client)
        return;

    // In network games, only a co-op server can tweak god-mode
    if (Level.NetMode != NM_Standalone)
    {
        if (Level.IsCOOPServer)
        {
            ToggleGodModeForCoopPlayers();
        }

        return;
    }
#endif

	if ( bGodMode )
	{
		bGodMode = false;
		ClientMessage("God mode off");
		return;
	}

	bGodMode = true; 
	ClientMessage("God Mode on");
}

#if IG_SWAT
function ToggleGodModeForCoopPlayers()
{
    local Controller Controller;
    local PlayerController PlayerController;

    // Toggle server player controller's god mode. Make sure every player has
    // the same god setting.
    bGodMode = !bGodMode;
	if (bGodMode)
	    ClientMessage("God mode on");
    else
	    ClientMessage("God mode off");

    for (Controller = Level.ControllerList; Controller != None; Controller = Controller.NextController)
    {
        // Tweak god mode only for player controllers, not AIs
        PlayerController = PlayerController(Controller);
        if (PlayerController != None)
        {
            PlayerController.bGodMode = bGodMode;
        }
    }
}
#endif


exec function SloMo( float T )
{
	Level.Game.SetGameSpeed(T);
//TMC don't save SloMo.  It would save to output/{configuration}/SwatGame.ini, so you wouldn't use updates made to content/system/SwatGame.ini.
//	Level.Game.SaveConfig(); 
//	Level.Game.GameReplicationInfo.SaveConfig();
}

exec function SetJumpZ( float F )
{
	Pawn.JumpZ = F;
}

exec function SetGravity( float F )
{
	PhysicsVolume.Gravity.Z = F;
}

exec function SetSpeed( float F )
{
	Pawn.GroundSpeed = Pawn.Default.GroundSpeed * f;
	Pawn.WaterSpeed = Pawn.Default.WaterSpeed * f;
}

exec function KillAll(class<actor> aClass)
{
	local Actor A;

#if !IG_SWAT // ckline: we don't support AIScript
	if ( ClassIsChildOf(aClass, class'AIController') )
	{
		Level.Game.KillBots(Level.Game.NumBots);
		return;
	}
#endif
	if ( ClassIsChildOf(aClass, class'Pawn') )
	{
		KillAllPawns(class<Pawn>(aClass));
		return;
	}
	ForEach DynamicActors(class 'Actor', A)
		if ( ClassIsChildOf(A.class, aClass) )
        {
            Log("KillAll("$aClass.Name$") destroying "$A);
            A.Destroy();
        }
}

// Kill non-player pawns and their controllers
function KillAllPawns(class<Pawn> aClass)
{
	local Pawn P;
	
	Level.Game.KillBots(Level.Game.NumBots);
	ForEach DynamicActors(class'Pawn', P)
		if ( ClassIsChildOf(P.Class, aClass)
			&& !P.IsPlayerPawn() )
		{
            P.TakeDamage(10000, None, vect(0,0,0), vect(0,0,0), class'DamageType');
		}
}

exec function KillPawns()
{
	KillAllPawns(class'Pawn');
}

/* Avatar()
Possess a pawn of the requested class
*/
exec function Avatar( string ClassName )
{
	local class<actor> NewClass;
	local Pawn P;
		
	NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class' ) );
	if( NewClass!=None )
	{
		Foreach DynamicActors(class'Pawn',P)
		{
			if ( (P.Class == NewClass) && (P != Pawn) )
			{
				if ( Pawn.Controller != None )
					Pawn.Controller.PawnDied(Pawn);
				Possess(P);
				break;
			}
		}
	}
}

exec function Summon( string ClassName )
{
	local class<actor> NewClass;
	local vector SpawnLoc;

	log( "Fabricate " $ ClassName );
	NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class' ) );
	if( NewClass!=None )
	{
		if ( Pawn != None )
			SpawnLoc = Pawn.Location;
		else
			SpawnLoc = Location;
		Spawn( NewClass,,,SpawnLoc + 72 * Vector(Rotation) + vect(0,0,1) * 15 );
	}
}

exec function PlayersOnly()
{
	Level.bPlayersOnly = !Level.bPlayersOnly;
}

exec function CheatView( class<actor> aClass, optional bool bQuiet )
{
	ViewClass(aClass,bQuiet,true);
}

// ***********************************************************
// Navigation Aids (for testing)

// remember spot for path testing (display path using ShowDebug)
exec function RememberSpot()
{
	if ( Pawn != None )
		Destination = Pawn.Location;
	else
		Destination = Location;
}

// ***********************************************************
// Changing viewtarget

exec function ViewSelf(optional bool bQuiet)
{
	bBehindView = false;
	bViewBot = false;
	if ( Pawn != None )
		SetViewTarget(Pawn);
	else
		SetViewtarget(outer);
	if (!bQuiet )
		ClientMessage(OwnCamera, 'DebugMessage');
	FixFOV();
}

exec function ViewPlayer( string S )
{
	local Controller P;

	for ( P=Level.ControllerList; P!=None; P= P.NextController )
		if ( P.bIsPlayer && (P.PlayerReplicationInfo.PlayerName ~= S) )
			break;

	if ( P.Pawn != None )
	{
		ClientMessage(LookingAtString@P.PlayerReplicationInfo.PlayerName, 'DebugMessage');
		SetViewTarget(P.Pawn);
	}

	bBehindView = ( ViewTarget != Pawn );
	if ( bBehindView )
		ViewTarget.BecomeViewTarget();
}

exec function ViewActor( name ActorName)
{
	local Actor A;

	ForEach AllActors(class'Actor', A)
		if ( A.Name == ActorName )
		{
			SetViewTarget(A);
			bBehindView = true;
			return;
		}
}

#if !IG_SWAT // ckline: we don't support this
exec function ViewFlag()
{
	local Controller C;

	For ( C=Level.ControllerList; C!=None; C=C.NextController )
		if ( C.IsA('AIController') && (C.PlayerReplicationInfo != None) && (C.PlayerReplicationInfo.HasFlag != None) )
		{
			SetViewTarget(C.Pawn);
			return;
		}
}
#endif		

exec function ViewBot()
{
	local actor first;
	local bool bFound;
	local Controller C;

	bViewBot = true;
	For ( C=Level.ControllerList; C!=None; C=C.NextController )
		if ( C.IsA('AIController') && (C.Pawn != None) )
	{
		if ( bFound || (first == None) )
		{
			first = C.Pawn;
			if ( bFound )
				break;
		}
		if ( C.Pawn == ViewTarget ) 
			bFound = true;
	}  

	if ( first != None )
	{
		SetViewTarget(first);
		bBehindView = true;
		ViewTarget.BecomeViewTarget();
		FixFOV();
	}
	else
		ViewSelf(true);
}

exec function ViewClass( class<actor> aClass, optional bool bQuiet, optional bool bCheat )
{
	local actor other, first;
	local bool bFound;

	if ( !bCheat && (Level.Game != None) && !Level.Game.bCanViewOthers )
		return;

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
		if ( !bQuiet )
		{
			if ( Pawn(first) != None )
				ClientMessage(LookingAtString@First.GetHumanReadableName(), 'DebugMessage');
			else
				ClientMessage(LookingAtString@first, 'DebugMessage');
		}
		SetViewTarget(first);
		bBehindView = ( ViewTarget != outer );

		if ( bBehindView )
			ViewTarget.BecomeViewTarget();

		FixFOV();
	}
	else
		ViewSelf(bQuiet);
}


#if IG_MOJO // rowan:
exec function Cutscene(name cutsceneName)
{
	Level.PlayMojoCutscene(cutsceneName);
}
#endif

#if IG_SHARED // henry: visualize shadow volumes
// Toggle debugging shadow projector volume rendering
exec function DebugShadowProjectors()
{
	local ShadowProjector SP;

	log("Toggling Shadow volume debugging");
	ForEach AllActors(class'ShadowProjector',SP)
	{
		SP.bDebugShadow = !SP.bDebugShadow;
	}
}

// Moves the near clip plane for the ShadowProjectors towards the virtual light source.
// Use this command with the "Show ProjectorBounds" cheat to see the effect of the near
// clip moving.
exec function SetShadowProjectorClipShift(float ShiftAmount)
{
	local ShadowProjector SP;

	log("Setting Shadow volume NearClip position shift");
	ForEach AllActors(class'ShadowProjector',SP)
	{
		SP.bShiftNearClip      = True;
		SP.NearClipShiftAmount = ShiftAmount;
	}
}

#endif

#if !IG_THIS_IS_SHIPPING_VERSION // testing speedhack cheat [crombie]
// doesn't currently work, looking to david beswick to find a reason why
exec function debugSpeedhack()
{
	Outer.bDebugSpeedhack = !Outer.bDebugSpeedhack;
	ClientMessage(Outer.bDebugSpeedhack);
}
#endif

defaultproperties
{
	LookingAtString="Now viewing: "
}
