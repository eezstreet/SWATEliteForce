//=============================================================================
// Controller, the base class of players or AI.
//
// Controllers are non-physical actors that can be attached to a pawn to control
// its actions.  PlayerControllers are used by human players to control pawns, while
// AIControFllers implement the artificial intelligence for the pawns they control.
// Controllers take control of a pawn using their Possess() method, and relinquish
// control of the pawn by calling UnPossess().
//
// Controllers receive notifications for many of the events occuring for the Pawn they
// are controlling.  This gives the controller the opportunity to implement the behavior
// in response to this event, intercepting the event and superceding the Pawn's default
// behavior.
//
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class Controller extends Actor
	native
	nativereplication
    dependsOn(HandheldEquipment)
	abstract;

#if IG_SWAT
import enum EquipmentSlot from HandheldEquipment;
#endif

var Pawn Pawn;

var const int		PlayerNum;			// The player number - per-match player number.
var		float		SightCounter;		// Used to keep track of when to check player visibility
var		float		FovAngle;			// X field of view angle in degrees, usually 90.
var globalconfig float	Handedness;
var		bool        bIsPlayer;			// Pawn is a player or a player-bot.
var		bool		bGodMode;			// cheat - when true, can't be killed or hurt

//AI flags
var const bool		bLOSflag;			// used for alternating LineOfSight traces
var		bool		bAdvancedTactics;	// serpentine movement between pathnodes
var		bool		bCanOpenDoors;
var		bool		bCanDoSpecial;
var		bool		bAdjusting;			// adjusting around obstacle
var		bool		bPreparingMove;		// set true while pawn sets up for a latent move
var		bool		bControlAnimations;	// take control of animations from pawn (don't let pawn play animations based on notifications)
var		bool		bEnemyInfoValid;	// false when change enemy, true when LastSeenPos etc updated
var		bool		bNotifyApex;		// event NotifyJumpApex() when at apex of jump
var		bool		bUsePlayerHearing;
var		bool		bJumpOverWall;		// true when jumping to clear obstacle
var		bool		bEnemyAcquired;
var		bool		bSoaking;			// pause and focus on this bot if it encounters a problem
var		bool		bHuntPlayer;		// hunting player
var		bool		bAllowedToTranslocate;
var		bool		bAllowedToImpactJump;

// Input buttons.
var input byte
#if IG_SWAT
    bLeanLeft, bLeanRight, bHoldCommand,
#endif
	bRun, bDuck, bFire, bAltFire, bVoiceTalk;

var		vector		AdjustLoc;			// location to move to while adjusting around obstacle

var const Controller	nextController; // chained Controller list

var		float 		Stimulus;			// Strength of stimulus - Set when stimulus happens

// Navigation AI
var 	float		MoveTimer;
var 	Actor		MoveTarget;		// actor being moved toward
var		vector	 	Destination;	// location being moved toward
var	 	vector		FocalPoint;		// location being looked at
var		Actor		Focus;			// actor being looked at
var		Mover		PendingMover;	// mover pawn is waiting for to complete its move
var		Actor		GoalList[4];	// used by navigation AI - list of intermediate goals
var NavigationPoint home;			// set when begin play, used for retreating and attitude checks
var	 	float		MinHitWall;		// Minimum HitNormal dot Velocity.Normal to get a HitWall event from the physics
var		float		RespawnPredictionTime;	// how far ahead to predict respawns when looking for inventory
var		int			AcquisitionYawRate;

// Enemy information
var	 	Pawn    	Enemy;
var		Actor		Target;
var		vector		LastSeenPos; 	// enemy position when I last saw enemy (auto updated if EnemyNotVisible() enabled)
var		vector		LastSeeingPos;	// position where I last saw enemy (auto updated if EnemyNotVisible enabled)
var		float		LastSeenTime;

var string	VoiceType;			// for speech
var float	OldMessageTime;		// to limit frequency of voice messages

// Route Cache for Navigation
var Actor		RouteCache[16];
var ReachSpec	CurrentPath;
var vector		CurrentPathDir;
var Actor		RouteGoal;			//final destination (ACTOR) for current route
var float		RouteDist;	// total distance for current route
var	float		LastRouteFind;	// time at which last route finding occured

#if IG_SWAT
var bool		bNearbyPathFound;	// we found a nearby path
var vector		RouteGoalPoint;		// final destination (LOCATION) for current route
#endif

