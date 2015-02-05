//=============================================================================
// The moving brush class.
// This is a built-in Unreal class and it shouldn't be modified.
// Note that movers by default have bNoDelete==true.  This makes movers and their default properties
// remain on the client side.  If a mover subclass has bNoDelete=false, then its default properties must
// be replicated
//=============================================================================
class Mover extends Actor
	native
	nativereplication;

// How the mover should react when it encroaches an actor.
var() enum EMoverEncroachType
{
	ME_StopWhenEncroach,	// Stop when we hit an actor.
	ME_ReturnWhenEncroach,	// Return to previous position when we hit an actor.
   	ME_CrushWhenEncroach,   // Crush the poor helpless actor.
   	ME_IgnoreWhenEncroach,  // Ignore encroached actors.
} MoverEncroachType;

// How the mover moves from one position to another.
var() enum EMoverGlideType
{
	MV_MoveByTime,			// Move linearly.
	MV_GlideByTime,			// Move with smooth acceleration.
} MoverGlideType;

// What classes can bump trigger this mover
var() enum EBumpType
{
	BT_PlayerBump,		// Can only be bumped by player.
	BT_PawnBump,		// Can be bumped by any pawn
	BT_AnyBump,			// Can be bumped by any solid actor
} BumpType;

//-----------------------------------------------------------------------------
// Keyframe numbers.
var() byte       KeyNum;           // Current or destination keyframe.
var byte         PrevKeyNum;       // Previous keyframe.
var() const byte NumKeys;          // Number of keyframes in total (0-3).
var() const byte WorldRaytraceKey; // Raytrace the world with the brush here.
var() const byte BrushRaytraceKey; // Raytrace the brush here.

//-----------------------------------------------------------------------------
// Movement parameters.
var() float      MoveTime;         // Time to spend moving between keyframes.
var() float      StayOpenTime;     // How long to remain open before closing.
var() float      OtherTime;        // TriggerPound stay-open time.
var() int        EncroachDamage;   // How much to damage encroached actors.

//-----------------------------------------------------------------------------
// Mover state.
var() bool       bTriggerOnceOnly; // Go dormant after first trigger.
var() bool       bSlave;           // This brush is a slave.
var() bool		 bUseTriggered;		// Triggered by player grab
var() bool		 bDamageTriggered;	// Triggered by taking damage
var() bool       bDynamicLightMover; // Apply dynamic lighting to mover.
var() bool       bUseShortestRotation; // rot by -90 instead of +270 and so on.
var(ReturnGroup) bool bIsLeader;
var() name       PlayerBumpEvent;  // Optional event to cause when the player bumps the mover.
var() name       BumpEvent;			// Optional event to cause when any valid bumper bumps the mover.
var   actor      SavedTrigger;      // Who we were triggered by.
var() float		 DamageThreshold;	// minimum damage to trigger
var	  int		 numTriggerEvents;	// number of times triggered ( count down to untrigger )
var	  Mover		 Leader;			// for having multiple movers return together
var	  Mover		 Follower;
var(ReturnGroup) name		 ReturnGroup;		// if none, same as tag
var() float		 DelayTime;			// delay before starting to open

//-----------------------------------------------------------------------------
// Audio.
var(MoverSounds) sound      OpeningSound;     // When start opening.
var(MoverSounds) sound      OpenedSound;      // When finished opening.
var(MoverSounds) sound      ClosingSound;     // When start closing.
var(MoverSounds) sound      ClosedSound;      // When finish closing.
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
var(MoverSounds) sound      MoveAmbientSound; // Optional ambient sound when moving.
#endif
var(MoverSounds) sound		LoopSound;		  // Played on Loop

//-----------------------------------------------------------------------------
// Events

var(MoverEvents) name		OpeningEvent;	// Event to cause when opening
var(MoverEvents) name		OpenedEvent;	// Event to cause when opened
var(MoverEvents) name		ClosingEvent;	// Event to cause when closing
var(MoverEvents) name		ClosedEvent;	// Event to cause when closed
var(MoverEvents) name		LoopEvent;		// Event to cause when the mover loops
//-----------------------------------------------------------------------------
// Other stuff

