//=============================================================================
// NavigationPoint.
//
// NavigationPoints are organized into a network to provide AIControllers 
// the capability of determining paths to arbitrary destinations in a level
//
//=============================================================================
class NavigationPoint extends Actor
	hidecategories(Lighting,LightColor,Karma,Force)
	native;

//------------------------------------------------------------------------------
// NavigationPoint variables
var const array<ReachSpec> PathList; //index of reachspecs (used by C++ Navigation code)
#if IG_SWAT // crombie: in Swat we don't want the designers to set proscribed or forced paths
var name ProscribedPaths[4];	// list of names of NavigationPoints which should never be connected from this path
var name ForcedPaths[4];		// list of names of NavigationPoints which should always be connected from this path
#else
var() name ProscribedPaths[4];	// list of names of NavigationPoints which should never be connected from this path
var() name ForcedPaths[4];		// list of names of NavigationPoints which should always be connected from this path
#endif
var int visitedWeight;
var const int bestPathWeight;
var const NavigationPoint nextNavigationPoint;
var const NavigationPoint nextOrdered;	// for internal use during route searches
var const NavigationPoint prevOrdered;	// for internal use during route searches
var const NavigationPoint previousPath;
var int cost;					// added cost to visit this pathnode
var() int ExtraCost;			// Extra weight added by level designer
var transient int TransientCost;	// added right before a path finding attempt, cleared afterward.
var	transient int FearCost;		// extra weight diminishing over time (used for example, to mark path where bot died)
#if IG_SWAT
var bool bAlreadyVisited;	// internal use (pathfinding code from ut2k4)
#endif
var transient bool bEndPoint;	// used by C++ navigation code
var transient bool bTransientEndPoint; // set right before a path finding attempt, cleared afterward.
var bool taken;					// set when a creature is occupying this spot
var() bool bPropagatesSound;	// this navigation point can be used for sound propagation (around corners)
#if IG_SWAT // crombie: in Swat we don't want designers to set these variables in UnrealEd
var bool bBlocked;			// this path is currently unuseable 
var bool bOneWayPath;			// reachspecs from this path only in the direction the path is facing (180 degrees)
var bool bNeverUseStrafing;	// shouldn't use bAdvancedTactics going to this point
var bool bAlwaysUseStrafing;	// shouldn't use bAdvancedTactics going to this point
#else
var() bool bBlocked;			// this path is currently unuseable 
var() bool bOneWayPath;			// reachspecs from this path only in the direction the path is facing (180 degrees)
var() bool bNeverUseStrafing;	// shouldn't use bAdvancedTactics going to this point
var() bool bAlwaysUseStrafing;	// shouldn't use bAdvancedTactics going to this point
#endif
var const bool bForceNoStrafing;// override any LD changes to bNeverUseStrafing
var const bool bAutoBuilt;		// placed during execution of "PATHS BUILD"
var	bool bSpecialMove;			// if true, pawn will call SuggestMovePreparation() when moving toward this node
var bool bNoAutoConnect;		// don't connect this path to others except with special conditions (used by LiftCenter, for example)
var	const bool	bNotBased;		// used by path builder - if true, no error reported if node doesn't have a valid base
var const bool  bPathsChanged;	// used for incremental path rebuilding in the editor
var bool		bDestinationOnly; // used by path building - means no automatically generated paths are sourced from this node
var	bool		bSourceOnly;	// used by path building - means this node is not the destination of any automatically generated path
var bool		bSpecialForced;	// paths that are forced should call the SpecialCost() and SuggestMovePreparation() functions
var bool		bMustBeReachable;	// used for PathReview code

#if !IG_SWAT // ckline: we don't support pickups
var Pickup	InventoryCache;		// used to point to dropped weapons
#endif
var float	InventoryDist;

#if IG_SWAT

var() private string	  RoomName;			// Designer specified room definitions
var protected name		  InternalRoomName;	// a name (type) version of the room name

struct native VisibleAwarenessPoint
{
    var AwarenessPoint AwarenessPoint;
    // If the visibility of this AwarenessPoint point depends on the state of
    // any doors, those doors will be contained in this array.
    var array<Door> DependsOnDoors;
};

