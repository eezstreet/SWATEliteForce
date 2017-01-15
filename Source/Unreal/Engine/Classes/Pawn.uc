//=============================================================================
// Pawn, the base class of all actors that can be controlled by players or AI.
//
// Pawns are the physical representations of players and creatures in a level.
// Pawns have a mesh, collision, and physics.  Pawns can take damage, make sounds,
// and hold weapons and other inventory.  In short, they are responsible for all
// physical interaction between the player or AI and the world.
//
// This is a built-in Unreal class and it shouldn't be modified.
//=============================================================================
class Pawn extends Actor
#if IG_SWAT
    implements  ICanHoldEquipment,
                ICanUseProtectiveEquipment
#endif
	abstract
	native
	placeable
#if IG_SWAT
	config(SwatPawn)
#else
	config(user)
#endif
#if IG_SHARED	// marc: AI LODding
	dependsOn(Tyrion_ResourceBase)
#endif
    dependsOn(FiredWeapon)
	nativereplication;

#if IG_SWAT
import enum EquipmentSlot from HandheldEquipment;
import enum Pocket from HandheldEquipment;
import enum FireMode from FiredWeapon;
import enum ESkeletalRegion from Actor;
#endif

//-----------------------------------------------------------------------------
// Pawn variables.

var Controller Controller;

#if IG_TRIBES3	// place for designers to put goals/abilities
var(AI) editinline array< class<Tyrion_GoalBase> > goals		"Goals the resource is trying to achieve";
var(AI)	editinline array< class<Tyrion_ActionBase> > abilities	"The actions this resource is capable of performing";
var Tyrion_ResourceBase.AI_LOD_Levels AI_LOD_LevelOrig;	// AI Level of detail before AI is disabled
#endif

#if IG_SWAT
// Future Direct Collision Memory
var vector	m_LastSteerDirection;
var float   m_LastSteerDirectionTime;
#endif

#if IG_SHARED // marc: Tyrion resources
var Tyrion_ResourceBase CharacterAI;
var Tyrion_ResourceBase MovementAI;
var Tyrion_ResourceBase WeaponAI;
#if !IG_SWAT
var Tyrion_ResourceBase HeadAI;
var(AI) Tyrion_ResourceBase.AI_LOD_Levels AI_LOD_Level;	// AI Level of detail (LOD)
#endif
#endif

#if IG_SHARED // marc: Tyrion debug
var bool logTyrion;									// for debug: switch on Tyrion logs
#endif

#if IG_SWAT // crombie: AI debug
var bool logAI;
#endif

#if IG_SHARED // crombie: for the PawnList in Level
// for the PawnList in LevelInfo
var Pawn       nextPawn;
#endif

#if IG_BATTLEROOM
var bool       bDisplayBattleDebug;
#endif

#if IG_SWAT_DEBUG_VISION
var bool	   bDebugVision;
#endif

// cache net relevancy test
var float NetRelevancyTime;
var playerController LastRealViewer;
var actor LastViewer;

#if IG_SWAT
var config float	RelevancyPropogationDistance;
var config float	RelevancyLOSDistance;
#endif

// Physics related flags.
var bool		bJustLanded;		// used by eyeheight adjustment
var bool		bUpAndOut;			// used by swimming
var bool		bIsWalking;			// currently walking (can't jump, affects animations)
var bool		bWarping;			// Set when travelling through warpzone (so shouldn't telefrag)
var bool		bWantsToCrouch;		// if true crouched (physics will automatically reduce collision height to CrouchHeight)
var const bool	bIsCrouched;		// set by physics to specify that pawn is currently crouched
var const bool	bTryToUncrouch;		// when auto-crouch during movement, continually try to uncrouch
var() bool		bCanCrouch;			// if true, this pawn is capable of crouching

#if IG_SMOOTH_PHYSICS_STEPPING
var private bool bIsCurrentMeshRenderZValid;
var private float CurrentMeshRenderZ;
#endif


#if IG_SWAT  // Talk about last minute hacks.
// This hack is to fix VUG bug 731.  If you kill someone just after you yourself have been killed, the controller passed
// into Died() and Killed() will be none.  This happens because the pawn is unpossessed from the controller as soon as death
// occurs.  This isn't a bug in single player, but in mp, this will get treated as if the killed pawn suicided, even though he
// really didn't.  This fix caches the controller that was unpossessed, and uses that as the Killer passed into Died/Killed()
var private Controller  LastUnPossessedController;
#endif

#if IG_SWAT

var private bool bForceCrouch;       // Used in VIP mode; if true the pawn will not uncrouch.

// We handle leaning similarly to how Unreal handles crouching. [darren]
var bool        bWantsToLeanLeft;
var bool        bWantsToLeanRight;

enum ELeanState
{
    kLeanStateNone,
    kLeanStateLeft,
    kLeanStateRight,
};

// Target lean state that the pawn wants to be in
var const ELeanState DesiredLeanState;

// The current lean state of the pawn
var const ELeanState LeanState;

// The yaw at which this lean was started at. Used to limit yaw while leaning.
var const int LeanLockedYaw;

// The alpha, from 0 to 1, of a lean in the direction of LeanState. 0 is
// no lean, 1 is full lean. This is updated every tick.
var const float LeanAlpha;

// Leaning tuning variables
var config private float LeanTransitionDuration; // Time in seconds
var config private float LeanHorizontalDistance;

#endif
var bool		bCrawler;			// crawling - pitch and roll based on surface pawn is on
var const bool	bReducedSpeed;		// used by movement natives
var bool		bJumpCapable;
var	bool		bCanJump;			// movement capabilities - used by AI
var	bool 		bCanWalk;
var	bool		bCanSwim;
var	bool		bCanFly;
#if !IG_SWAT // ckline: we don't support this
var	bool		bCanClimbLadders;
#endif
var	bool		bCanStrafe;
var	bool		bCanDoubleJump;
var	bool		bAvoidLedges;		// don't get too close to ledges
var	bool		bStopAtLedges;		// if bAvoidLedges and bStopAtLedges, Pawn doesn't try to walk along the edge at all
var	bool		bNoJumpAdjust;		// set to tell controller not to modify velocity of a jump/fall
var	bool		bCountJumps;		// if true, inventory wants message whenever this pawn jumps
var const bool	bSimulateGravity;	// simulate gravity for this pawn on network clients when predicting position (true if pawn is walking or falling)
var	bool		bUpdateEyeheight;	// if true, UpdateEyeheight will get called every tick
var	bool		bIgnoreForces;		// if true, not affected by external forces
var const bool	bNoVelocityUpdate;	// used by C++ physics
var	bool		bCanWalkOffLedges;	// Can still fall off ledges, even when walking (for Player Controlled pawns)
var bool		bCanBeBaseForPawns;	// all your 'base', are belong to us
var bool		bClientCollision;	// used on clients when temporarily turning off collision
var const bool	bSimGravityDisabled;	// used on network clients
var bool		bDirectHitWall;		// always call pawn hitwall directly (no controller notifyhitwall)

// Does this pawn Collision Cylinder collide with Havok and generate events? Will create a Havok Character Control proxy if so.
var(Havok) bool bHavokCharacterCollisions "If true this pawn's bones will collide with Havok objects, push them out of the way, and generate collision events.";
var const transient bool bHavokInitCalled; // internal check
// radius of Havok proxy 0.02 (1/50) extra than that of Unreal to allow Havok first go ;)
var(Havok) float bHavokCharacterCollisionExtraRadius "How much larger than the Unreal collision cylinder should the Havok collision cylinder be? Default is 1, which is enough to ensure that Havok can respond to collisions before Unreal does.\r\n\r\nWARNING: must be in Unreal units, not meters (1 Unreal unit == 1/50 meter)";

// used by dead pawns (for bodies landing and changing collision box)
var		bool	bThumped;
var		bool	bInvulnerableBody;

// AI related flags
var		bool	bIsFemale;
var		bool	bAutoActivate;			// if true, automatically activate Powerups which have their bAutoActivate==true
#if !IG_SWAT // ckline: we don't support this
var		bool	bCanPickupInventory;	// if true, will pickup inventory when touching pickup actors
#endif
var		bool	bUpdatingDisplay;		// to avoid infinite recursion through inventory setdisplay
var		bool	bAmbientCreature;		// AIs will ignore me
var(AI) bool	bLOSHearing;			// can hear sounds from line-of-sight sources (which are close enough to hear)
										// bLOSHearing=true is like UT/Unreal hearing
var(AI) bool	bSameZoneHearing;		// can hear any sound in same zone (if close enough to hear)
var(AI) bool	bAdjacentZoneHearing;	// can hear any sound in adjacent zone (if close enough to hear)
var(AI) bool	bMuffledHearing;		// can hear sounds through walls (but muffled - sound distance increased to double plus 4x the distance through walls
var(AI) bool	bAroundCornerHearing;	// Hear sounds around one corner (slightly more expensive, and bLOSHearing must also be true)
var(AI) bool	bDontPossess;			// if true, Pawn won't be possessed at game start
var		bool	bRollToDesired;			// Update roll when turning to desired rotation (normally false)

var		bool	bCachedRelevant;		// network relevancy caching flag
var		bool	bUseCompressedPosition;	// use compressed position in networking - true unless want to replicate roll, or very high velocities
#if IG_SWAT
var		config bool bWeaponBob;
#else
var		globalconfig bool bWeaponBob;
#endif

var     bool    bHideRegularHUD;
var		bool	bSpecialHUD;
var		bool    bSpecialCalcView;		// If true, the Controller controlling this pawn will call 'SpecialCalcView' to find camera pos.
var		bool	bIsTyping;

// AI basics.
var 	byte	Visibility;			//How visible is the pawn? 0=invisible, 128=normal, 255=highly visible
var		float	DesiredSpeed;
var		float	MaxDesiredSpeed;
#if !IG_SWAT // ckline: we don't support this
var(AI) name	AIScriptTag;		// tag of AIScript which should be associated with this pawn
#endif
var(AI) float	HearingThreshold;	// max distance at which a makenoise(1.0) loudness sound can be heard
var(AI)	float	Alertness;			// -1 to 1 ->Used within specific states for varying reaction to stimuli
var(AI)	float	SightRadius;		// Maximum seeing distance.
var(AI)	float	PeripheralVision;	// Cosine of limits of peripheral vision.
var()	float	SkillModifier;			// skill modifier (same scale as game difficulty)
var const float	AvgPhysicsTime;		// Physics updating time monitoring (for AI monitoring reaching destinations)
var		float	MeleeRange;			// Max range for melee attack (not including collision radii)
var NavigationPoint Anchor;			// current nearest path;
var const NavigationPoint LastAnchor;		// recent nearest path
var		float	FindAnchorFailedTime;	// last time a FindPath() attempt failed to find an anchor.
var		float	LastValidAnchorTime;	// last time a valid anchor was found
var     vector	LastValidAnchorLocation;	// last place we found a valid anchor
var     float   LastDistanceToAnchor;
var		float	DestinationOffset;	// used to vary destination over NavigationPoints
var		float	NextPathRadius;		// radius of next path in route
var		vector	SerpentineDir;		// serpentine direction
var		float	SerpentineDist;
var		float	SerpentineTime;		// how long to stay straight before strafing again
var const float	UncrouchTime;		// when auto-crouch during movement, continually try to uncrouch once this decrements to zero
var		float	SpawnTime;

#if IG_SHARED
var const float VisionCounter;      // when the VisionCounter < 0, we look for other pawns
var     Range   VisionUpdateRange;  // min and max time that will be used to make a random VisionCounterTime
#endif

#if IG_SWAT
var const array<Pawn>	ViewablePawns;	// the list of pawns that we are looking for when we test vision

// how often we re-test path reachability (every 0.25 to 0.75 seconds)
const kMinRetestPathReachabilityDelta = 0.25;
const kMaxRetestPathReachabilityDelta = 0.75;

var float NextPathReachabilityRetestedTime; // the last time we retested path reachability

var		bool	bAlwaysUseWalkAimErrorWhenMoving;	// when set to true, we always use the walk aim error (no run aim error) while moving
#endif