//-----------------------------------------------------------------------------
// Internal.
var vector       KeyPos[24];
var rotator      KeyRot[24];
var vector       BasePos, OldPos, OldPrePivot, SavedPos;
var rotator      BaseRot, OldRot, SavedRot;
var           float       PhysAlpha;       // Interpolating position, 0.0-1.0.
var           float       PhysRate;        // Interpolation rate per second.

// AI related
var       NavigationPoint  myMarker;
var		  bool			bOpening, bDelaying, bClientPause;
var		  bool			bClosed;	// mover is in closed position, and no longer moving
var		  bool			bPlayerOnly;
var(AI)	  bool			bAutoDoor;	// automatically setup Door NavigationPoint for this mover
var(AI)	  bool			bNoAIRelevance; // don't warn about this mover during path review

// for client side replication
var		vector			SimOldPos;
var		int				SimOldRotPitch, SimOldRotYaw, SimOldRotRoll;
var		vector			SimInterpolate;
var		vector			RealPosition;
var     rotator			RealRotation;
var		int				ClientUpdate;

// Used for controlling antiportals

var array<AntiPortalActor>	AntiPortals;	
var() name					AntiPortalTag;

replication
{
	// Things the server should send to the client.
	reliable if( Role==ROLE_Authority )
		SimOldPos, SimOldRotPitch, SimOldRotYaw, SimOldRotRoll, SimInterpolate, RealPosition, RealRotation;
}

/* StartInterpolation()
when this function is called, the actor will start moving along an interpolation path
beginning at Dest
*/	
simulated function StartInterpolation()
{
	GotoState('');
	bInterpolating = true;
	SetPhysics(PHYS_None);
}

simulated function Timer()
{
	if ( Velocity != vect(0,0,0) )
	{
		bClientPause = false;
		return;		
	}
	if ( Level.NetMode == NM_Client )
	{
		if ( ClientUpdate == 0 ) // not doing a move
		{
			if ( bClientPause )
			{
				if ( VSize(RealPosition - Location) > 3 )
					SetLocation(RealPosition);
				else
					RealPosition = Location;
				SetRotation(RealRotation);
				bClientPause = false;
			}
			else if ( RealPosition != Location )
				bClientPause = true;
		}
		else
			bClientPause = false;
	}
	else 
	{
		RealPosition = Location;
		RealRotation = Rotation;
	}
}

//-----------------------------------------------------------------------------
// Movement functions.

// Interpolate to keyframe KeyNum in Seconds time.
simulated final function InterpolateTo( byte NewKeyNum, float Seconds )
{
	NewKeyNum = Clamp( NewKeyNum, 0, ArrayCount(KeyPos)-1 );
	if( NewKeyNum==PrevKeyNum && KeyNum!=PrevKeyNum )
	{
		// Reverse the movement smoothly.
		PhysAlpha = 1.0 - PhysAlpha;
		OldPos    = BasePos + KeyPos[KeyNum];
		OldRot    = BaseRot + KeyRot[KeyNum];
	}
	else
	{
		// Start a new movement.
		OldPos    = Location;
		OldRot    = Rotation;
		PhysAlpha = 0.0;
	}

	// Setup physics.
	SetPhysics(PHYS_MovingBrush);
	bInterpolating   = true;
	PrevKeyNum       = KeyNum;
	KeyNum			 = NewKeyNum;
	PhysRate         = 1.0 / FMax(Seconds, 0.005);

	ClientUpdate++;
	SimOldPos = OldPos;
	SimOldRotYaw = OldRot.Yaw;
	SimOldRotPitch = OldRot.Pitch;
	SimOldRotRoll = OldRot.Roll;
	SimInterpolate.X = 100 * PhysAlpha;
	SimInterpolate.Y = 100 * FMax(0.01, PhysRate);
	SimInterpolate.Z = 256 * PrevKeyNum + KeyNum;
}