// Each navigation point has a list of awareness points that it has a direct
// line-of-sight to. Used for awareness point vision sensing. [darren]
//var const private array<VisibleAwarenessPoint> VisibleAwarenessPoints;
var private nocopy const array<VisibleAwarenessPoint> VisibleAwarenessPoints;

// Each navigation holds a reference to the closest awareness point that it
// has a direct line-of-sight to. [darren]
var private nocopy AwarenessPoint ClosestAwarenessPoint;
var private nocopy float          ClosestAwarenessPointDistance;

#endif

// IG ckline: last time someone spawned here, used in GameInfo subclasses to
// bias spawning players against spawning in the same spot
var float TimeOfLastSpawn; 

#if IG_SWAT_OCCLUSION  // Carlos: Sound propagation stuff
struct native OcclusionNodeInformation
{
    var Name                  OtherOcclusionNode;           
    var float                 ShortestDistanceTo;
    var array<Door>           DoorsInBetween;
};

var private const array<OcclusionNodeInformation> OcclusionNodes;  
var private const transient Map<Name, OcclusionNodeInformation> OcclusionMap; // Built at runtime from the OcclusionNodes list...

native private function InitOcclusionMap();
#endif // IG_SWAT_OCCLUSION

simulated function PostBeginPlay()
{
	ExtraCost = Max(ExtraCost,0);
	Super.PostBeginPlay();

	// NOTE: will need to do this once we implement co-op MP
	if (Level.NetMode == NM_Standalone
#if IG_SWAT
	    || Level.IsCOOPServer
#endif
	    )
		AddSelfToRoomList();

#if IG_SWAT_OCCLUSION
    InitOcclusionMap();
#endif
}

function AddSelfToRoomList()
{
	if (Level.AIRepo != None)
	{	
		if (InternalRoomName == '')
			InternalRoomName = name(RoomName);

        Level.AIRepo.AddNavigationPointToRoomList(self, InternalRoomName);
    }
}

native function name GetRoomName(Pawn Requester);

event int SpecialCost(Pawn Seeker, ReachSpec Path);

// Accept an actor that has teleported in.
// used for random spawning and initial placement of creatures
event bool Accept( actor Incoming, actor Source )
{
	// Move the actor here.
	taken = Incoming.SetLocation( Location );
	if (taken)
	{
		Incoming.Velocity = vect(0,0,0);
		Incoming.SetRotation(Rotation);
	}
	Incoming.PlayTeleportEffect(true, false);
	TriggerEvent(Event, self, Pawn(Incoming));
	return taken;
}

/* DetourWeight()
value of this path to take a quick detour (usually 0, used when on route to distant objective, but want to grab inventory for example)
*/
event float DetourWeight(Pawn Other,float PathWeight);
 
/* SuggestMovePreparation()
Optionally tell Pawn any special instructions to prepare for moving to this goal
(called by Pawn.PrepareForMove() if this node's bSpecialMove==true
*/
event bool SuggestMovePreparation(Pawn Other)
{
	return false;
}

/* ProceedWithMove()
Called by Controller to see if move is now possible when a mover reports to the waiting
pawn that it has completed its move
*/
function bool ProceedWithMove(Pawn Other)
{
	return true;
}

/* MoverOpened() & MoverClosed() used by NavigationPoints associated with movers */
function MoverOpened();
function MoverClosed();

#if IG_SWAT

// Each navigation holds a reference to the closest awareness point that it
// has a direct line-of-sight to. [darren]
function AwarenessPoint GetClosestAwarenessPoint()
{
    return ClosestAwarenessPoint;
}

function float GetClosestAwarenessPointDistance()
{
    return ClosestAwarenessPointDistance;
}

#endif

defaultproperties
{
	Texture=Texture'Engine_res.S_NavP'
     bStatic=true
	 bNoDelete=true
     bHidden=true
     bCollideWhenPlacing=true
//#if !IG_DISABLE_UNREAL_ACTOR_SOUND_MANAGEMENT // ckline: use IG_EFFECTS system instead of old Unreal per-actor sound specifications 
//     SoundVolume=0
//#endif
     CollisionRadius=+00030.000000
     CollisionHeight=+00080.000000
	 TimeOfLastSpawn=-1;// ckline: must start at < 0 because Level.TimeSeconds is 0 when non-dedicated server spawns player
}
