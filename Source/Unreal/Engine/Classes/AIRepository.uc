///////////////////////////////////////////////////////////////////////////////
class AIRepository extends Actor
	native;
///////////////////////////////////////////////////////////////////////////////

// Swat Specific, totally overridden in SwatAICommon.SwatAIRepository

// overridden in SwatAIRepository class
function AddNavigationPointToRoomList(NavigationPoint NavPoint, name RoomName);
function NavigationPointList GetRoomNavigationPoints(name RoomName) { return None; }

defaultproperties
{
    bHidden=true
}