// Movement.
var config float	GroundSpeed;    // The maximum ground speed.
var float   WaterSpeed;     // The maximum swimming speed.
var float   AirSpeed;		// The maximum flying speed.
var float	LadderSpeed;	// Ladder climbing speed
var float	AccelRate;		// max acceleration rate
var float	JumpZ;      	// vertical acceleration w/ jump
var float   AirControl;		// amount of AirControl available to the pawn
#if !IG_SWAT
// In Swat, we specify absolute speeds directly in a given animation set.
// Therefore, these percentages do not apply. [darren]
var config float	WalkingPct;		// pct. of running speed that walking speed is
var config float	CrouchedPct;	// pct. of running speed that crouched walking speed is
#endif
var float	MaxFallSpeed;	// max speed pawn can land without taking damage (also limits what paths AI can use)
var vector	ConstantAcceleration;	// acceleration added to pawn when falling

#if IG_SWAT
var float			ReachedDestinationThreshold;
#endif

// Player info.
var	string			OwnerName;		// Name of owning player (for save games, coop)
//TMC made BaseEyeHeight config
var config float    BaseEyeHeight; 	// Base eye height above collision center.
// added config variable CrouchEyeHeight
var config float	CrouchEyeHeight;
var float        	EyeHeight;     	// Current eye height, adjusted for bobbing and stairs.
var	const vector	Floor;			// Normal of floor pawn is standing on (only used by PHYS_Spider and PHYS_Walking)
var float			SplashTime;		// time of last splash
var config float	CrouchHeight;	// CollisionHeight when crouching
var config float	CrouchRadius;	// CollisionRadius when crouching
var float			OldZ;			// Old Z Location - used for eyeheight smoothing
var PhysicsVolume	HeadVolume;		// physics volume of head
var travel int      Health;         // Health: 100 = normal maximum
var	float			LastPainTime;	// last time pawn played a takehit animation (updated in PlayHit())
var class<DamageType> ReducedDamageType; // which damagetype this creature is protected from (used by AI)
var float			HeadScale;

// Sound and noise management
// remember location and position of last noises propagated
var const 	vector 		noise1spot;
var const 	float 		noise1time;
var const	pawn		noise1other;
var const	float		noise1loudness;
var const 	vector 		noise2spot;
var const 	float 		noise2time;
var const	pawn		noise2other;
var const	float		noise2loudness;
var			float		LastPainSound;

// view bob
#if IG_SWAT
var				config float Bob;
#else
var				globalconfig float Bob;
#endif
var				float				LandBob, AppliedBob;
var				float bobtime;
var				vector			WalkBob;

var float SoundDampening;
var float DamageScaling;

var localized  string MenuName; // Name used for this pawn type in menus (e.g. player selection)

// shadow decal
#if IG_SWAT // ckline
var ShadowProjector Shadow;
#else
var Projector Shadow;
#endif

// blood effect
var class<Effects> BloodEffect;
var class<Effects> LowGoreBlood;

#if IG_TRIBES3 || IG_SWAT // marc: used to determine if Tyrion structures should be initialized for this pawn
var(AI) string ControllerClassName;	// Used to specify which controller class should be spawned for this pawn.
									// Must be set to None for player controlled pawns - login function sets the controller.
#else
var class<AIController> ControllerClass;	// default class to use when pawn is controlled by AI (can be modified by an AIScript)
#endif

var PlayerReplicationInfo PlayerReplicationInfo;

#if !IG_SWAT // ckline: we don't support this
var LadderVolume OnLadder;		// ladder currently being climbed
#endif

var name LandMovementState;		// PlayerControllerState to use when moving on land or air
var name WaterMovementState;	// PlayerControllerState to use when moving in water

var PlayerStart LastStartSpot;	// used to avoid spawn camping
var float LastStartTime;

// Animation status
var name AnimAction;			// use for replicating anims

enum EAnimPlayType
{
    kAPT_Normal,
    kAPT_Additive,
};

// Animation updating by physics FIXME - this should be handled as an animation object
// Note that animation channels 2 through 11 are used for animation updating
var vector DeathHitLocation;		// location of last hit (for playing hit/death anims)
#if IG_SWAT
// Location of the pawn that killed us. This is used for Swat's death cam. We
// use a hard location instead of an actor so that in multiplayer, we don't
// have to worry about relevancy.
var vector KillerLocation;
const kInvalidKillerLocationZ = -10000.0;
#endif
var class<DamageType> DeathHitDamageType;	// damage type of last hit (for playing hit/death anims)
var vector DeathHitMomentum;		// momentum to apply when torn off (bTearOff == true)
var bool bPhysicsAnimUpdate;
var bool bWasCrouched;
var bool bWasWalking;
var bool bWasOnGround;
var bool bInitializeAnimation;
var bool bPlayedDeath;
var EPhysics OldPhysics;
var float OldRotYaw;			// used for determining if pawn is turning
var vector OldAcceleration;
var float BaseMovementRate;		// FIXME - temp - used for scaling movement
var name MovementAnims[4];		// Forward, Back, Left, Right
var name TurnLeftAnim;
var name TurnRightAnim;			// turning anims when standing in place (scaled by turn speed)
var(AnimTweaks) float BlendChangeTime;	// time to blend between movement animations
var float MovementBlendStartTime;	// used for delaying the start of run blending
var float ForwardStrafeBias;	// bias of strafe blending in forward direction
var float BackwardStrafeBias;	// bias of strafe blending in backward direction

var transient CompressedPosition PawnPosition;

//
// Equipment variables
//

var config float FirstPersonFOV;
var protected Hands Hands;
var bool bRenderHands; // if false, the first person Hands (and hence weapon) will not be rendered

var private HandheldEquipment ActiveItem;   //access with GetActiveItem(), set by the equipping process

//The PendingItem is the item that will be equipped as soon as
//  the ActiveItem is finished being UnEquipped.
//This may change while the ActiveItem is being UnEquipped
//  (for example, if the player presses another equip key).
var private HandheldEquipment PendingItem;   //access with GetPendingItem(), set by the equipping process

// This is the way the server tells all clients in a network game which item
// should be equipped.
var private Pocket DesiredItemPocket;

// This value starts off being false. When the first piece of equipment is
// equipped we set it to true and it stays true from then on. This value is
// used to prevent the equipping key frame from triggering the effect event to
// play a sound when the item becomes equipped. Players could hear the sounds
// when other players and AI's became relevant and this was giving them info
// they shouldn't have.
var bool HasEquippedFirstItemYet;

#if IG_SWAT
// Irrational Added [darren]
// Collision avoidance variables
// The soft radius acts as a comfort zone around the pawn. The soft radius is
// found by adding CollisionSoftRadiusOffset to CollisionRadius
var (Collision) const float CollisionSoftRadiusOffset;

var private int LastCollisionAvoidanceTick;

// Clients can directly set this to enable or disable collision avoidance
var private bool bCollisionAvoidanceEnabled;

var private bool bAvoidingCollision;
var private Door MovingThroughDoor;

var private CollisionAvoidanceNotifier	CollisionAvoidanceNotifier;

var protected array<SkeletalRegionInformation> SkeletalRegionInformation;
var protected array<ProtectiveEquipment> SkeletalRegionProtection;
#endif

#if IG_SWAT
var float AccumulatedLimbInjury;
#endif

#if IG_SHARED // ckline: notifications upon Pawn death and Actor destruction
var private const bool bNotifiedDeathListeners; // have listeners been notified that this pawn died?
#endif

replication
{
	// Variables the server should send to the client.
	reliable if( bNetDirty && (Role==ROLE_Authority) )
        bSimulateGravity, bIsCrouched,
#if IG_SWAT
        bForceCrouch, KillerLocation,
#endif
        bIsWalking, bIsTyping, PlayerReplicationInfo, AnimAction, DeathHitDamageType, DeathHitLocation,HeadScale;
	reliable if( bTearOff && bNetDirty && (Role==ROLE_Authority) )
		DeathHitMomentum;
    //TMC removed
//	reliable if ( bNetDirty && !bNetOwner && (Role==ROLE_Authority) )
//		bSteadyFiring;
	reliable if( bNetDirty && bNetOwner && Role==ROLE_Authority )
         Controller, GroundSpeed, WaterSpeed, AirSpeed, AccelRate, JumpZ, AirControl;   //TMC removed SelectedItem,
         //ActiveItem, PendingItem;
	reliable if( bNetDirty && Role==ROLE_Authority )
         Health, DesiredItemPocket;
    unreliable if ( !bNetOwner && Role==ROLE_Authority )
#if IG_SWAT
		DesiredLeanState,
#endif
		PawnPosition;

	// replicated functions sent to server by owning client
	reliable if( Role<ROLE_Authority )
        ServerRequestEquip, ServerRequestMelee, ServerRequestReload, ServerBeginFiringWeapon, ServerEndFiringWeapon,
        ServerSetCurrentFireMode;
}

// Havok character collision event
struct HavokCharacterObjectInteractionEvent
{
	var vector  Position;
	var vector  Normal;
	var float   ObjectImpulse;
	var float   Timestep;
	var float	ProjectedVelocity;
	var float	ObjectMassInv;
	var float	CharacterMassInv;
	var Actor	Body;
};

// Havok character collision output
struct HavokCharacterObjectInteractionResult
{
	var vector  ObjectImpulse;
	var vector  ImpulsePosition;
	var vector  CharacterImpulse;
};

#if IG_SHARED
// for the PawnList
native function AddPawn();
native function RemovePawn();

final function NotifyKilled(Controller Killer, Controller Killed, pawn Other)
{
	// notify the controller (just in case -- SWAT is not using the controller)
	if (Controller != None)
	{
		Controller.NotifyKilled(Killer, Killed, Other);
	}
}

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{
    // we don't ignore anyone;
    return false;
}

native function bool CanSee(Actor Other);
#endif

#if IG_SWAT
// Overridden in SwatAI
event bool CanHitTargetAt(Actor Target, vector AILocation)	{ return false; }
event bool CanHit(Actor Target)								{ return false; }
#endif

// Return true if you want to change the default output as given in res, based on the input data.
// By default, just do whatever Havok thinks is best, so we can actually just return false.
event bool HavokCharacterCollision(HavokCharacterObjectInteractionEvent data, out HavokCharacterObjectInteractionResult res)
{
	return false;
}

simulated event SetHeadScale(float NewScale);

// Begin Irrational Addition [darren]
native final function bool IsActorReachable(Actor actor);
native final function bool IsLocationReachable(vector location);
// End Irrational Addition [darren]

#if IG_SWAT
// returns true if we don't hit any world geometry when placed at the test location
native final function bool FitsAtLocation( vector NewLocation );
#endif // IG_SWAT

// Begin Irrational Addition [crombie]

// overridden in SwatAI - needs to be here for navigation code
//
// Note: script side call is not an event, because there is a pure-native
// implementation with the same name that should be called by native methods.
// Native implementation of this func simply calls APawn::IsDoorBlockedForPawn(ADoor& Target).
native function bool IsDoorBlockedForPawn(Door Target);

// End Irrational Addition [crombie]

#if IG_SWAT
// Irrational Added [crombie]

// Collision avoidance functions

function DisableCollisionAvoidance()
{
    bCollisionAvoidanceEnabled = false;
}

function EnableCollisionAvoidance()
{
    bCollisionAvoidanceEnabled = true;
}

function bool IsCollisionAvoidanceEnabled()
{
    return bCollisionAvoidanceEnabled;
}

// tests to see if the pawn is at a walking speed (or below)
// NOTE: this is overridden in SwatPawn
function bool IsAtRunningSpeed()
{
    return VSize(Velocity) >= Default.GroundSpeed;
}

native function ClearRouteCache();
#endif // IG_SWAT

native function bool ReachedDestination(Actor Goal);
native function bool ReachedLocation(vector Location);
#if IG_SWAT
// Renamed the engine's ForceCrouch, since its behavior is not as accurate as
// our custom force-crouch related functions and variables. ForceCrouch always
// gets thwarted the next tick by whatever input the player is currently
// giving. [darren]
native function ForceCrouchThisTick();
#else
native function ForceCrouch();
#endif

