//=============================================================================
// ReachSpec.
//
// A Reachspec describes the reachability requirements between two NavigationPoints
//
//=============================================================================
class ReachSpec extends Core.Object
	native;

var	int		Distance; 
var	const NavigationPoint	Start;		// navigationpoint at start of this path
var	const NavigationPoint	End;		// navigationpoint at endpoint of this path (next waypoint or goal)
var	int		CollisionRadius; 
var	int		CollisionHeight; 
var	int		reachFlags;			// see EReachSpecFlags definition in UnPath.h
var	int		MaxLandingVelocity;
var	byte	bPruned;
var	const bool	bForced;

// this tells us when a reach spec is blocked by an open door
struct native DoorBlockedInfo
{
	var Door BlockedBy;
	var bool bBlockedWhenOpenRight;	// true if it's blocked by being open right, false if when it's blocked by being open left
};

var array<DoorBlockedInfo> DoorBlockedList;

