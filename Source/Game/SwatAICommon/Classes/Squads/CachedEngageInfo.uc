///////////////////////////////////////////////////////////////////////////////
// CachedEngageInfo.uc - the CachedEngageInfo class
// helps us keep track of officer engagements within the same tick
// the Hive manages an array of CachedEngageInfo

class CachedEngageInfo extends Core.RefCount
	native;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

var Pawn					CachedOpponent;
var name					CachedRoomForEngaging;				// what room we cached info for
var float					CachedTime;							// when we cached the info
var array<NavigationPoint>	CachedNavigationPointsForEngaging;	// the points we can engage from