#if IG_SWAT
// @NOTE: This is not at all related to the engine's ForceCrouch above,
// despite their frighteningly similar names. This function allows subclasses
// to control the setting of the bForceCrouch variable. [darren]
simulated function SetForceCrouchState(bool inbForceCrouch)
{
    bForceCrouch = inbForceCrouch;
}
#endif // IG_SWAT

//TMC removed Epic's Weapon or Inventory code here - function GetDemoRecordingWeapon()

/* Reset()
reset actor to initial state - used when restarting level without reloading.
*/
function Reset()
{
	if ( (Controller == None) || Controller.bIsPlayer )
		Destroy();
	else
		Super.Reset();
}

//TMC removed... this is called on the weapon now directly
/*
function Fire( optional float F )
{
    if( Weapon!=None )
        Weapon.Fire(F);
}
*/

function DrawHUD(Canvas Canvas);

// If returns false, do normal calview anyway
function bool SpecialCalcView(out actor ViewActor, out vector CameraLocation, out rotator CameraRotation );

#if IG_SWAT // ckline:
// Returns true if this pawn is controlled by a human sitting in front of
// this computer.
//
// This is useful when you want to do something different depending on whether
// this is the local or remote representation of a given player's pawn.
simulated function bool IsControlledByLocalHuman()
{
    // If this test fails, we're dealing with an AI so return false.
    if ( PlayerController(Controller) == None )
        return false;

    if (
        Level.NetMode != NM_DedicatedServer &&          // All pawns are remotely controlled on dedicated servers
        Controller != None &&                           // Remote representation of a pawn don't have a controller
        Controller == Level.GetLocalPlayerController()  // All pawns on server have controllers, so make sure it's the locally controlled pawn
        )
    {
        return true; // yep, a human is driving this pawn locally
    }

    return false; // nope, it's a manifestation of a remote pawn.
}

// Override in derived classes. The equipment system needs to be able to call
// this on AI's.
simulated function bool IsPrimaryWeapon( HandheldEquipment theItem )
{
    Assert( false );
    return false; //dkaplan, just to prevent compiler warning
}
#endif

simulated function String GetHumanReadableName()
{
    // If in a multiplayer game, return the player's chosen name
	if (Level.NetMode != NM_StandAlone &&  // HACK FIXME: we shouldn't be creating PlayerReplicationInfo in standalone games anyhow
		PlayerReplicationInfo != None)
    {
		return PlayerReplicationInfo.PlayerName;
}

    // else return some default
    return MenuName; // return the class name, without package specifiers
}


#if IG_SWAT
simulated function String GetHumanReadableTeamName()
{
    if (PlayerReplicationInfo != None && PlayerReplicationInfo.Team != None)
        return PlayerReplicationInfo.Team.TeamName;
    return "";
}
#endif

#if IG_SWAT
// Override in base classes
event int GetTeamNumber();
#endif

function PlayTeleportEffect(bool bOut, bool bSound)
{
	MakeNoise(1.0);
}

/* PossessedBy()
 Pawn is possessed by Controller
*/
function PossessedBy(Controller C)
{
	Controller = C;
	NetPriority = 3;

	if ( C.PlayerReplicationInfo != None )
	{
		PlayerReplicationInfo = C.PlayerReplicationInfo;
		OwnerName = PlayerReplicationInfo.PlayerName;
	}
	if ( C.IsA('PlayerController') )
	{
		if ( Level.NetMode != NM_Standalone )
			RemoteRole = ROLE_AutonomousProxy;
		BecomeViewTarget();
	}
	else
		RemoteRole = Default.RemoteRole;

	SetOwner(Controller);	// for network replication
	Eyeheight = BaseEyeHeight;
	ChangeAnimation();
}

function UnPossessed()
{
#if IG_SWAT
    LastUnPossessedController = Controller;
#endif
	PlayerReplicationInfo = None;
	SetOwner(None);
	Controller = None;
}

/* PointOfView()
called by controller when possessing this pawn
false = 1st person, true = 3rd person
*/
simulated function bool PointOfView()
{
	return false;
}

function BecomeViewTarget()
{
	bUpdateEyeHeight = true;
}

function DropToGround()
{
	bCollideWorld = True;
	bInterpolating = false;
	if ( Health > 0 )
	{
		SetCollision(true,true,true);
		SetPhysics(PHYS_Falling);
#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
		AmbientSound = None;
#endif
		if ( IsHumanControlled() )
			Controller.GotoState(LandMovementState);
	}
}

#if !IG_SWAT // ckline: we don't support this
function bool CanGrabLadder()
{
	return ( bCanClimbLadders
			&& (Controller != None)
			&& (Physics != PHYS_Ladder)
			&& ((Physics != Phys_Falling) || (abs(Velocity.Z) <= JumpZ)) );
}
#endif

event SetWalking(bool bNewIsWalking)
{
	if ( bNewIsWalking != bIsWalking )
	{
		bIsWalking = bNewIsWalking;
		ChangeAnimation();
	}
}

function bool CanSplash()
{
	if ( (Level.TimeSeconds - SplashTime > 0.25)
		&& ((Physics == PHYS_Falling) || (Physics == PHYS_Flying))
		&& (Abs(Velocity.Z) > 100) )
	{
		SplashTime = Level.TimeSeconds;
		return true;
	}
	return false;
}

#if !IG_SWAT // ckline: we don't support this
function EndClimbLadder(LadderVolume OldLadder)
{
	if ( Controller != None )
		Controller.EndClimbLadder();
	if ( Physics == PHYS_Ladder )
		SetPhysics(PHYS_Falling);
}

function ClimbLadder(LadderVolume L)
{
	OnLadder = L;
	SetRotation(OnLadder.WallDir);
	SetPhysics(PHYS_Ladder);
	if ( IsHumanControlled() )
		Controller.GotoState('PlayerClimbing');
}
#endif // !IG_SWAT

/* DisplayDebug()
list important actor variable on canvas.  Also show the pawn's controller and weapon info
*/
simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	local string T;
	Super.DisplayDebug(Canvas, YL, YPos);

	Canvas.SetDrawColor(255,255,255);

	Canvas.DrawText("Animation Action "$AnimAction$" Health "$Health);
	YPos += YL;
	Canvas.SetPos(4,YPos);
	Canvas.DrawText("Anchor "$Anchor$" Serpentine Dist "$SerpentineDist$" Time "$SerpentineTime);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	T = "Floor "$Floor$" DesiredSpeed "$DesiredSpeed$" Crouched "$bIsCrouched$" Try to uncrouch "$UncrouchTime;
#if !IG_SWAT // ckline: we don't support this
	if ( (OnLadder != None) || (Physics == PHYS_Ladder) )
		T=T$" on ladder "$OnLadder;
#endif
	Canvas.DrawText(T);
	YPos += YL;
	Canvas.SetPos(4,YPos);
	Canvas.DrawText("EyeHeight "$Eyeheight$" BaseEyeHeight "$BaseEyeHeight$" Physics Anim "$bPhysicsAnimUpdate);
	YPos += YL;
	Canvas.SetPos(4,YPos);

	if ( Controller == None )
	{
		Canvas.SetDrawColor(255,0,0);
		Canvas.DrawText("NO CONTROLLER");
		YPos += YL;
		Canvas.SetPos(4,YPos);
	}
	else
		Controller.DisplayDebug(Canvas,YL,YPos);

	if ( GetActiveItem() == None )
	{
		Canvas.SetDrawColor(0,255,0);
		Canvas.DrawText("NO ACTIVE ITEM");
		YPos += YL;
		Canvas.SetPos(4,YPos);
	}
	else
		GetActiveItem().DisplayDebug(Canvas,YL,YPos);
}

//
// Compute offset for drawing an inventory item.
//
simulated function vector CalcDrawOffset()
{
	local vector DrawOffset;

    AssertWithDescription(Hands != None,
        "[tcohen] The Pawn named "$name$" was called to CalcDrawOffset().  But it has no Hands.");

	if ( Controller == None )
		return (Hands.PlayerViewOffset >> Rotation) + BaseEyeHeight * vect(0,0,1);

	DrawOffset = ((90/FirstPersonFOV * Hands.PlayerViewOffset) >> GetViewRotation() );
	if ( !IsLocallyControlled() )
		DrawOffset.Z += BaseEyeHeight;
	else
	{
		DrawOffset.Z += EyeHeight;
        if( bWeaponBob && GetActiveItem() != None)
			DrawOffset += WeaponBob(0); //TMC 11-11-2003 += WeaponBob(GetActiveItem().GetFirstPersonModel().BobDamping);
	}
	return DrawOffset;
}

function vector WeaponBob(float BobDamping)
{
	Local Vector WBob;

	WBob = BobDamping * WalkBob;
	WBob.Z = (0.45 + 0.55 * BobDamping) * WalkBob.Z;
	return WBob;
}

function CheckBob(float DeltaTime, vector Y)
{
	local float Speed2D;

    if( !bWeaponBob )
    {
		BobTime = 0;
		WalkBob = Vect(0,0,0);
        return;
    }
	Bob = FClamp(Bob, -0.01, 0.01);
	if (Physics == PHYS_Walking )
	{
		Speed2D = VSize(Velocity);
		if ( Speed2D < 10 )
			BobTime += 0.2 * DeltaTime;
		else
			BobTime += DeltaTime * (0.3 + 0.7 * Speed2D/GroundSpeed);
		WalkBob = Y * Bob * Speed2D * sin(8 * BobTime);
		AppliedBob = AppliedBob * (1 - FMin(1, 16 * deltatime));
		WalkBob.Z = AppliedBob;
		if ( Speed2D > 10 )
			WalkBob.Z = WalkBob.Z + 0.75 * Bob * Speed2D * sin(16 * BobTime);
		if ( LandBob > 0.01 )
		{
			AppliedBob += FMin(1, 16 * deltatime) * LandBob;
			LandBob *= (1 - 8*Deltatime);
		}
	}
	else if ( Physics == PHYS_Swimming )
	{
		Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
		WalkBob = Y * Bob *  0.5 * Speed2D * sin(4.0 * Level.TimeSeconds);
		WalkBob.Z = Bob * 1.5 * Speed2D * sin(8.0 * Level.TimeSeconds);
	}
	else
	{
		BobTime = 0;
		WalkBob = WalkBob * (1 - FMin(1, 8 * deltatime));
	}
}

//***************************************
// Interface to Pawn's Controller

// return true if controlled by a Player (AI or human)
simulated function bool IsPlayerPawn()
{
	return ( (Controller != None) && Controller.bIsPlayer );
}

// return true if was controlled by a Player (AI or human)
simulated function bool WasPlayerPawn()
{
	return false;
}

// return true if controlled by a real live human
simulated function bool IsHumanControlled()
{
	return ( PlayerController(Controller) != None );
}

// return true if controlled by local (not network) player
simulated function bool IsLocallyControlled()
{
	if ( Level.NetMode == NM_Standalone )
		return true;
	if ( Controller == None )
		return false;
	if ( PlayerController(Controller) == None )
		return true;

	return ( Viewport(PlayerController(Controller).Player) != None );
}

// return true if viewing this pawn in first person pov. useful for determining what and where to spawn effects
simulated function bool IsFirstPerson()
{
    local PlayerController PC;

    PC = PlayerController(Controller);
    return ( PC != None && !PC.bBehindView && Viewport(PC.Player) != None );
}

simulated function rotator GetViewRotation()
{
	if ( Controller == None )
		return Rotation;
	return Controller.GetViewRotation();
}

#if IG_SWAT
simulated function SetViewLocation(vector NewLocation)
{
	if ( Controller != None )
		Controller.SetLocation(NewLocation);
}
#endif

simulated function SetViewRotation(rotator NewRotation)
{
	if ( Controller != None )
		Controller.SetRotation(NewRotation);
}

// MCJ: added this. It is needed for aiming FiredWeapon on network
// clients. This version should never get called, hence the
// assert(false). Derived classes should override as needed.
simulated function Rotator GetAimRotation()
{
    local Rotator r;
    assert( false );
    return r;
}

simulated function vector GetAimOrigin()
{
	return Location + EyePosition();
}

#if IG_SWAT
//stub for SwatPlayer function.  see comments there.
simulated function vector GetThirdPersonEyesLocation();
#endif

simulated function float GetFireTweenTime()
{
    return 0.0;
}