// Replication Info
var() class<PlayerReplicationInfo> PlayerReplicationInfoClass;
var PlayerReplicationInfo PlayerReplicationInfo;

var class<Pawn> PawnClass;			// class of pawn to spawn (for players)
var class<Pawn> PreviousPawnClass;	// Holds the player's previous class

var float GroundPitchTime;
var vector ViewX, ViewY, ViewZ;	// Viewrotation encoding for PHYS_Spider

var NavigationPoint StartSpot;  // where player started the match

// for monitoring the position of a pawn
var		vector		MonitorStartLoc;	// used by latent function MonitorPawn()
var		Pawn		MonitoredPawn;		// used by latent function MonitorPawn()
var		float		MonitorMaxDistSq;

var const Actor LastFailedReach;	// cache to avoid trying failed actorreachable more than once per frame
var const float FailedReachTime;
var const vector FailedReachLocation;

//TMC removed Epic's Weapon or Inventory code here - var Weapon LastPawnWeapon

const LATENT_MOVETOWARD = 503; // LatentAction number for Movetoward() latent function

replication
{
	reliable if( bNetDirty && (Role==ROLE_Authority) )
		PlayerReplicationInfo, Pawn;
	reliable if( bNetDirty && (Role== ROLE_Authority) && bNetOwner )
		PawnClass;

	// Functions the server calls on the client side.
	reliable if( RemoteRole==ROLE_AutonomousProxy )
		ClientGameEnded, ClientDying, ClientSetRotation, ClientSetLocation;
		//TMC removed ClientSwitchToBestWeapon, ClientSetWeapon;
	reliable if ( (!bDemoRecording || (bClientDemoRecording && bClientDemoNetFunc)) && Role == ROLE_Authority )
		ClientVoiceMessage;
	reliable if(Role==ROLE_Authority)
		ClientOnTargetUsed;

	// Functions the client calls on the server.
	unreliable if( Role<ROLE_Authority )
		SendVoiceMessage, SetPawnClass, ServerRequestInteract;
	reliable if ( Role < ROLE_Authority )
		ServerRestartPlayer;
}

native(508) final latent function FinishRotation();

// native AI functions
/* LineOfSightTo() returns true if any of several points of Other is visible
  (origin, top, bottom)
*/
native(514) final function bool LineOfSightTo(actor Other);

/* CanSee() similar to line of sight, but also takes into account Pawn's peripheral vision
*/
native(533) final function bool CanSee(Pawn Other);

native(523) final function vector EAdjustJump(float BaseZ, float XYSpeed);

/* PickWallAdjust()
Check if could jump up over obstruction (only if there is a knee height obstruction)
If so, start jump, and return current destination
Else, try to step around - return a destination 90 degrees right or left depending on traces
out and floor checks
*/
native(526) final function bool PickWallAdjust(vector HitNormal);

/* WaitForLanding()
latent function returns when pawn is on ground (no longer falling)
*/
native(527) final latent function WaitForLanding();

native(529) final function AddController();
native(530) final function RemoveController();

// Pick best pawn target
#if !IG_SWAT    //tcohen: defunct (weapon zoom)
native(531) final function pawn PickTarget(out float bestAim, out float bestDist, vector FireDir, vector projStart, float MaxRange);
#endif
native(534) final function actor PickAnyTarget(out float bestAim, out float bestDist, vector FireDir, vector projStart);

native final function bool InLatentExecution(int LatentActionNumber); //returns true if controller currently performing latent action specified by LatentActionNumber

#if !IG_UC_THREADED // crombie: moved StopWaiting to Object
// Force end to sleep
native function StopWaiting();
#endif

#if !IG_SWAT // ckline: we don't support this
native function EndClimbLadder();
#endif

event MayFall(); //return true if allowed to fall - called by engine when pawn is about to fall

function PendingStasis()
{
	bStasis = true;
	Pawn = None;
}

/* DisplayDebug()
list important controller attributes on canvas
*/
function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	if ( Pawn == None )
	{
		Super.DisplayDebug(Canvas,YL,YPos);
		return;
	}

	Canvas.SetDrawColor(255,0,0);
	Canvas.DrawText("CONTROLLER "$GetItemName(string(self))$" Pawn "$GetItemName(string(Pawn)));
	YPos += YL;
	Canvas.SetPos(4,YPos);

	if ( Enemy != None )
		Canvas.DrawText("     STATE: "$GetStateName()$" Timer: "$TimerCounter$" Enemy "$Enemy.GetHumanReadableName(), false);
	else
		Canvas.DrawText("     STATE: "$GetStateName()$" Timer: "$TimerCounter$" NO Enemy ", false);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	if ( PlayerReplicationInfo == None )
		Canvas.DrawText("     NO PLAYERREPLICATIONINFO", false);
	else
		PlayerReplicationInfo.DisplayDebug(Canvas,YL,YPos);

	YPos += YL;
	Canvas.SetPos(4,YPos);
}

