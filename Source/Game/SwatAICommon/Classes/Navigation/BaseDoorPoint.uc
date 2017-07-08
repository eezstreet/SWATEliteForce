///////////////////////////////////////////////////////////////////////////////
// BaseDoorPoint.uc - Base class of stackup and clear points

class BaseDoorPoint extends Engine.PathNode
    notplaceable
    native;

var const nocopy Door ParentDoor; // internal native code backpointer, managed by SwatDoor
var() private int Priority;


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    bDirectional=true
    bPropagatesSound=true
}