final function bool InGodMode()
{
	return ( (Controller != None) && Controller.bGodMode );
}

function bool NearMoveTarget()
{
	if ( (Controller == None) || (Controller.MoveTarget == None) )
		return false;

	return ReachedDestination(Controller.MoveTarget);
}

simulated final function bool PressingFire()
{
	return ( (Controller != None) && (Controller.bFire != 0) );
}

simulated final function bool PressingAltFire()
{
	return ( (Controller != None) && (Controller.bAltFire != 0) );
}

function Actor GetMoveTarget()
{
	if ( Controller == None )
		return None;

	return Controller.MoveTarget;
}

function SetMoveTarget(Actor NewTarget )
{
	if ( Controller != None )
		Controller.MoveTarget = NewTarget;
}

native function bool LineOfSightTo(actor Other);

simulated function rotator AdjustAim(Ammunition FiredAmmunition, vector projStart, int aimerror)
{
	if ( Controller == None )
		return Rotation;

	return Controller.AdjustAim(FiredAmmunition, projStart, aimerror);
}

/* return a value (typically 0 to 1) adjusting pawn's perceived strength if under some special influence (like berserk)
*/
function float AdjustedStrength()
{
	return 0;
}

#if !IG_SWAT // ckline: we don't support this
function HandlePickup(Pickup pick)
{
	MakeNoise(0.2);
	if ( Controller != None )
		Controller.HandlePickup(pick);
}
#endif

function ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	if ( PlayerController(Controller) != None )
		PlayerController(Controller).ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
}

event ClientMessage( coerce string S, optional Name Type )
{
	if ( PlayerController(Controller) != None )
		PlayerController(Controller).ClientMessage( S, Type );
}

function Trigger( actor Other, pawn EventInstigator )
{
	if ( Controller != None )
		Controller.Trigger(Other, EventInstigator);
}

//***************************************

function bool CanTrigger(Trigger T)
{
	return true;
}

//TMC removed Epic's Weapon or Inventory code here - functions CreateInventory(),  GiveWeapon()

function SetDisplayProperties(ERenderStyle NewStyle, Material NewTexture, bool bLighting )
{
	Style = NewStyle;
	Texture = NewTexture;
	bUnlit = bLighting;
    //TMC removed
//	if ( Weapon != None )
//		Weapon.SetDisplayProperties(Style, Texture, bUnlit);

	if ( !bUpdatingDisplay && (Inventory != None) )
	{
		bUpdatingDisplay = true;
		Inventory.SetOwnerDisplay();
	}
	bUpdatingDisplay = false;
}

function SetDefaultDisplayProperties()
{
	Style = Default.Style;
	texture = Default.Texture;
	bUnlit = Default.bUnlit;
    //TMC removed
//	if ( Weapon != None )
//		Weapon.SetDefaultDisplayProperties();

	if ( !bUpdatingDisplay && (Inventory != None) )
	{
		bUpdatingDisplay = true;
		Inventory.SetOwnerDisplay();
	}
	bUpdatingDisplay = false;
}

function FinishedInterpolation()
{
	DropToGround();
}

function JumpOutOfWater(vector jumpDir)
{
	Falling();
	Velocity = jumpDir * WaterSpeed;
	Acceleration = jumpDir * AccelRate;
	velocity.Z = FMax(380,JumpZ); //set here so physics uses this for remainder of tick
	bUpAndOut = true;
}

/*
Modify velocity called by physics before applying new velocity
for this tick.

Velocity,Acceleration, etc. have been updated by the physics, but location hasn't
*/
simulated event ModifyVelocity(float DeltaTime, vector OldVelocity);