simulated function String GetHumanReadableName()
{
	if ( PlayerReplicationInfo != None )
		return PlayerReplicationInfo.PlayerName;
	return GetItemName(String(self));
}

simulated function rotator GetViewRotation()
{
	return Rotation;
}

/* Reset()
reset actor to initial state
*/
function Reset()
{
	Super.Reset();
	Enemy = None;
	LastSeenTime = 0;
	StartSpot = None;
}

function bool AvoidCertainDeath()
{
	return false;
}

/* ClientSetLocation()
replicated function to set location and rotation.  Allows server to force new location for
teleports, etc.
*/
function ClientSetLocation( vector NewLocation, rotator NewRotation )
{
	SetRotation(NewRotation);
	If ( (Rotation.Pitch > RotationRate.Pitch)
		&& (Rotation.Pitch < 65536 - RotationRate.Pitch) )
	{
		If (Rotation.Pitch < 32768)
			NewRotation.Pitch = RotationRate.Pitch;
		else
			NewRotation.Pitch = 65536 - RotationRate.Pitch;
	}
	if ( Pawn != None )
	{
		NewRotation.Roll  = 0;
		Pawn.SetRotation( NewRotation );
		Pawn.SetLocation( NewLocation );
	}
}

/* ClientSetRotation()
replicated function to set rotation.  Allows server to force new rotation.
*/
function ClientSetRotation( rotator NewRotation )
{
	SetRotation(NewRotation);
	if ( Pawn != None )
	{
		NewRotation.Pitch = 0;
		NewRotation.Roll  = 0;
		Pawn.SetRotation( NewRotation );
	}
}

#if IG_SWAT
function ClientDying(class<DamageType> DamageType, vector HitLocation, vector HitMomentum, vector inKillerLocation)
#else
function ClientDying(class<DamageType> DamageType, vector HitLocation)
#endif
{
	if ( Pawn != None )
	{
#if IG_SWAT
		Pawn.PlayDying(DamageType, HitLocation, HitMomentum, inKillerLocation);
#else
		Pawn.PlayDying(DamageType, HitLocation);
#endif
		Pawn.GotoState('Dying');
	}
}

#if IG_SHARED
native function float GetDistanceToSound(Actor Listener, vector SourceLocation, vector ListenerLocation);
#endif

/* AIHearSound()
Called when AI controlled pawn would hear a sound.  Default AI implementation uses MakeNoise()
interface for hearing appropriate sounds instead
*/
event AIHearSound (
	actor Actor,
#if !IG_EFFECTS
	int Id,
#endif
	sound S,
	vector SoundLocation,
	vector Parameters,
	bool Attenuate
);

event SoakStop(string problem);

function Possess(Pawn aPawn)
{
	aPawn.PossessedBy(self);
	Pawn = aPawn;
	if ( PlayerReplicationInfo != None )
		PlayerReplicationInfo.bIsFemale = Pawn.bIsFemale;
	// preserve Pawn's rotation initially for placed Pawns
	FocalPoint = Pawn.Location + 512*vector(Pawn.Rotation);
	Restart();
}

// unpossessed a pawn (not because pawn was killed)
function UnPossess()
{
    if ( Pawn != None )
        Pawn.UnPossessed();
    Pawn = None;
}

function WasKilledBy(Controller Other);

//TMC removed Epic's Weapon or Inventory code here - function Weapon GetLastWeapon()

/* PawnDied()
 unpossess a pawn (because pawn was killed)
 */
function PawnDied(Pawn P)
{
	if ( Pawn != P )
		return;

	if ( Pawn != None )
	{
		SetLocation(Pawn.Location);
		Pawn.UnPossessed();
	}
Pawn = None;
	PendingMover = None;
	if ( bIsPlayer )
    {
        if ( !IsInState('GameEnded') )
		GotoState('Dead'); // can respawn
    }
	else
		Destroy();
}

function Restart()
{
	Enemy = None;
}

event LongFall(); // called when latent function WaitForLanding() doesn't return after 4 seconds

