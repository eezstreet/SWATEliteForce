///////////////////////////////////////////////////////////////////////////////
// ClearPoint.uc - ClearPoint class
// A point that Officers will stack-up at based on priority

class ClearPoint extends BaseDoorPoint
	notplaceable
    native;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// ClearPoint variables

var   protected Texture			ClearPointIcons[4];
var	  array<ClearRoutePoint>	ClearRoutePoints;

// For Debugging
var	  array<vector>				ClearPathLocations;
var	  private color				ClearPathColors[4];

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	bStatic=true
	ClearPathColors(0)=(B=255,G=255,R=255,A=255)
	ClearPathColors(1)=(B=0,G=0,R=0,A=255)
	ClearPathColors(2)=(B=255,G=200,R=200,A=255)
	ClearPathColors(3)=(B=0,G=96,R=255,A=255)
}