event FellOutOfWorld(eKillZType KillType)
{
	if ( Role < ROLE_Authority )
		return;
	if ( (Controller != None) && Controller.AvoidCertainDeath() )
		return;
	Health = -1;

	if(KillType == KILLZ_Suicide)
		Died( None, class'Fell', Location
#if IG_SWAT
             ,vect(0,0,0)
#endif
            );
	else
	{
#if IG_THIS_IS_SHIPPING_VERSION
		log(
#else
		AssertWithDescription(false,
#endif
         "[ckline]: !!!! WARNING !!!!! Pawn "$self$" in base Pawn state and Physics="$GetEnum(EPhysics,Physics)$" fell out of the world and Died()! Pawn's location = "$Location$", look around this area in the editor for gaps in bsp.");

	SetPhysics(PHYS_None);
		Died( None, class'Fell', Location
#if IG_SWAT
             ,vect(0,0,0)
#endif
            );
	}
}

/* ShouldCrouch()
Controller is requesting that pawn crouch
*/
function ShouldCrouch(bool Crouch)
{
	bWantsToCrouch = Crouch;
}

// Stub events called when physics actually allows crouch to begin or end
// use these for changing the animation (if script controlled)
event EndCrouch(float HeightAdjust)
{
	EyeHeight -= HeightAdjust;
	OldZ += HeightAdjust;
	BaseEyeHeight = Default.BaseEyeHeight;
}

event StartCrouch(float HeightAdjust)
{
	EyeHeight += HeightAdjust;
	OldZ -= HeightAdjust;
	BaseEyeHeight = CrouchEyeHeight;
}

#if IG_SWAT

native function Lean(ELeanState inLeanState);
native function UnLean();

function ShouldLeanLeft(bool Lean)
{
    bWantsToLeanLeft = Lean;
}

function ShouldLeanRight(bool Lean)
{
    bWantsToLeanRight = Lean;
}

// Called by engine right after the pawn's LeanState member has changed value
event OnLeanStateChange();

native function GetLeanYawRanges(out int leftYawLimit, out int rightYawLimit);

// Returns true if the lean direction is unobstructed at the specified pawn
// location and rotation
native function bool CanLean(ELeanState inLeanState, vector testLocation, rotator testRotation);
#endif

function RestartPlayer();
function AddVelocity( vector NewVelocity)
{
	if ( bIgnoreForces || (NewVelocity == vect(0,0,0)) )
		return;
    // In SWAT, we don't want to change the physics to falling when someone
    // gets shot. We also want to zero out the Z component of the velocity,
    // so that our characters are not lifted off the floor (otherwise, when
    // crouching and getting shot, the character will stand up briefly).
    // [darren]
#if IG_SWAT
    NewVelocity.Z = 0.0;
#else
	if ( (Physics == PHYS_Walking)
		|| (((Physics == PHYS_Ladder) || (Physics == PHYS_Spider)) && (NewVelocity.Z > Default.JumpZ)) )
		SetPhysics(PHYS_Falling);
#endif
	if ( (Velocity.Z > 380) && (NewVelocity.Z > 0) )
		NewVelocity.Z *= 0.5;
	Velocity += NewVelocity;
}

function KilledBy( pawn EventInstigator )
{
	local Controller Killer;

	Health = 0;
	if ( EventInstigator != None )
		Killer = EventInstigator.Controller;
	Died( Killer, class'Suicided', Location
#if IG_SWAT
         ,vect(0,0,0)
#endif
        );
}

function TakeFallingDamage()
{
	local float Shake, EffectiveSpeed;

	if (Velocity.Z < -0.5 * MaxFallSpeed)
	{
		if ( Role == ROLE_Authority )
		{
		    MakeNoise(1.0);
		    if (Velocity.Z < -1 * MaxFallSpeed)
		    {
			    EffectiveSpeed = Velocity.Z;
			    if ( TouchingWaterVolume() )
					EffectiveSpeed = FMin(0, EffectiveSpeed + 100);
			    if ( EffectiveSpeed < -1 * MaxFallSpeed )
				    TakeDamage(-100 * (EffectiveSpeed + MaxFallSpeed)/MaxFallSpeed, None, Location, vect(0,0,0), class'Fell');
		    }
		}
		        if ( Controller != None )
		        {
			        Shake = FMin(1, -1 * Velocity.Z/MaxFallSpeed);
			        Controller.ShakeView(0.175 + 0.1 * Shake, 850 * Shake, Shake * vect(0,0,1.5), 120000, vect(0,0,10), 1);
		        }
	        }
	else if (Velocity.Z < -1.4 * JumpZ)
		MakeNoise(0.5);
}

function ClientReStart()
{
	Velocity = vect(0,0,0);
	Acceleration = vect(0,0,0);
	BaseEyeHeight = Default.BaseEyeHeight;
	EyeHeight = BaseEyeHeight;
	PlayWaiting();
}

function ClientSetLocation( vector NewLocation, rotator NewRotation )
{
	if ( Controller != None )
		Controller.ClientSetLocation(NewLocation, NewRotation);
}

function ClientSetRotation( rotator NewRotation )
{
	if ( Controller != None )
		Controller.ClientSetRotation(NewRotation);
}

simulated function FaceRotation( rotator NewRotation )
{
#if IG_SWAT // ckline: we don't support this
    if (false) {} // no ladders
#else
	if ( Physics == PHYS_Ladder )
		SetRotation(OnLadder.Walldir);
#endif
	else
	{
		if ( (Physics == PHYS_Walking) || (Physics == PHYS_Falling) )
			NewRotation.Pitch = 0;
		SetRotation(NewRotation);
	}
}

#if IG_SWAT
function ClientDying(class<DamageType> DamageType, vector HitLocation, vector HitMomentum, vector inKillerLocation)
#else
function ClientDying(class<DamageType> DamageType, vector HitLocation)
#endif
{
	if ( Controller != None )
#if IG_SWAT
		Controller.ClientDying(DamageType, HitLocation, HitMomentum, inKillerLocation);
#else
		Controller.ClientDying(DamageType, HitLocation);
#endif
}

function bool InCurrentCombo()
{
	return false;
}

//TMC removed Epic's Weapon or Inventory code here - functions
//CanThrowWeapon(), NextItem(), FindInventoryType(), AddInventory(),
//DeleteInventory(), ChangedWeapon(), GetWeaponBoneFor(),
//ServerChangedWeapon()

// Executes only on the server.
// Override in derived class (SwatPawn).
function ServerRequestEquip( EquipmentSlot Slot );


// Override in derived class (SwatPlayer).
simulated function bool ValidateEquipSlot( EquipmentSlot Slot )
	{
    assert( false );
			return false;
	}


//==============
// Encroachment
event bool EncroachingOn( actor Other )
{
	if ( Other.bWorldGeometry )
		return true;

	if ( ((Controller == None) || !Controller.bIsPlayer || bWarping) && (Pawn(Other) != None) )
		return true;

	return false;
}

event EncroachedBy( actor Other )
{
#if !IG_SWAT // ckline: removed unreal classes not needed for SWAT
	// Allow encroachment by Vehicles so they can push the pawn out of the way
	if ( Pawn(Other) != None && Vehicle(Other) == None )
		gibbedBy(Other);
#endif
}

#if !IG_SWAT // ckline: removed unreal classes not needed for SWAT
function gibbedBy(actor Other)
{
	if ( Role < ROLE_Authority )
		return;
	if ( Pawn(Other) != None )
		Died(Pawn(Other).Controller, class'DamTypeTelefragged', Location);
	else
		Died(None, class'Gibbed', Location);
}
#endif

//Base change - if new base is pawn or decoration, damage based on relative mass and old velocity
// Also, non-players will jump off pawns immediately
function JumpOffPawn()
{
	Velocity += (100 + CollisionRadius) * VRand();
	Velocity.Z = 200 + CollisionHeight;
	SetPhysics(PHYS_Falling);
	bNoJumpAdjust = true;
	Controller.SetFall();
}

singular event BaseChange()
{
	local float decorMass;

	if ( bInterpolating )
		return;
	if ( (base == None) && (Physics == PHYS_None) )
		SetPhysics(PHYS_Falling);
	// Pawns can only set base to non-pawns, or pawns which specifically allow it.
	// Otherwise we do some damage and jump off.
	else if ( Pawn(Base) != None )
	{
		if ( !Pawn(Base).bCanBeBaseForPawns )
		{
#if ! IG_SWAT	// don't take damage if we have a pawn as our base [crombie]
			Base.TakeDamage( (1-Velocity.Z/400)* Mass/Base.Mass, Self,Location,0.5 * Velocity , class'Crushed');
#endif
			JumpOffPawn();
		}
	}
	else if ( (Decoration(Base) != None) && (Velocity.Z < -400) )
	{
		decorMass = FMax(Decoration(Base).Mass, 1);
		Base.TakeDamage((-2* Mass/decorMass * Velocity.Z/400), Self, Location, 0.5 * Velocity, class'Crushed');
	}
}

event UpdateEyeHeight( float DeltaTime )
{
	local float smooth, MaxEyeHeight;
	local float OldEyeHeight;
	local Actor HitActor;
	local vector HitLocation,HitNormal;

	if (Controller == None )
	{
		EyeHeight = 0;
		return;
	}
	if ( bTearOff )
	{
		EyeHeight = 0;
		bUpdateEyeHeight = false;
		return;
	}
	HitActor = trace(HitLocation,HitNormal,Location + (CollisionHeight + MAXSTEPHEIGHT + 14) * vect(0,0,1),
					Location + CollisionHeight * vect(0,0,1),true);
	if ( HitActor == None )
		MaxEyeHeight = CollisionHeight + MAXSTEPHEIGHT;
	else
		MaxEyeHeight = HitLocation.Z - Location.Z - 14;

	// smooth up/down stairs
	smooth = FMin(1.0, 10.0 * DeltaTime/Level.TimeDilation);
	If( Controller.WantsSmoothedView() )
	{
		OldEyeHeight = EyeHeight;
		EyeHeight = FClamp((EyeHeight - Location.Z + OldZ) * (1 - smooth) + BaseEyeHeight * smooth,
							-0.5 * CollisionHeight, MaxEyeheight);
	}
	else
	{
		bJustLanded = false;
		EyeHeight = FMin(EyeHeight * ( 1 - smooth) + BaseEyeHeight * smooth, MaxEyeHeight);
	}
	Controller.AdjustView(DeltaTime);
}

/* EyePosition()
Called by PlayerController to determine camera position in first person view.  Returns
the offset from the Pawn's location at which to place the camera
*/
#if IG_SWAT
native function vector EyePosition();
#else
simulated function vector EyePosition()
{
	return EyeHeight * vect(0,0,1) + WalkBob;
}
#endif

#if IG_SWAT
native function AddViewablePawn(Pawn NewViewablePawn);
#endif

#if IG_SWAT
// The alpha (0-1 value) of the yaw edge for the current pitch. The more
// extreme the pitch, the less the pawns can yaw aim left or right. This
// is due to a limitation in normal animation channel blending.
native function float GetYawEdgeAlpha(int pitch);
#endif

//=============================================================================

simulated event Destroyed()
{
#if IG_SWAT
    local int i;

    // If moving through a specific door, remove ourselves from the door's
    // array of pawns moving through it
    if (MovingThroughDoor != None)
    {
        for (i = 0; i < MovingThroughDoor.CurrentlyMovingThroughDoor.length; ++i)
        {
            if (MovingThroughDoor.CurrentlyMovingThroughDoor[i] == self)
            {
                MovingThroughDoor.CurrentlyMovingThroughDoor.remove(i, 1);
                break;
            }
        }

        MovingThroughDoor = None;
    }
#endif

#if IG_SHARED // ckline: notifications upon Pawn death and Actor destruction
	// it's possible the pawn was destroyed and never got Died() called on it,
	// (e.g., with the 'Killall' console command) so we'll notify here just in case.
	NotifyPawnDeathListeners();
#endif

	// remove the Pawn from the Level's Pawn list
    RemovePawn();

	if ( Shadow != None )
		Shadow.Destroy();
	if ( Controller != None )
		Controller.PawnDied(self);

    // MCJ: I'm pretty sure that Epic's code had a bug here. They returned at
    // this point if NM_Client. That prevents the Inventory from getting
    // destroyed on clients (and rightly so) but also prevents
    // Super.Destroyed() from getting called. Since Irrational's codebase
    // actually does something in Actor.Destroyed(), we really do need to call
    // it. I've fixed the problem by wrapping the Inventory stuff in an
    // if-statement.
	if ( Level.NetMode != NM_Client )
    {
	while ( Inventory != None )
		Inventory.Destroy();
    }

	SetActiveItem(None);
    DestroyEquipment();

	Super.Destroyed();
}

//=============================================================================
//
// Called immediately before gameplay begins.
//
#if IG_SWAT // Make prebeginplay simulated so it runs on clients.  This ensures that the skeletal regions are correctly initialized on all clients
simulated
#endif
event PreBeginPlay()
{
	Super.PreBeginPlay();

#if IG_SWAT
    KillerLocation.X = 0;
    KillerLocation.Y = 0;
    KillerLocation.Z = kInvalidKillerLocationZ;
#endif

	Instigator = self;
	DesiredRotation = Rotation;
	if ( bDeleteMe )
		return;

	if ( BaseEyeHeight == 0 )
		BaseEyeHeight = 0.8 * CollisionHeight;
	EyeHeight = BaseEyeHeight;

	if ( menuname == "" )
		menuname = GetItemName(string(class));

#if IG_SHARED
#if IG_SWAT // Carlos: Only addpawn on servers and in standalone, the pawnlist should be empty on clients
    if ( Level.NetMode != NM_Client )
#endif // IG_SWAT
	AddPawn();
#endif  // IG_SHARED

#if IG_SWAT
    InitSkeletalRegions();
#endif
}

#if IG_SWAT
// these are all called after resource creation but before the resource initialization
function CharacterAICreated();
function MovementAICreated();
function WeaponAICreated();
#endif

#if IG_SWAT
native function bool IsInRoom(name RoomName);
native function name GetRoomName();

native function float GetPathfindingDistanceToActor(Actor Destination, optional bool bAcceptNearbyPath);
native function float GetPathfindingDistanceToPoint(vector Point, optional bool bAcceptNearbyPath);

simulated event bool IsStunned() { return false; }
#endif

event PostBeginPlay()
{
#if !IG_SWAT // we don't support AIScript
	local AIScript A;
#endif

	Super.PostBeginPlay();
	SplashTime = 0;
	SpawnTime = Level.TimeSeconds;
	EyeHeight = BaseEyeHeight;
	OldRotYaw = Rotation.Yaw;

#if IG_SWAT // crombie: SWAT-specific Tyrion resource initialization

    // MCJ: the test for IsHumanControlled() below doesn't work; in
    // PostBeginPlay() the Pawn hasn't been possessed yet.
    // All these IG_SWAT changes busted network games. I'm exiting early here
    // if this is a NetPlayer.
    if ( Level.NetMode != NM_Standalone && !Level.IsCOOPServer )
        return;

    // if we're an AI, create the Tyrion code
    if (! IsHumanControlled() && Level.NetMode != NM_Client )
	{
	// Since resources (objects) don't have PostBeginPlay functions, initialize them here explicitly
		characterAI = new class<Tyrion_ResourceBase>( DynamicLoadObject( "SwatAICommon.SwatCharacterResource", class'Class'));
		assert(characterAI != None);
		characterAI.SetResourceOwner( self );
        CharacterAICreated();

		movementAI = new class<Tyrion_ResourceBase>( DynamicLoadObject( "SwatAICommon.SwatMovementResource", class'Class'));
		assert(movementAI != None);
		movementAI.SetResourceOwner( self );
        MovementAICreated();

		weaponAI = new class<Tyrion_ResourceBase>( DynamicLoadObject( "Tyrion.AI_WeaponResource", class'Class'));
		assert(weaponAI != None);
		weaponAI.SetResourceOwner( self );
        WeaponAICreated();

		// create the collision avoidance notifier
		CreateCollisionAvoidanceNotifier();
	}
#endif

#if IG_SWAT
	// Add controllers to all pawns
	if ( (Health > 0) && !bDontPossess )
#else
	// automatically add controller to pawns which were placed in level
	// NOTE: pawns spawned during gameplay are not automatically possessed by a controller
	if ( Level.bStartup && (Health > 0) && !bDontPossess )
#endif
	{

#if IG_SWAT // use ControllerClassName instead of ControllerClass, and don't support AIScript
        if ( (Controller == None) && ControllerClassName != "" )
	    {
            Controller = spawn(class<Controller>( DynamicLoadObject( ControllerClassName, class'Class')));

            assertWithDescription(Controller != None, "Couldn't spawn controller of class "$ControllerClassName$" for "$self);
	    }

        if ( Controller != None )
	{
			Controller.Possess(self);
		}
#else // not SWAT
		// check if I have an AI Script
		if ( AIScriptTag != '' )
		{
			ForEach AllActors(class'AIScript',A,AIScriptTag)
				break;
			// let the AIScript spawn and init my controller
			if ( A != None )
			{
				A.SpawnControllerFor(self);
				if ( Controller != None )
					return;
			}
		}
		if ( (ControllerClass != None) && (Controller == None) )
		{
			Controller = spawn(ControllerClass);
			assert(Controller != None);
		}
		if ( Controller != None )
		{
			Controller.Possess(self);
			AIController(Controller).Skill += SkillModifier;
		}
#endif
	}
}

#if IG_SWAT
function CreateCollisionAvoidanceNotifier()
{
	CollisionAvoidanceNotifier = new class'CollisionAvoidanceNotifier'(self);
	assert(CollisionAvoidanceNotifier != None);
}

function bool IsAvoidingCollision()
{
	return bAvoidingCollision;
}

function RegisterCollisionAvoidanceNotification(ICollisionAvoidanceNotification Registrant)
{
    CollisionAvoidanceNotifier.RegisterCollisionAvoidanceNotification(Registrant);
}

function UnregisterCollisionAvoidanceNotification(ICollisionAvoidanceNotification Registrant)
{
    CollisionAvoidanceNotifier.UnregisterCollisionAvoidanceNotification(Registrant);
}

event NotifyBeganCollisionAvoidance()
{
	CollisionAvoidanceNotifier.NotifyBeganCollisionAvoidance();
}

event NotifyEndedCollisionAvoidance()
{
	CollisionAvoidanceNotifier.NotifyEndedCollisionAvoidance();
}

function float GetCollisionSoftRadius()
{
    return CollisionRadius + CollisionSoftRadiusOffset;
}

simulated function InitSkeletalRegions()
{
    local int ct;

    for ( ct = 0; ct < ESkeletalRegion.REGION_Body_Max; ct ++ )
    {
        SkeletalRegionInformation[ct] = new(None, GetEnum(ESkeletalRegion, ct) $ "Info", 0) class'SkeletalRegionInformation';
        //log("Pawn: SkeletalRegionInformation["$ct$"] spawned a SkeletalRegion with name: "$SkeletalRegionInformation[ct].Name$", damage modifier is: "$SkeletalRegionInformation[ct].DamageModifier);
    }
}

simulated final function SwitchToMesh(Mesh NewMesh)
{
    LinkMesh(NewMesh);

    OnMeshChanged();
}
simulated function OnMeshChanged();

//
//ICanUseProtectiveEquipment implmentation
//

simulated function SetProtection(ESkeletalRegion Region, ProtectiveEquipment Protection)
{
    SkeletalRegionProtection[int(Region)] = Protection;
}

simulated function bool HasProtection(name ProtectionClass)
{
    local int i;

    for (i=0; i<SkeletalRegionProtection.length; ++i)
        if (SkeletalRegionProtection[i] != None && SkeletalRegionProtection[i].IsA(ProtectionClass))
            return true;

    return false;
}

simulated function SkeletalRegionInformation GetSkeletalRegionInformation(ESkeletalRegion Region)
{
    return SkeletalRegionInformation[int(Region)];
}

simulated function ProtectiveEquipment GetSkeletalRegionProtection(ESkeletalRegion Region)
{
    if (SkeletalRegionProtection.length > int(Region))
        return SkeletalRegionProtection[int(Region)];
    else
        return None;
}

simulated function OnSkeletalRegionHit(ESkeletalRegion RegionHit, vector HitLocation, vector HitNormal, int Damage, class<DamageType> DamageType, Actor Instigator);

#endif // IG_SWAT

function InitializeHands();
simulated final function Hands GetHands() { return Hands; }
simulated final function SetHands(Hands inHands) { Hands = inHands; }   //TMC TODO just set in SwatPlayer when protected works between packages

// called after PostBeginPlay on net client
simulated event PostNetBeginPlay()
{
	if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
#if IG_SWAT // ckline: better lighting on characters
    MaxLights = Min(4,MaxLights);
#else
    MaxLights = Min(4,MaxLights);
#endif

	if ( Role == ROLE_Authority )
		return;
	if ( Controller != None )
	{
		Controller.Pawn = self;
		if ( (PlayerController(Controller) != None)
			&& (PlayerController(Controller).ViewTarget == Controller) )
			PlayerController(Controller).SetViewTarget(self);
	}

	if ( Role == ROLE_AutonomousProxy )
		bUpdateEyeHeight = true;

	if ( (PlayerReplicationInfo != None)
		&& (PlayerReplicationInfo.Owner == None) )
		PlayerReplicationInfo.SetOwner(Controller);
	PlayWaiting();
}

#if IG_SHARED // karl: Fix for savegames
event PostLoadGame()
{
	bInitializeAnimation = false;
	PlayWaiting();
}
#endif

simulated function SetMesh()
{
    if (Mesh != None)
        return;

	LinkMesh( default.mesh );
}

function Gasp();
function SetMovementPhysics();

#if IG_SWAT
// Subclasses should override completely
native event float GetAdditionalBaseAimError();
function float GetInjuredAimErrorPenalty() { return 0.0; }
#endif

#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
function PostTakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
						Vector momentum, class<DamageType> damageType)