// notifications of pawn events (from C++)
// if return true, then pawn won't get notified
event bool NotifyPhysicsVolumeChange(PhysicsVolume NewVolume);
event bool NotifyHeadVolumeChange(PhysicsVolume NewVolume);
event bool NotifyLanded(vector HitNormal);
event bool NotifyHitWall(vector HitNormal, actor Wall);
event bool NotifyBump(Actor Other);
event NotifyHitMover(vector HitNormal, mover Wall);
event NotifyJumpApex();
event NotifyMissedJump();

// notifications called by pawn in script
function NotifyTakeHit(pawn InstigatedBy, vector HitLocation, int Damage, class<DamageType> damageType, vector Momentum)
{
}

function SetFall();	//about to fall
function PawnIsInPain(PhysicsVolume PainVolume);	// called when pawn is taking pain volume damage

event PreBeginPlay()
{
	AddController();
	Super.PreBeginPlay();
	if ( bDeleteMe )
		return;

	SightCounter = 0.2 * FRand();  //offset randomly
}

event PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( !bDeleteMe && bIsPlayer && (Role == ROLE_Authority) )
	{
		PlayerReplicationInfo = Spawn(PlayerReplicationInfoClass, Self,,vect(0,0,0),rot(0,0,0));
		InitPlayerReplicationInfo();
	}
}

function InitPlayerReplicationInfo()
{
	if (PlayerReplicationInfo.PlayerName == "")
		PlayerReplicationInfo.SetPlayerName(class'GameInfo'.Default.DefaultPlayerName);
}

function bool SameTeamAs(Controller C)
{
	if ( (PlayerReplicationInfo == None) || (C == None) || (C.PlayerReplicationInfo == None)
		|| (PlayerReplicationInfo.Team == None) )
		return false;
	return Level.Game.IsOnTeam(C,PlayerReplicationInfo.Team.TeamIndex);
}

#if !IG_SWAT // ckline: we don't support pickups
function HandlePickup(Pickup pick)
{
	if ( MoveTarget == pick )
		{
		if ( pick.MyMarker != None )
		{
			MoveTarget = pick.MyMarker;
			Pawn.Anchor = pick.MyMarker;
			MoveTimer = 0.5;
		}
		else
		MoveTimer = -1.0;
}
}
#endif

simulated event Destroyed()
{
	if ( Role < ROLE_Authority )
    {
    	Super.Destroyed();
		return;
    }

	RemoveController();

	if ( bIsPlayer && (Level.Game != None) )
		Level.Game.logout(self);
	if ( PlayerReplicationInfo != None )
	{
		if ( !PlayerReplicationInfo.bOnlySpectator && (PlayerReplicationInfo.Team != None) )
			PlayerReplicationInfo.Team.RemoveFromTeam(self);
		PlayerReplicationInfo.Destroy();
	}
	Super.Destroyed();
}

event bool AllowDetourTo(NavigationPoint N)
{
	return true;
}

/* AdjustView()
by default, check and see if pawn still needs to update eye height
(only if some playercontroller still has pawn as its viewtarget)
Overridden in playercontroller
*/
function AdjustView( float DeltaTime )
{
	local Controller C;

	for ( C=Level.ControllerList; C!=None; C=C.NextController )
		if ( C.IsA('PlayerController') && (PlayerController(C).ViewTarget == Pawn) )
			return;

	Pawn.bUpdateEyeHeight =false;
	Pawn.Eyeheight = Pawn.BaseEyeheight;
}

function bool WantsSmoothedView()
{
	return ( (Pawn != None) && ((Pawn.Physics==PHYS_Walking)
#if !IG_SWAT // ckline: we don't support this
                                || (Pawn.Physics==PHYS_Spider)
#endif
                                ) && !Pawn.bJustLanded );
}

function GameHasEnded()
{
	GotoState('GameEnded');
}

function ClientGameEnded()
{
	GotoState('GameEnded');
}

simulated event RenderOverlays( canvas Canvas );

/* GetFacingDirection()
returns direction faced relative to movement dir

0 = forward
16384 = right
32768 = back
49152 = left
*/
function int GetFacingDirection()
{
	return 0;
}

//------------------------------------------------------------------------------
// Speech related

function byte GetMessageIndex(name PhraseName)
{
	return 0;
}

function SendMessage(PlayerReplicationInfo Recipient, name MessageType, byte MessageID, float Wait, name BroadcastType)
{
	SendVoiceMessage(PlayerReplicationInfo, Recipient, MessageType, MessageID, BroadcastType);
}

