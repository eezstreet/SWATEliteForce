///////////////////////////////////////////////////////////////////////////////
class MirrorPoint extends Engine.Actor implements SwatAICommon.IMirrorPoint
	placeable
	native
	config(SwatGame);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

enum EMirroringSide
{
	MirrorToLeft,
	MirrorToRight
};

var() EMirroringSide				MirrorDirection;

// set by processing in UnrealEd
var private const bool				bIsMirroringFromPointValid;
var private const vector			MirroringFromPoint;		
var private const vector			MirroringToPoint;
var private const Rotator			MirroringRotation;

// config
var config float					OffsetFromMirrorPoint;
var config float					OffsetFromCornerDirection;

///////////////////////////////////////////////////////////////////////////////
// 
// Variables


function vector GetMirroringFromPoint()		{ return MirroringFromPoint; }
function vector GetMirroringToPoint()		{ return MirroringToPoint; }
function rotator GetMirroringDirection()	{ return Rotation; }

//This is placeholder until evidence is implemented.
//I am creating the class while implementing the CommandInterface, so that
//  I can implement the 'MirrorCorner' command.

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	bDirectional = true
	bCollideActors = true
	bCollideWorld = false
	bBlockActors = false
	bBlockPlayers = false
	bStatic = false
	bBlockKarma=false
	bWorldGeometry=false
	bAcceptsProjectors=false
	bStaticLighting=false
	bShadowCast=false

	bHidden=true
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'Doors_sm.MirrorPoint'
}