#else
function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
						Vector momentum, class<DamageType> damageType)
#endif
{
	local int actualDamage;
	local bool bAlreadyDead;
	local Controller Killer;

    //log( "............Pawn::TakeDamage() called." );

	if ( damagetype == None )
	{
		if ( InstigatedBy != None )
		Log("WARNING: No damagetype for damage by "$instigatedby);  //TMC $" with weapon "$InstigatedBy.Weapon);
		DamageType = class'DamageType';
	}

	if ( Role < ROLE_Authority )
	{
		log(self$" took client damage of type "$damageType$" by "$instigatedBy);
		return;
	}

    // ------ CLIENTS NEVER GET BELOW HERE --------

	bAlreadyDead = (Health <= 0);

	if (Physics == PHYS_None)
		SetMovementPhysics();

#if 0 // ckline: this screws up the momentum passed to PlayDying, so I disabled it
    if (Physics == PHYS_Walking)
		momentum.Z = FMax(momentum.Z, 0.4 * VSize(momentum));
	if ( (instigatedBy == self)
		|| ((Controller != None) && (InstigatedBy != None) && (InstigatedBy.Controller != None) && InstigatedBy.Controller.SameTeamAs(Controller)) )
		momentum *= 0.6;
	momentum = momentum/Mass;
#endif

	actualDamage = Level.Game.ReduceDamage(Damage, self, instigatedBy, HitLocation, Momentum, DamageType);

	Health -= actualDamage;
	if ( HitLocation == vect(0,0,0) )
		HitLocation = Location;
	if ( bAlreadyDead )
	{
		Log("WARNING: "$self$" took regular damage "$damagetype$" from "$instigatedby$" while already dead at "$Level.TimeSeconds);
		ChunkUp(Rotation, DamageType);
		return;
	}

	PlayHit(actualDamage,InstigatedBy, hitLocation, damageType, Momentum);
	if ( Health <= 0 )
	{
		// pawn died
		if ( instigatedBy != None )
        {
            Killer = instigatedBy.GetKillerController();

            // ckline: warn in cases where killer can't be determined...
            // helps debug "accessed none" errors in GameInfo.NotifyKilled()
            if (Killer == None)
            {
                Log("WARNING: could not determine killer of "$self$" (instigatedBy=='"$instigatedBy$"')");
                mpLog("---------Using the cached playerpawn");
#if IG_SWAT
				// This is a valid pawn that instigated this, so make sure and grab the correct controller, even if the instigator was killed
                Killer = instigatedBy.LastUnPossessedController;
#endif
            }
        }
        //log( ".......about to call Pawn::Died()." );
		Died(Killer, damageType, HitLocation, Momentum);
	}
	else
	{
		if ( (InstigatedBy != None) && (InstigatedBy != self) && (Controller != None)
			&& (InstigatedBy.Controller != None) && InstigatedBy.Controller.SameTeamAs(Controller) )
			Momentum *= 0.5;

#if !IG_SWAT // ckline: this causes pawns to get moved when shot, which looks dumb
		AddVelocity( momentum );
#endif
		if ( Controller != None )
			Controller.NotifyTakeHit(instigatedBy, HitLocation, actualDamage, DamageType, Momentum);
	}
	MakeNoise(1.0);
}

function TeamInfo GetTeam()
{
	if ( PlayerReplicationInfo != None )
		return PlayerReplicationInfo.Team;
	return None;
}

function Controller GetKillerController()
{
	return Controller;
}

#if IG_SHARED // ckline: notifications upon Pawn death and Actor destruction
// Notify anyone who registered with the LevelInfo for pawn death notification.
// It is safe to call this multiple times on the same Pawn; the function
// automatically handles this so that listeners are only notified once.
native function NotifyPawnDeathListeners();
#endif

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum)
{
#if IG_SWAT
    local Vector LocalKillerLocation;
#endif
    //local Vector TossVel;

    //log( ".....in Pawn::Died().1" );

	if ( bDeleteMe || Level.bLevelChange )
		return; // already destroyed, or level is being cleaned up

	// mutator hook to prevent deaths
	// WARNING - don't prevent bot suicides - they suicide when really needed
	if ( Level.Game.PreventDeath(self, Killer, damageType, HitLocation) )
	{
		Health = max(Health, 1); //mutator should set this higher
		return;
	}
	Health = Min(0, Health);

#if IG_SHARED // ckline: notifications upon Pawn death and Actor destruction
	NotifyPawnDeathListeners();
#endif

	if ( Controller != None )
	{
	    Level.Game.Killed(Killer, Controller, self, damageType);
        Controller.WasKilledBy(Killer);
	}
	else
		Level.Game.Killed(Killer, Controller(Owner), self, damageType);

	if ( Killer != None )
		TriggerEvent(Event, self, Killer.Pawn);
	else
		TriggerEvent(Event, self, None);

	Velocity.Z *= 1.3;
	if ( IsHumanControlled() )
		PlayerController(Controller).ForceDeathUpdate();
#if IG_SWAT    //tcohen: changed DamageType
	if (false) { }
#else
	if ( (DamageType != None) && DamageType.default.bAlwaysGibs )
		ChunkUp( Rotation, DamageType );
#endif
	else
	{
#if IG_SWAT
        // Calculate the killer's location, using a variety of means
        if (Killer != None)
        {
            if (Killer.Pawn != None)
            {
                LocalKillerLocation = Killer.Pawn.Location;
            }
            else
            {
                LocalKillerLocation = Killer.Location;
            }
        }
        else
        {
            // Just use whatever the value of the KillerLocation member is as
            // a catch-all
            LocalKillerLocation = KillerLocation;
        }

		PlayDying(DamageType, HitLocation, HitMomentum, LocalKillerLocation);
#else
		PlayDying(DamageType, HitLocation);
#endif
		if ( Level.Game.bGameEnded )
			return;
        if ( !bPhysicsAnimUpdate && !IsLocallyControlled() )
        {
#if IG_SWAT
            ClientDying(DamageType, HitLocation, HitMomentum, LocalKillerLocation);
#else
            ClientDying(DamageType, HitLocation);
#endif
        }
    }
}

#if !IG_SWAT // ckline: removed unreal classes not needed for SWAT
function bool Gibbed(class<DamageType> damageType)
{
	if ( damageType.default.GibModifier == 0 )
		return false;
	if ( damageType.default.GibModifier >= 100 )
		return true;
	if ( (Health < -80) || ((Health < -40) && (FRand() < 0.6)) )
		return true;
	return false;
}
#endif

#if IG_SHARED	// marc: used for Tyrion object termination/cleanup
static final function bool checkAlive( Pawn pawn )
{
	return pawn != None && !pawn.bDeleteMe && pawn.Health > 0;
}
#endif

#if IG_SHARED	// marc: used for Tyrion object termination/cleanup
static final function bool checkDead( Pawn pawn )
{
	return pawn == None || pawn.bDeleteMe || pawn.Health <= 0;
}
#endif

#if IG_SWAT
static final function bool checkIsAThreat( Pawn pawn )
{
	return pawn != None && !pawn.bDeleteMe && pawn.IsAThreat();
}

// Special Swat check that let's us know if the guy is alive and not incapacitated
static final function bool checkConscious( Pawn pawn )
{
	return  pawn != None && !pawn.IsDead() && !pawn.IsIncapacitated();
}

// returns true if bDeleteMe or Health == 0
simulated native function bool IsDead();

// returns true if !bDeleteMe, (Health > 0), and !IsIncapacitated
simulated native function bool IsConscious();

// needed in Pawn because Tyrion checks to see if we are incapacitated
simulated native function bool IsIncapacitated();

function float GetIncapacitatedDamageAmount()
{
	return 0.0;
}

function bool ShouldBecomeIncapacitated()
{
	return ((Health >= 0) && (Health < GetIncapacitatedDamageAmount()));
}

simulated event bool IsArrested()					{ assert(false); return false; }
event Pawn GetCurrentAssignment()		{ assert(false); return None;  }
#endif

#if IG_SHARED	// marc: call !isAlive() to check for death (because a script-side "isDead" may return 0 when bDeleteMe is set)
simulated event bool isAlive()
{
	return !bDeleteMe && Health > 0;
}
#endif

#if IG_SHARED
simulated native event bool IsInjured();

static final function bool checkIsInjured( Pawn pawn )
{
	return pawn != None && !pawn.bDeleteMe && Pawn.IsInjured();
}
#endif

#if IG_SWAT
simulated native event bool IsLowerBodyInjured();    //override in subclasses

event bool CanMoveFreely()
{
	return true;
}

simulated native function bool IsAThreat();
simulated native function bool IsCompliant();

function bool IsAttackingPlayer()
{
	return false;
}
#endif

#if IG_SHARED	// marc: cause all resources attached to this pawn to re-check their goals
function rematchGoals();
#endif

event Falling()
{
	//SetPhysics(PHYS_Falling); //Note - physics changes type to PHYS_Falling by default
	if ( Controller != None )
		Controller.SetFall();
}

event HitWall(vector HitNormal, actor Wall);

event Landed(vector HitNormal)
{
	LandBob = FMin(50, 0.055 * Velocity.Z);
	TakeFallingDamage();
	if ( Health > 0 )
		PlayLanded(Velocity.Z);
	bJustLanded = true;
#if IG_EFFECTS
    TriggerEffectEvent('Landed');
#endif
}

event HeadVolumeChange(PhysicsVolume newHeadVolume);

function bool TouchingWaterVolume()
{
	local PhysicsVolume V;

	ForEach TouchingActors(class'PhysicsVolume',V)
		if ( V.bWaterVolume )
			return true;

	return false;
}

#if IG_SWAT
function EnteredZone(ZoneInfo Zone)
{
	SLog(self $ " entered zone " $ Zone);
	dispatchMessage(new class'MessageZoneEntered'(Zone.label, label));

    TriggerEffectEvent('InZone');
}

function LeftZone(ZoneInfo Zone)
{
	SLog(self $ " leaving zone " $ Zone);
	dispatchMessage(new class'MessageZoneExited'(Zone.label, label));

    UnTriggerEffectEvent('InZone');
}
#endif

//Pain timer just expired.
//Check what zone I'm in (and which parts are)
//based on that cause damage

function bool IsInPain()
{
#if !IG_SWAT    //tcohen: changed DamageType
	local PhysicsVolume V;

	ForEach TouchingActors(class'PhysicsVolume',V)
		if ( V.bPainCausing && (V.DamageType != ReducedDamageType)
			&& (V.DamagePerSec > 0) )
			return true;
#endif
	return false;
}

function TakeDrowningDamage();