function bool AllowVoiceMessage(name MessageType)
{
	if ( Level.TimeSeconds - OldMessageTime < 10 )
		return false;
	else
		OldMessageTime = Level.TimeSeconds;

	return true;
}

function SendVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID, name broadcasttype)
{
	local Controller P;

	if ( !AllowVoiceMessage(MessageType) )
		return;

	for ( P=Level.ControllerList; P!=None; P=P.NextController )
	{
		if ( PlayerController(P) != None )
		{
				if ( (broadcasttype == 'GLOBAL') || !Level.Game.bTeamGame )
					P.ClientVoiceMessage(Sender, Recipient, messagetype, messageID);
				else if ( Sender.Team == P.PlayerReplicationInfo.Team )
					P.ClientVoiceMessage(Sender, Recipient, messagetype, messageID);
			}
		else if ( (messagetype == 'ORDER') && ((Recipient == None) || (Recipient == P.PlayerReplicationInfo)) )
			P.BotVoiceMessage(messagetype, messageID, self);
	}
}

function ClientVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID);
function BotVoiceMessage(name messagetype, byte MessageID, Controller Sender);

//***************************************************************
// interface used by ScriptedControllers to query pending controllers

function bool WouldReactToNoise( float Loudness, Actor NoiseMaker)
{
	return false;
}

function bool WouldReactToSeeing(Pawn Seen)
{
	return false;
}

//***************************************************************
// AI related

/* AdjustToss()
return adjustment to Z component of aiming vector to compensate for arc given the target
distance
*/
function vector AdjustToss(float TSpeed, vector Start, vector End, bool bNormalize)
{
	local vector Dest2D, Result, Vel2D;
	local float Dist2D;

	if ( Start.Z > End.Z + 64 )
	{
		Dest2D = End;
		Dest2D.Z = Start.Z;
		Dist2D = VSize(Dest2D - Start);
		TSpeed *= Dist2D/VSize(End - Start);
		Result = SuggestFallVelocity(Dest2D,Start,TSpeed,TSpeed);
		Vel2D = result;
		Vel2D.Z = 0;
		Result.Z = Result.Z + (End.Z - Start.Z) * VSize(Vel2D)/Dist2D;
	}
	else
	{
		Result = SuggestFallVelocity(End,Start,TSpeed,TSpeed);
	}
	if ( bNormalize )
		return TSpeed * Normal(Result);
	else
		return Result;
}

event PrepareForMove(NavigationPoint Goal, ReachSpec Path);
function WaitForMover(Mover M);
function MoverFinished();
function UnderLift(Mover M);

#if !IG_SWAT // ckline: we don't support pickups
event float Desireability(Pickup P)
{
	return P.BotDesireability(Pawn);
}
#endif

/* called before start of navigation network traversal to allow setup of transient navigation flags
*/
event SetupSpecialPathAbilities();

event HearNoise( float Loudness, Actor NoiseMaker);
event SeePlayer( Pawn Seen );	// called when a player (bIsPlayer==true) pawn is seen
event SeeMonster( Pawn Seen );	// called when a non-player (bIsPlayer==false) pawn is seen
event EnemyNotVisible();

function ShakeView( float shaketime, float RollMag, vector OffsetMag, float RollRate, vector OffsetRate, float OffsetTime);

function NotifyKilled(Controller Killer, Controller Killed, pawn Other)
{
	if ( Enemy == Other )
		Enemy = None;
}

#if !IG_SWAT // ckline: don't need support pickups
function float AdjustDesireFor(Pickup P);
#endif

function StopFiring()
{
	bFire = 0;
	bAltFire = 0;
}

/* AdjustAim()
AIController version does adjustment for non-controlled pawns.
PlayerController version does the adjustment for player aiming help.
Only adjusts aiming at pawns
allows more error in Z direction (full as defined by AutoAim - only half that difference for XY)
*/
simulated function rotator AdjustAim(Ammunition FiredAmmunition, vector projStart, int aimerror)
{
	return Rotation;
}

/* ReceiveWarning()
 AI controlled creatures may duck
 if not falling, and projectile time is long enough
 often pick opposite to current direction (relative to shooter axis)
*/
function ReceiveWarning(Pawn shooter, float projSpeed, vector FireDir)
{
}

function SetPawnClass(string inClass, string inCharacter)
{
    local class<Pawn> pClass;
    pClass = class<Pawn>(DynamicLoadObject(inClass, class'Class'));
    if ( pClass != None )
        PawnClass = pClass;
}

