///////////////////////////////////////////////////////////////////////////////
// PlacedThrowPoint.uc - PlacedThrowPoint class
// A point placed by designers that specifies a particular place that the officers throw from
// when moving and clearing.  This is not to replace throw points that are automatically a part
// of doors, simply to supercede use of them when this class is associated with a door

class PlacedThrowPoint extends Engine.PathNode
	native;
///////////////////////////////////////////////////////////////////////////////

import enum AIThrowSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var() AIThrowSide	ThrowSide	"Determines the animation we use to throw through this door";

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	Texture=Texture'Swat4EditorTex.throwPoint'
    bPropagatesSound=false
	bDirectional=true
}