function bool CheckWaterJump(out vector WallNormal)
{
#if !IG_SWAT // ckline: disable jumping
	local actor HitActor;
	local vector HitLocation, HitNormal, checkpoint, start, checkNorm, Extent;

	checkpoint = vector(Rotation);
	checkpoint.Z = 0.0;
	checkNorm = Normal(checkpoint);
	checkPoint = Location + CollisionRadius * checkNorm;
	Extent = CollisionRadius * vect(1,1,0);
	Extent.Z = CollisionHeight;
	HitActor = Trace(HitLocation, HitNormal, checkpoint, Location, true, Extent);
	if ( (HitActor != None) && (Pawn(HitActor) == None) )
	{
		WallNormal = -1 * HitNormal;
		start = Location;
		start.Z += 1.1 * MAXSTEPHEIGHT;
		checkPoint = start + 2 * CollisionRadius * checkNorm;
		HitActor = Trace(HitLocation, HitNormal, checkpoint, start, true);
		if (HitActor == None)
			return true;
	}
#endif
	return false;
}

function DoDoubleJump( bool bUpdating );
function bool CanDoubleJump();

function bool Dodge(eDoubleClickDir DoubleClickMove)
{
	return false;
}

//Player Jumped
function bool DoJump( bool bUpdating )
{
#if !IG_SWAT // ckline: disable jumping
	if ( !bIsCrouched && !bWantsToCrouch && ((Physics == PHYS_Walking) ||
                                             (Physics == PHYS_Spider)) )
	{
		if ( Role == ROLE_Authority )
		{
			if ( (Level.Game != None) && (Level.Game.GameDifficulty > 2) )
				MakeNoise(0.1 * Level.Game.GameDifficulty);
			if ( bCountJumps && (Inventory != None) )
				Inventory.OwnerEvent('Jumped');
		}
		if ( Physics == PHYS_Spider )
			Velocity = JumpZ * Floor;
		else if ( bIsWalking )
			Velocity.Z = Default.JumpZ;
		else
			Velocity.Z = JumpZ;
		if ( (Base != None) && !Base.bWorldGeometry )
			Velocity.Z += Base.Velocity.Z;
		SetPhysics(PHYS_Falling);
        return true;
	}
#endif
    return false;
}

/* PlayMoverHitSound()
Mover Hit me, play appropriate sound if any
*/
function PlayMoverHitSound();

#if IG_SWAT
// Pawns are only dealt damage by the server
simulated function bool CanBeAffectedByHurtRadius()
{
    return Role == ROLE_Authority;
}
#endif // IG_SWAT

function PlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum)
{
	local PlayerController PC;

	if ( (Damage <= 0) && ((Controller == None) || !Controller.bGodMode) )
		return;

	// jdf ---
	if ( (Level.NetMode != NM_DedicatedServer) && (Level.NetMode != NM_ListenServer) )
	{
		PC = PlayerController(Controller);
		if ( PC != None && PC.bEnableDamageForceFeedback )
			PC.ClientPlayForceFeedback("Damage");
	}
	// --- jdf
}

/*
Pawn was killed - detach any controller, and die
*/

// blow up into little pieces (implemented in subclass)

simulated function ChunkUp( Rotator HitRotation, class<DamageType> D )
{
	if ( (Level.NetMode != NM_Client) && (Controller != None) )
	{
		if ( Controller.bIsPlayer )
			Controller.PawnDied(self);
		else
#if IG_TRIBES3
			Controller.PawnDied(self);
#else
			Controller.Destroy();
#endif
	}
	destroy();
}

State Dying
{
ignores Trigger, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling;

	event ChangeAnimation() {}
	event StopPlayFiring() {}
	function PlayFiring(float Rate, name FiringMode) {}
	function PlayWeaponSwitch(Weapon NewWeapon) {}
	simulated function PlayNextAnimation() {}

#if IG_SWAT
	function Died(Controller Killer, class<DamageType> damageType, vector HitLocation, vector HitMomentum)
#else
	function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
#endif
	{
	}

	event FellOutOfWorld(eKillZType KillType)
	{
		if(KillType == KILLZ_Suicide )
			return;

#if IG_THIS_IS_SHIPPING_VERSION
        log(
#else
        AssertWithDescription(false,
#endif
            "[ckline]: !!!! WARNING !!!!! Pawn "$self$" in state Pawn.Dying and Physics="$GetEnum(EPhysics,Physics)$" fell out of the world and was Destroy()ed! Pawn's location = "$Location$", look around this area in the editor for gaps in bsp.");

		Destroy();
	}

	function Timer()
	{
		if ( !PlayerCanSeeMe() )
			Destroy();
		else
			SetTimer(2.0, false);
	}

	function Landed(vector HitNormal)
	{
		local rotator finalRot;

		LandBob = FMin(50, 0.055 * Velocity.Z);
		if( Velocity.Z < -500 )
			TakeDamage( (1-Velocity.Z/30),Instigator,Location,vect(0,0,0) , class'Crushed');

		finalRot = Rotation;
		finalRot.Roll = 0;
		finalRot.Pitch = 0;
		setRotation(finalRot);
		SetPhysics(PHYS_None);
		SetCollision(true, false, false);

		if ( !IsAnimating(0) )
			LieStill();
	}

	/* ReduceCylinder() made obsolete by ragdoll deaths */
	function ReduceCylinder()
	{
		SetCollision(false, false, false);
	}

	function LandThump()
	{
		// animation notify - play sound if actually landed, and animation also shows it
		if ( Physics == PHYS_None)
			bThumped = true;
	}

	event AnimEnd(int Channel)
	{
#if !IG_SWAT //dkaplan: we dont really want to do any of this in swat- we dont "Thump", and we dont want to disable collision
		if ( Channel != 0 )
			return;
		if ( Physics == PHYS_None )
			LieStill();
		else if ( PhysicsVolume.bWaterVolume )
		{
			bThumped = true;
			LieStill();
		}
#endif
	}

	function LieStill()
	{
		if ( !bThumped )
			LandThump();
		SetCollision(false, false, false);
	}

	singular function BaseChange()
	{
#if IG_SWAT
        // Only set to PHYS_Falling if Physics are currently none. Otherwise,
        // the pawn can sometimes get ripped out of ragdoll.
		if( (base == None) && (Physics == PHYS_None) )
#else
		if( base == None )
#endif
			SetPhysics(PHYS_Falling);
		else if ( Pawn(base) != None ) // don't let corpse ride around on someone's head
        	ChunkUp( Rotation, class'Fell' );
	}

#if IG_SHARED  //tcohen: hooked TakeDamage(), used by effects system and reactive world objects
	function PostTakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
							Vector momentum, class<DamageType> damageType)
#else
	function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
							Vector momentum, class<DamageType> damageType)
#endif
	{
		SetPhysics(PHYS_Falling);
		if ( (Physics == PHYS_None) && (Momentum.Z < 0) )
			Momentum.Z *= -1;
		Velocity += 3 * momentum/(Mass + 200);
		if ( bInvulnerableBody )
			return;
#if !IG_SWAT    //tcohen: changed DamageType
		Damage *= DamageType.Default.GibModifier;
#endif
		Health -=Damage;
		if ( ((Damage > 30) || !IsAnimating()) && (Health < -80) )
        	ChunkUp( Rotation, DamageType );
	}

	function BeginState()
	{
		if ( (LastStartSpot != None) && (LastStartTime - Level.TimeSeconds < 6) )
			LastStartSpot.LastSpawnCampTime = Level.TimeSeconds;
		if ( bTearOff && (Level.NetMode == NM_DedicatedServer) )
			LifeSpan = 1.0;
		else
			SetTimer(12.0, false);
#if !IG_SWAT
        // Our swat ragdolls transition to havok skeletal physics on their own.
        // Thus this is not needed, and can actually cause problems when killing
        // an already-incapacitated (and therefore ragdolled) pawn.
		SetPhysics(PHYS_Falling);
#endif
		bInvulnerableBody = true;
		if ( Controller != None )
		{
			if ( Controller.bIsPlayer )
				Controller.PawnDied(self);
			else
#if IG_TRIBES3
				Controller.PawnDied(self);
#else
				Controller.Destroy();
#endif
		}
	}

Begin:
	Sleep(0.15);
	bInvulnerableBody = false;
}

//=============================================================================
// Animation interface for controllers

simulated event SetAnimAction(name NewAction);

simulated function PlayRagdoll(class<DamageType> DamageType, vector HitLoc);

/* PlayXXX() function called by controller to play transient animation actions
*/
#if IG_SWAT
simulated event PlayDying(class<DamageType> DamageType, vector HitLoc, vector HitMomentum, vector inKillerLocation)
#else
simulated event PlayDying(class<DamageType> DamageType, vector HitLoc)
#endif
{
    mplog( self$"---Pawn::PlayDying()." );

#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
	AmbientSound = None;
#endif

    // MCJ: this is not executed because SwatRagdollPawn's PlayDying() doesn't
    // call super.PlayDying(). Ask ckline or me about it. This will all be
    // cleaned up momentarily.
#if IG_SWAT_INTERRUPT_STATE_SUPPORT //tcohen: support for notifying states before they are interrupted
    mplog( "...calling InterruptState()." );
    InterruptState('Dying');
    Controller.InterruptState('Dying');
#endif
	GotoState('Dying');
	if ( bPhysicsAnimUpdate )
	{
		bReplicateMovement = false;
		bTearOff = true;  // Setting bTearOff is used to make sure that pawns on remote clients become dead as soon as they become relevant
		Velocity += DeathHitMomentum;
		SetPhysics(PHYS_Falling);
	}
	bPlayedDeath = true;
}

//=============================================================================
// Pawn internal animation functions

simulated event ChangeAnimation()
{
	if ( (Controller != None) && Controller.bControlAnimations )
		return;
	// player animation - set up new idle and moving animations
	PlayWaiting();
	PlayMoving();
}

simulated event AnimEnd(int Channel)
{
	if ( Channel == 0 )
		PlayWaiting();
}

// Animation group checks (usually implemented in subclass)

function bool CannotJumpNow()
{
	return false;
}

simulated event PlayJump();
simulated event PlayFalling();
simulated function PlayMoving();
simulated function PlayWaiting();

function PlayLanded(float impactVel)
{
	if ( !bPhysicsAnimUpdate )
		PlayLandingAnimation(impactvel);
}

simulated event PlayLandingAnimation(float ImpactVel);

#if !IG_SWAT // ckline: we don't support this
function PlayVictoryAnimation();
function HoldCarriedObject(CarriedObject O, name AttachmentBone);
#endif

simulated function Pocket GetDesiredItemPocket()
{
    return DesiredItemPocket;
}

// Only the server should call this.
function SetDesiredItemPocket( Pocket NewPocket )
{
    assert( Role == ROLE_Authority );
    DesiredItemPocket = NewPocket;
}

// override in derived class if necessary.
simulated event DesiredItemPocketChanged();


//TMC I expect this to ONLY be called by a subclass's
//  implementation of OnEquipKeyFrame() and OnUnequipKeyFrame().
//  (Okay, maybe OnActiveItemThrown() too when that's added.)
simulated final protected function SetActiveItem(HandheldEquipment inActiveItem)
{
//    log( "Pawn::SetActiveItem(), new active item="$inActiveItem );
    ActiveItem = inActiveItem;
}

//TMC I expect this to ONLY be called by HandheldEquipment::DoEquipping()
simulated final function SetPendingItem(HandheldEquipment inPendingItem)
{
    PendingItem = inPendingItem;
}

//
//ICanHoldEquipment implementation
//

native simulated function HandheldEquipment GetActiveItem();

//The PendingItem is the item that will be equipped as soon as
//  the ActiveItem is finished being UnEquipped.
//This may change while the ActiveItem is being UnEquipped
//  (for example, if the player presses another equip key).
simulated function HandheldEquipment GetPendingItem()
{
    return PendingItem;
}

//These notifications are called by their respective AnimNotifys
//  when an animation playing on the ICanHoldEquipment reaches
//  a key frame in the animation.
//The ICanHoldEquipment will do some work and it will forward
//  the notification to its ActiveItem.