//TMC removed Epic's Weapon or Inventory code here - function ChangedWeapon()

function ServerReStartPlayer()
{
	if ( Level.NetMode == NM_Client )
		return;
	if ( Pawn != None )
		ServerGivePawn();
}

function ServerGivePawn();

////////////////////////////////////////////////////////
// Migrated from SwatGamePlayerController
function ServerRequestInteract( ICanBeUsed Target, String UniqueID )
{
    local Controller i;

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ServerRequestInteract(). Target="$Target$", UniqueID = "$UniqueID  );

    //target can be none when it is torn off, in which case, use the unique ID to find the actor
    if( Target == None && UniqueID != "" )
        Target = ICanBeUsed(FindByUniqueID( None, UniqueID ));

    if (Level.GetEngine().EnableDevTools)
    {
        mplog( self$"---SGPC::ServerRequestInteract()... Target="$Target$", UniqueID = "$UniqueID  );
        mplog( "...target's owner="$Actor(Target).Owner );
    }

    if ( Target != None && Target.CanBeUsedNow() )
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...1" );

        Target.OnUsed(Pawn);
        Target.PostUsed();

        // Walk the controller list here to notify all clients
        for ( i = Level.ControllerList; i != None; i = i.NextController )
        {
            i.ClientOnTargetUsed( Target, UniqueID );
        }
    }
    else
    {
        if (Level.GetEngine().EnableDevTools)
            mplog( "...Interact request ignored." );
    }
}

function ClientOnTargetUsed( ICanBeUsed Target, String UniqueID )
{
    //target can be none when it is torn off, in which case, use the unique ID to find the actor
    if( Target == None && UniqueID != "" )
        Target = ICanBeUsed(FindByUniqueID( None, UniqueID ));

    if (Level.GetEngine().EnableDevTools)
        mplog( self$"---SGPC::ClientOnTargetUsed(). Target="$Target );

    Target.PostUsed();
}

event MonitoredPawnAlert();

function StartMonitoring(Pawn P, float MaxDist)
{
	MonitoredPawn = P;
	MonitorStartLoc = P.Location;
	MonitorMaxDistSq = MaxDist * MaxDist;
}

function bool AutoTaunt()
{
	return false;
}

function bool DontReuseTaunt(int T)
{
	return false;
}
// **********************************************
// Controller States

State Dead
{
ignores SeePlayer, HearNoise, KilledBy;

	function PawnDied(Pawn P)
	{
		if ( Level.NetMode != NM_Client )
			warn(self$" Pawndied while dead");
	}

	function ServerReStartPlayer()
	{
		if ( Level.NetMode == NM_Client )
			return;
		Level.Game.RestartPlayer(self);
	}
}

state GameEnded
{
#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
ignores SeePlayer, HearNoise, KilledBy, NotifyBump, HitWall, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange, Falling, PostTakeDamage, ReceiveWarning;
#else
ignores SeePlayer, HearNoise, KilledBy, NotifyBump, HitWall, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange, Falling, TakeDamage, ReceiveWarning;
#endif

	function BeginState()
	{
		if ( Pawn != None )
		{
			Pawn.bPhysicsAnimUpdate = false;
			Pawn.StopAnimating();
#if !IG_SWAT // don't replicate the AnimRate in Swat (it's always 1.0)
			Pawn.SimAnim.AnimRate = 0;
#endif
			Pawn.SetCollision(true,false,false);
			Pawn.Velocity = vect(0,0,0);
			Pawn.SetPhysics(PHYS_None);
			Pawn.UnPossessed();
			Pawn.bIgnoreForces = true;
		}
		if ( !bIsPlayer )
			Destroy();
	}
}

#if IG_SWAT_INTERRUPT_STATE_SUPPORT //tcohen: support for notifying states before they are interrupted
simulated function InterruptState(name Reason);
#endif

#if IG_SWAT //tcohen: support for quick-equip interface
simulated function EquipmentSlot GetEquipmentSlotForQualify() { return SLOT_Invalid; }
#endif

defaultproperties
{
	RotationRate=(Pitch=3072,Yaw=30000,Roll=2048)
	AcquisitionYawRate=20000
     FovAngle=+00090.000000
	 bHidden=true
	 bHiddenEd=true
	 PlayerReplicationInfoClass=Class'Engine.PlayerReplicationInfo'
 	 MinHitWall=-1.f
}