// Set the specified keyframe.
final function SetKeyframe( byte NewKeyNum, vector NewLocation, rotator NewRotation )
{
	KeyNum         = Clamp( NewKeyNum, 0, ArrayCount(KeyPos)-1 );
	KeyPos[KeyNum] = NewLocation;
	KeyRot[KeyNum] = NewRotation;
}

// Interpolation ended.
simulated event KeyFrameReached()
{
	local byte OldKeyNum;

	OldKeyNum  = PrevKeyNum;
	PrevKeyNum = KeyNum;
	PhysAlpha  = 0;
	ClientUpdate--;

	// If more than two keyframes, chain them.
	if( KeyNum>0 && KeyNum<OldKeyNum )
	{
		// Chain to previous.
		InterpolateTo(KeyNum-1,MoveTime);
	}
	else if( KeyNum<NumKeys-1 && KeyNum>OldKeyNum )
	{
		// Chain to next.
		InterpolateTo(KeyNum+1,MoveTime);
	}
	else
	{
		// Finished interpolating.
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
		AmbientSound = None;
#endif
		if ( (ClientUpdate == 0) && (Level.NetMode != NM_Client) )
		{
			RealPosition = Location;
			RealRotation = Rotation;
		}
	}
}

//-----------------------------------------------------------------------------
// Mover functions.

// Notify AI that mover finished movement
function FinishNotify()
{
	local Controller C;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( (C.Pawn != None) && (C.PendingMover == self) )
			C.MoverFinished();
}

// Handle when the mover finishes closing.
function FinishedClosing()
{
	local Mover M;
	
	// Update sound effects.
#if IG_EFFECTS
    UnTriggerEffectEvent('Closing');
    TriggerEffectEvent('Closed');
#else
	PlaySound( ClosedSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0); 
#endif
	
	// Handle Events
	
	TriggerEvent( ClosedEvent, Self, Instigator );
	
	// Notify our triggering actor that we have completed.
	if( SavedTrigger != None )
		SavedTrigger.EndEvent();
		
	SavedTrigger = None;
	Instigator = None;
	If ( MyMarker != None )
		MyMarker.MoverClosed();
	bClosed = true;
	FinishNotify(); 
	for ( M=Leader; M!=None; M=M.Follower )
		if ( !M.bClosed )
			return;
	UnTriggerEvent(OpeningEvent, Self, Instigator);
}