simulated final function OnEquipKeyFrame()
{
    // MCJ: In COOP, the server plays the equip animation for the IAmCuffed
    // and this animation is replicated to the clients. As a result, on the
    // client the AnimNotify for OnEquipKeyFrame fires, but this is spurious
    // since the equipping is done solely on the server and the third person
    // model for the IAmCuffed is replicated attached to the socket once the
    // arresting finishes. The upshot of this is that on clients in Coop for
    // the IAmCuffed, they don't actually have a PendingItem and all this code
    // below just gives us Accessed Nones. I'm wrapping it in an if-statement,
    // so nothing happens if there is no pending item.

    if ( Level.NetMode != NM_Client || GetPendingItem() != None )
    {
        //make pending item active (protected call)
        SetActiveItem(GetPendingItem());

        GetActiveItem().OnEquipKeyFrame();

        //allow subclasses to extend functionality
        OnActiveItemEquipped();
    }
}
// Notifications called by OnEquipKeyFrame to let subclasses know that the Active Item has been equipped
simulated function OnActiveItemEquipped();

// This differs from OnActiveItemEquipped() in that this is called, not on the
// key frame, but right before DoEquipping() exits, that is, after all the
// animations are finished playing.
simulated function OnEquippingFinished();

simulated function OnUnequipKeyFrame()
{
    local HandheldEquipment theActiveItem;

    theActiveItem = GetActiveItem();
    if ( theActiveItem != None )
    {
        theActiveItem.OnUnequipKeyFrame();
        OnActiveItemUnEquipped();
        SetActiveItem(None);
    }
}
simulated function OnActiveItemUnEquipped();

simulated function OnUseKeyFrame()
{
    local HandheldEquipment LocalActiveItem;

    LocalActiveItem = GetActiveItem();

    if ( LocalActiveItem != None )
        LocalActiveItem.OnUseKeyFrame();

    if  (   LocalActiveItem != None             //this may be called twice, once for each HanheldEquipmentModel
        &&  LocalActiveItem.UnavailableAfterUsed
        )
    {
        //TMC 11-16-2003 This is unexpected... I expect that
        //  HandheldEquipment::OnUseKeyFrame() just sets Available=false. I
        //  don't want to change it now for fear of messing-up Mike.  But in
        //  the future... I think this should go and be replaced with
        //  LocalActiveItem.SetAvailable( false ).
        //TMC TODO remove this:

        // MCJ: 1-19-2004 It appears that some of our code relies on the
        // LocalActiveItem being destroyed when it is used and
        // UnavailableAfterUsed; specifically, the handheldequipmentmodels
        // don't get destroyed and stay stuck to the sockets they were
        // on. This happens in both MP and standalone. Since there may be
        // other consequences of removing this line, I'll leave it for
        // now. Talk to me before trying to remove it in the future.

        // MCJ: 2-4-2004 We do *not* want to destroy the item here. For
        // thrownweapons, the pawn will still be in the ThrowingFinish state
        // and the weapon will still be in LatentUse(). Bad caca ensues if you
        // destroy the item in a situation like that. I'm commenting out this
        // line and we'll fix the resulting bugs. We probably want to mark the
        // weapon unavailable and do some other stuff here.
        //LocalActiveItem.Destroy();

        // Instead, do this:

        //TMC 2-11-2004 In training, you don't use-up grenades that you throw:

        if (!Level.IsTraining)
        {
            LocalActiveItem.SetAvailable( false );

            SetActiveItem(None);
        }
        else
        {
            //TMC TODO hide thrown grenade in Training
        }
    }
}

simulated function OnUsingBegan();
simulated function OnUsingFinished();
simulated function IWasNonlethaledAndFinishedSoDoAnEquipIfINeedToDoOne();

simulated function OnMeleeKeyFrame()
{
    GetActiveItem().OnMeleeKeyFrame();
}

simulated function OnLightstickKeyFrame()
{
	log("USE LIGHTSTICK");
}

simulated function OnReloadKeyFrame()
{
    FiredWeapon(GetActiveItem()).OnReloadKeyFrame();
}

simulated function OnNVGogglesDownKeyFrame()
{
}

simulated function OnNVGogglesUpKeyFrame()
{
}

// Called once the Reload animation is finished playing.
simulated function OnReloadingFinished();

simulated function IdleHoldingEquipment();

//(end of ICanHoldEquipment implementation)

simulated function DestroyEquipment();

simulated final function AIInterruptEquipment()
{
	local HandheldEquipment ActiveItem, PendingItem;

    ActiveItem  = GetActiveItem();
	PendingItem = GetPendingItem();

	if ((ActiveItem != None) && !ActiveItem.IsIdle())
	{
		ActiveItem.AIInterrupt();
	}

	if ((PendingItem != None) && !PendingItem.IsIdle())
	{
		PendingItem.AIInterrupt();
	}
}

native final function FindAnchor(bool bMustFindAnchor);


// This is an RPC from the client to the server. Override in a derived class.
function ServerBeginFiringWeapon( EquipmentSlot ItemSlot );
function ServerEndFiringWeapon();
function BroadcastEmptyFiredToClients();


function ServerSetCurrentFireMode( EquipmentSlot ItemSlot, FireMode NewFireMode )
{
    local FiredWeapon theActiveItem;

    mplog( self$"---Pawn::ServerSetCurrentFireMode(). ItemSlot="$ItemSlot$", NewFireMode="$NewFireMode );

    theActiveItem = FiredWeapon(GetActiveItem());
    if ( theActiveItem != None && theActiveItem.GetSlot() == ItemSlot )
    {
        theActiveItem.SetCurrentFireMode( NewFireMode );
    }
    else
    {
        mplog( "...SetCurrentFireMode() not possible. ItemSlot="$ItemSlot$", ActiveItem="$GetActiveItem() );
    }
}

simulated function OnFireModeChanged();

// This is an RPC from the client to the server.
function ServerRequestMelee( EquipmentSlot ItemSlot );

// This is an RPC from the client to the server.
function ServerRequestReload( EquipmentSlot ItemSlot );


#if IG_SWAT
//TMC added stub for animation method implemented in SwatPawn for use by Equipment
simulated function int AnimGetSpecialChannel();
simulated function int AnimGetEquipmentChannel();
simulated function int AnimPlaySpecial(Name AnimName, optional float TweenTime, optional name Bone, optional float Rate);
simulated function int AnimPlayEquipment(EAnimPlayType AnimPlayType, Name AnimName, optional float TweenTime, optional name Bone, optional float Rate);
simulated function int AnimLoopSpecial(Name AnimName, optional float TweenTime, optional name Bone, optional float Rate);
simulated function int AnimLoopEquipment(EAnimPlayType AnimPlayType, Name AnimName, optional float TweenTime, optional name Bone, optional float Rate);
simulated function EnableAnimSpecialAlphaOverride(float alpha);
simulated function DisableAnimSpecialAlphaOverride();
simulated function EnableAnimEquipmentAlphaOverride(float alpha);
simulated function DisableAnimEquipmentAlphaOverride();
simulated function AnimStopSpecial();
simulated function AnimStopEquipment();
simulated latent function AnimFinishSpecial();
simulated latent function AnimFinishEquipment();
#endif

#if IG_SWAT
// Irrational Added [darren]
// Collision avoidance functions

// Called by collision avoidance as a request for the pawn to move to the
// specified location.

event OnCollisionAvoidanceMoveTo(vector MoveToLocation);

// tcohen: allow Pawn's condition to affect its view direction

simulated event rotator ViewRotationOffset()
{
    return Rot(0,0,0);
}

simulated function vector ViewLocationOffset(Rotator CameraRotation)
{
    return vect(0,0,0);
}

// tcohen: support for firing modes

simulated function bool WantsToContinueAutoFiring() { assert(false); return false; }    //implement in subclasses
simulated function OnAutoFireStarted();

// tcohen: support for HandheldEquipmentPickups

function HandheldEquipment FindItemForPickupToReplace(HandheldEquipment PickedUp);
//called by the HandheldEquipmentPickup at the moment that Equipping begins
function OnPickedUp(HandheldEquipment PickedUp);
#endif

// ckline: in Pawn so tyrion actions can start ragdoll
simulated event BecomeRagdoll();

#if IG_SWAT //tcohen: hook player's rotation for special effeccts
simulated event ApplyRotationOffset(out Vector Acceleration);
#endif

#if IG_SWAT //dkaplan: stub for evidence used- to be hooked into GameEvents system
function OnEvidenceSecured(IEvidence Evidence);
#endif

#if IG_SWAT_INTERRUPT_STATE_SUPPORT //tcohen: support for notifying states before they are interrupted
simulated function InterruptState(name Reason);
#endif

#if IG_SWAT // dbeswick:
simulated event bool ShouldPlayWalkingAnimations()
{
	return bIsWalking;
}
#endif

defaultproperties
{
	bCanBeDamaged=true
	 bNoRepMesh=true
	 bJumpCapable=true
 	 bCanJump=true
	 bCanWalk=true
	 bCanSwim=false
	 bCanFly=false
	 bUpdateSimulatedPosition=true
	 BaseEyeHeight=+00064.000000
	 CrouchEyeHeight=+00032.00000
     EyeHeight=+00054.000000
     CollisionRadius=+00034.000000
     CollisionHeight=+00078.000000
     GroundSpeed=+00600.000000
     AirSpeed=+00600.000000
     WaterSpeed=+00300.000000
     AccelRate=+02048.000000
     JumpZ=+00420.000000
	 MaxFallSpeed=+1200.0
	 DrawType=DT_Mesh
	 bLOSHearing=true
	 HearingThreshold=+2800.0
     Health=100
     Visibility=128
	 LadderSpeed=+200.0
     noise1time=-00010.000000
     noise2time=-00010.000000
     AvgPhysicsTime=+00000.100000
     SoundDampening=+00001.000000
     DamageScaling=+00001.000000
     bDirectional=True
     bCanTeleport=True
	 bStasis=True
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications
//     SoundRadius=60
//	 SoundVolume=255
//#endif
     bCollideActors=True
     bCollideWorld=True
     bBlockActors=True
     bBlockPlayers=True
     bProjTarget=True
     bRotateToDesired=True
	 bCanCrouch=False
     RotationRate=(Pitch=4096,Yaw=20000,Roll=3072)
	 Texture=Texture'Engine_res.S_Pawn'
     RemoteRole=ROLE_SimulatedProxy
     NetPriority=+00002.000000
	 AirControl=+0.05
	 //ControllerClass=class'AIController'
	 ControllerClassName="Tyrion.AI_Controller"
	 CrouchHeight=+40.0
	 CrouchRadius=+34.0
     LeanState=kLeanStateNone
     MaxDesiredSpeed=+00001.000000
     DesiredSpeed=+00001.000000
 	 LandMovementState=PlayerWalking
	 WaterMovementState=PlayerSwimming
	 SightRadius=+05000.000000
	 bOwnerNoSee=true
	 bAcceptsProjectors=True
	 BlendChangeTime=0.25
	 bTravel=true
	 BaseMovementRate=+525.0
	 ForwardStrafeBias=+0.0
	 BackwardStrafeBias=+0.0
	 bShouldBaseAtStartup=true
     Bob=0.0080
	 bDisturbFluidSurface=true
	 bBlockKarma=False
	 bBlockHavok=False
	 bHavokCharacterCollisions=False
	 bHavokCharacterCollisionExtraRadius=1
	 bWeaponBob=true
	 bUseCompressedPosition=true
	 HeadScale=+1.0
     VisionUpdateRange=(Min=0.1,Max=0.3)
     FirstPersonFOV=+85.0
	 LastValidAnchorTime=-1.0
     bCollisionAvoidanceEnabled=true
	 ReachedDestinationThreshold=8.0
	 bRenderHands=true;

//#if IG_SHARED // ckline: notifications upon Pawn death and Actor destruction
	bNotifiedDeathListeners=false
    bSendDestructionNotification=true
//#endif

//#if IG_SHARED
//	AI_LOD_Level = AILOD_ALWAYS_ON // SWAT doesn't use this
//#endif

//#if IG_SWAT
    LeanTransitionDuration=0.3
    LeanHorizontalDistance=44.0f
    bForceCrouch=false
    DesiredItemPocket=Pocket_Invalid
    HasEquippedFirstItemYet=false
//#endif
//#if IG_SWAT // ckline: better lighting on characters
    MaxLights=4
	bAlwaysUseWalkAimErrorWhenMoving=false
//#endif
}