// Handle when the mover finishes opening.
function FinishedOpening()
{
	// Update sound effects.
#if IG_EFFECTS
    UnTriggerEffectEvent('Opening');
    TriggerEffectEvent('Opened');
#else
	PlaySound( OpenedSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
#endif
	
	// Trigger any chained movers / Events
	TriggerEvent(Event, Self, Instigator);
	TriggerEvent(OpenedEvent, Self, Instigator);

	If ( MyMarker != None )
		MyMarker.MoverOpened();
	FinishNotify();
}

// Open the mover.
function DoOpen()
{
	bOpening = true;
	bDelaying = false;
	InterpolateTo( 1, MoveTime );
	MakeNoise(1.0);
#if IG_EFFECTS
    TriggerEffectEvent('Opening');
#else
	PlaySound( OpeningSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
#endif
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	AmbientSound = MoveAmbientSound;
#endif
	TriggerEvent(OpeningEvent, Self, Instigator);
	if ( Follower != None )
		Follower.DoOpen();
}

// Close the mover.
function DoClose()
{
	bOpening = false;
	bDelaying = false;
	InterpolateTo( Max(0,KeyNum-1), MoveTime );
	MakeNoise(1.0);
#if IG_EFFECTS
    TriggerEffectEvent('Closing');
#else
	PlaySound( ClosingSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
#endif
	UntriggerEvent(Event, self, Instigator);
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	AmbientSound = MoveAmbientSound;
#endif
	TriggerEvent(ClosingEvent,Self,Instigator);
	if ( Follower != None )
		Follower.DoClose();
}

//-----------------------------------------------------------------------------
// Engine notifications.

// When mover enters gameplay.
simulated function BeginPlay()
{
	local AntiPortalActor AntiPortal;
	
	if(AntiPortalTag != '')
	{
		foreach AllActors(class'AntiPortalActor',AntiPortal,AntiPortalTag)
		{
			AntiPortals.Length = AntiPortals.Length + 1;
			AntiPortals[AntiPortals.Length - 1] = AntiPortal;
		}
	}

	// timer updates real position every second in network play
	if ( Level.NetMode != NM_Standalone )
	{
		if ( Level.NetMode == NM_Client )
			settimer(4.0, true);
		else
			settimer(1.0, true);
		if ( Role < ROLE_Authority )
			return;
	}

	if ( Level.NetMode != NM_Client )
	{
		RealPosition = Location;
		RealRotation = Rotation;
	}

	// Init key info.
	Super.BeginPlay();
	KeyNum         = Clamp( KeyNum, 0, ArrayCount(KeyPos)-1 );
	PhysAlpha      = 0.0;

	// Set initial location.
	Move( BasePos + KeyPos[KeyNum] - Location );

	// Initial rotation.
	SetRotation( BaseRot + KeyRot[KeyNum] );

	// find movers in same group
	if ( ReturnGroup == '' )
		ReturnGroup = tag;
	Leader = None;
	Follower = None;
}

// Immediately after mover enters gameplay.
function PostBeginPlay()
{
	local mover M;

	// Initialize all slaves.
	if( !bSlave )
	{
		foreach DynamicActors( class 'Mover', M, Tag )
		{
			if( M.bSlave )
			{
				M.GotoState('');
				M.SetBase( Self );
			}
		}
	}

	if ( bIsLeader )
	{	
		Leader = self;
		ForEach DynamicActors( class'Mover', M )
			if ( (M != self) && (M.ReturnGroup == ReturnGroup) )
			{
				M.Leader = self;
				M.Follower = Follower;
				Follower = M;
			}
	}
	else if ( Leader == None )
	{
		// if no one in returngroup, I am the leader anyway
		ForEach DynamicActors( class'Mover', M )
		{
			if ( (M != self) && (M.ReturnGroup == ReturnGroup) )
				return;
		}
		Leader = self;
	}
}

function MakeGroupStop()
{
	// Stop moving immediately.
	bInterpolating = false;
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	AmbientSound = None;
#endif
	GotoState( , '' );

	if ( Follower != None )
		Follower.MakeGroupStop();
}

function MakeGroupReturn()
{
	// Abort move and reverse course.
	bInterpolating = false;
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	AmbientSound = None;
#endif
	if(bIsLeader || Leader==Self)
	{
	if( KeyNum<PrevKeyNum )
		GotoState( , 'Open' );
	else
		GotoState( , 'Close' );
	}

	if ( Follower != None )
		Follower.MakeGroupReturn();
}
		
// Return true to abort, false to continue.
function bool EncroachingOn( actor Other )
{
	local Pawn P;
	
	if ( Other == None )
		return false;
	if ( ((Pawn(Other) != None) && (Pawn(Other).Controller == None)) || Other.IsA('Decoration') )
	{
		Other.TakeDamage(10000, None, Other.Location, vect(0,0,0), class'Crushed');
		return false;
	}
	if ( Other.IsA('Pickup') )
	{
		if ( !Other.bAlwaysRelevant && (Other.Owner == None) )
			Other.Destroy();
		return false;
	}
	if ( Other.IsA('Fragment') || Other.IsA('Gib') || Other.IsA('Projectile') )
	{
		Other.Destroy();
		return false;
	}

	// Damage the encroached actor.
	if( EncroachDamage != 0 )
		Other.TakeDamage( EncroachDamage, Instigator, Other.Location, vect(0,0,0), class'Crushed' );

	// If we have a bump-player event, and Other is a pawn, do the bump thing.
	P = Pawn(Other);
	if( P!=None && (P.Controller != None) && P.IsPlayerPawn() )
	{
#if IG_SCRIPTING // david: support for Gameplay.Mover
		DoPlayerBumpEvent( Other );
#else
		if ( PlayerBumpEvent!='' )
			Bump( Other );
#endif

		if ( (P != None) && (P.Controller != None) && (P.Base != self) && (P.Controller.PendingMover == self) )
			P.Controller.UnderLift(self);	// pawn is under lift - tell him to move
	}

	// Stop, return, or whatever.
	if( MoverEncroachType == ME_StopWhenEncroach )
	{
		Leader.MakeGroupStop();
		return true;
	}
	else if( MoverEncroachType == ME_ReturnWhenEncroach )
	{
		Leader.MakeGroupReturn();
		if ( Other.IsA('Pawn') )
			Pawn(Other).PlayMoverHitSound();
		return true;
	}
	else if( MoverEncroachType == ME_CrushWhenEncroach )
	{
		// Kill it.
		Other.KilledBy( Instigator );
		return false;
	}
	else if( MoverEncroachType == ME_IgnoreWhenEncroach )
	{
		// Ignore it.
		return false;
	}
}

#if IG_SCRIPTING // david: support for Gameplay.Mover
function DoPlayerBumpEvent( actor Other )
{
	if ( PlayerBumpEvent!='' )
		Bump( Other );
}

function DoBumpEvent( actor Other )
{
	TriggerEvent(BumpEvent, self, Pawn(Other));
}
#endif

// When bumped by player.
#if IG_RWO    //tcohen: reactive world objects
function PostBump( actor Other )
#else
function Bump( actor Other )
#endif
{
	local pawn  P;

	P = Pawn(Other);
	if ( bUseTriggered && (P != None) && !P.IsHumanControlled() && P.IsPlayerPawn() )
	{
		Trigger(P,P);
		P.Controller.WaitForMover(self);
	}	
	if ( (BumpType != BT_AnyBump) && (P == None) )
		return;
	if ( (BumpType == BT_PlayerBump) && !P.IsPlayerPawn() )
		return;
	if ( (BumpType == BT_PawnBump) && P.bAmbientCreature )
		return;
#if IG_SCRIPTING // david: support for Gameplay.Mover
	DoBumpEvent(P);

	if ( (P != None) && P.IsPlayerPawn() )
		DoPlayerBumpEvent(P);
#else
	TriggerEvent(BumpEvent, self, P);

	if ( (P != None) && P.IsPlayerPawn() )
		TriggerEvent(PlayerBumpEvent, self, P);
#endif
}

// When damaged
#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
function PostTakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation, 
						Vector momentum, class<DamageType> damageType)
#else
function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation, 
						Vector momentum, class<DamageType> damageType)
#endif
{
	if ( bDamageTriggered && (Damage >= DamageThreshold) )
	{
#if !IG_SWAT // ckline: we don't support this
		if ( (AIController(instigatedBy.Controller) != None)
			&& (instigatedBy.Controller.Focus == self) )
			instigatedBy.Controller.StopFiring();
#endif
		self.Trigger(self, instigatedBy);
}
}

//========================================================================
// Master State for OpenTimed mover states (for movers that open and close)

state OpenTimedMover
{
	function DisableTrigger();
	function EnableTrigger();

Open:
	bClosed = false;
	DisableTrigger();
	if ( DelayTime > 0 )
	{
		bDelaying = true;
		Sleep(DelayTime);
	}
	DoOpen();
	FinishInterpolation();
	FinishedOpening();
	Sleep( StayOpenTime );
	if( bTriggerOnceOnly )
		GotoState('');
Close:
	DoClose();
	FinishInterpolation();
	FinishedClosing();
	EnableTrigger();
}

// Open when stood on, wait, then close.
state() StandOpenTimed extends OpenTimedMover
{
	function Attach( actor Other )
	{
		local pawn  P;

		P = Pawn(Other);
		if ( (BumpType != BT_AnyBump) && (P == None) )
			return;
		if ( (BumpType == BT_PlayerBump) && !P.IsPlayerPawn() )
			return;
		if ( (BumpType == BT_PawnBump) && (Other.Mass < 10) )
			return;
		SavedTrigger = None;
		GotoState( 'StandOpenTimed', 'Open' );
	}

	function DisableTrigger()
	{
		Disable( 'Attach' );
	}

	function EnableTrigger()
	{
		Enable('Attach');
	}
}

// Open when bumped, wait, then close.
state() BumpOpenTimed extends OpenTimedMover
{
#if IG_RWO    //tcohen: reactive world objects
	function PostBump( actor Other )
#else
	function Bump( actor Other )
#endif
	{
		if ( (BumpType != BT_AnyBump) && (Pawn(Other) == None) )
			return;
		if ( (BumpType == BT_PlayerBump) && !Pawn(Other).IsPlayerPawn() )
			return;
		if ( (BumpType == BT_PawnBump) && (Other.Mass < 10) )
			return;
#if IG_RWO
		Global.PostBump( Other );
#else
		Global.Bump( Other );
#endif
		SavedTrigger = None;
		Instigator = Pawn(Other);
		Instigator.Controller.WaitForMover(self);
		GotoState( 'BumpOpenTimed', 'Open' );
	}

	function DisableTrigger()
	{
		Disable( 'Bump' );
	}

	function EnableTrigger()
	{
		Enable('Bump');
	}
}

// When triggered, open, wait, then close.
state() TriggerOpenTimed extends OpenTimedMover
{
	function Trigger( actor Other, pawn EventInstigator )
	{
		SavedTrigger = Other;
		Instigator = EventInstigator;
		if ( SavedTrigger != None )
			SavedTrigger.BeginEvent();
		GotoState( 'TriggerOpenTimed', 'Open' );
	}

	function DisableTrigger()
	{
		Disable( 'Trigger' );
	}

	function EnableTrigger()
	{
		Enable('Trigger');
	}
}

//=================================================================
// Other Mover States

// Toggle when triggered.
state() TriggerToggle
{
	function Trigger( actor Other, pawn EventInstigator )
	{
		SavedTrigger = Other;
		Instigator = EventInstigator;
		if ( SavedTrigger != None )
			SavedTrigger.BeginEvent();
		if( KeyNum==0 || KeyNum<PrevKeyNum )
			GotoState( 'TriggerToggle', 'Open' );
		else
			GotoState( 'TriggerToggle', 'Close' );
	}
Open:
	bClosed = false;
	if ( DelayTime > 0 )
	{
		bDelaying = true;
		Sleep(DelayTime);
	}
	DoOpen();
	FinishInterpolation();
	FinishedOpening();
	if ( SavedTrigger != None )
		SavedTrigger.EndEvent();
	Stop;
Close:		
	DoClose();
	FinishInterpolation();
	FinishedClosing();
}

// Open when triggered, close when get untriggered.
state() TriggerControl
{
	function Trigger( actor Other, pawn EventInstigator )
	{
		numTriggerEvents++;
		SavedTrigger = Other;
		Instigator = EventInstigator;
		if ( SavedTrigger != None )
			SavedTrigger.BeginEvent();
		GotoState( 'TriggerControl', 'Open' );
	}
	function UnTrigger( actor Other, pawn EventInstigator )
	{
		numTriggerEvents--;
		if ( numTriggerEvents <=0 )
		{
			numTriggerEvents = 0;
			SavedTrigger = Other;
			Instigator = EventInstigator;
			SavedTrigger.BeginEvent();
			GotoState( 'TriggerControl', 'Close' );
		}
	}

	function BeginState()
	{
		numTriggerEvents = 0;
	}

Open:
	bClosed = false;
	if ( DelayTime > 0 )
	{
		bDelaying = true;
		Sleep(DelayTime);
	}
	DoOpen();
	FinishInterpolation();
	FinishedOpening();
	SavedTrigger.EndEvent();
	if( bTriggerOnceOnly )
		GotoState('');
	Stop;
Close:		
	DoClose();
	FinishInterpolation();
	FinishedClosing();
}

// Start pounding when triggered.
state() TriggerPound
{
	function Trigger( actor Other, pawn EventInstigator )
	{
		numTriggerEvents++;
		SavedTrigger = Other;
		Instigator = EventInstigator;
		GotoState( 'TriggerPound', 'Open' );
	}
	function UnTrigger( actor Other, pawn EventInstigator )
	{
		numTriggerEvents--;
		if ( numTriggerEvents <= 0 )
		{
			numTriggerEvents = 0;
			SavedTrigger = None;
			Instigator = None;
			GotoState( 'TriggerPound', 'Close' );
		}
	}
	function BeginState()
	{
		numTriggerEvents = 0;
	}

Open:
	bClosed = false;
	if ( DelayTime > 0 )
	{
		bDelaying = true;
		Sleep(DelayTime);
	}
	DoOpen();
	FinishInterpolation();
	Sleep(OtherTime);
Close:
	DoClose();
	FinishInterpolation();
	Sleep(StayOpenTime);
	if( bTriggerOnceOnly )
		GotoState('');
	if( SavedTrigger != None )
		goto 'Open';
}

//-----------------------------------------------------------------------------
// Bump states.


// Open when bumped, close when reset.
state() BumpButton
{
#if IG_RWO    //tcohen: reactive world objects
	function PostBump( actor Other )
#else
	function Bump( actor Other )
#endif
	{
		if ( (BumpType != BT_AnyBump) && (Pawn(Other) == None) )
			return;
		if ( (BumpType == BT_PlayerBump) && !Pawn(Other).IsPlayerPawn() )
			return;
		if ( (BumpType == BT_PawnBump) && (Other.Mass < 10) )
			return;
#if IG_RWO
		Global.Bump( Other );
#else
		Global.PostBump( Other );
#endif
		SavedTrigger = Other;
		Instigator = Pawn( Other );
		Instigator.Controller.WaitForMover(self);
		GotoState( 'BumpButton', 'Open' );
	}
	function BeginEvent()
	{
		bSlave=true;
	}
	function EndEvent()
	{
		bSlave     = false;
		Instigator = None;
		GotoState( 'BumpButton', 'Close' );
	}
Open:
	bClosed = false;
	Disable( 'Bump' );
	if ( DelayTime > 0 )
	{
		bDelaying = true;
		Sleep(DelayTime);
	}
	DoOpen();
	FinishInterpolation();
	FinishedOpening();
	if( bTriggerOnceOnly )
		GotoState('');
	if( bSlave )
		Stop;
Close:
	DoClose();
	FinishInterpolation();
	FinishedClosing();
	Enable( 'Bump' );
}

defaultproperties
{
	 bNoDelete=true
	 bPathColliding=true
     MoverEncroachType=ME_ReturnWhenEncroach
     MoverGlideType=MV_GlideByTime
     NumKeys=2
	 BrushRaytraceKey=0
     MoveTime=+00001.000000
     StayOpenTime=+00004.000000
     bStatic=False
	 bDynamicLightMover=False
	 bHidden=false
     CollisionRadius=+00160.000000
     CollisionHeight=+00160.000000
     bCollideActors=True
     bBlockActors=True
     bBlockPlayers=True
     Physics=PHYS_MovingBrush
     InitialState=BumpOpenTimed
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications 
//	 TransientSoundVolume=+00001.000000
//   SoundVolume=228
//#endif
	 NetPriority=2.7
	 bAlwaysRelevant=true
     RemoteRole=ROLE_SimulatedProxy
	 bClosed=true
	 bShadowCast=true
	 bEdShouldSnap=true
	 bAcceptsProjectors=true
	 bOnlyDirtyReplication=true
}
