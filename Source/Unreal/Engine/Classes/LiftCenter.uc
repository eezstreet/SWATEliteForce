//=============================================================================
// LiftCenter.
//=============================================================================
class LiftCenter extends NavigationPoint
	placeable
	native;

var() name LiftTag;
var	 mover MyLift;
var() name LiftTrigger;
var trigger RecommendedTrigger;
var float MaxDist2D;
var vector LiftOffset;	// starting vector between MyLift location and LiftCenter location

function PostBeginPlay()
{
	if ( LiftTrigger != '' )
		ForEach DynamicActors(class'Trigger', RecommendedTrigger, LiftTrigger )
			break;
	Super.PostBeginPlay();
}

/* SpecialHandling is called by the navigation code when the next path has been found.  
It gives that path an opportunity to modify the result based on any special considerations

Here, we check if the mover needs to be triggered
*/

function Actor SpecialHandling(Pawn Other)
{
	// if no lift, no special handling
	if ( MyLift == None )
		return self;

	// check whether or not need to trigger the lift
	if ( !MyLift.IsInState('StandOpenTimed') )
	{
		if ( MyLift.bClosed 
			&& (RecommendedTrigger != None) )
			return RecommendedTrigger;
	}	
	else if ( MyLift.BumpType == BT_PlayerBump && !Other.IsPlayerPawn() )
		return None;

	return self;
}

/* 
Check if mover is positioned to allow Pawn to get on
*/
function bool SuggestMovePreparation(Pawn Other)
{
	// if already on lift, no problem 
	if ( Other.base == MyLift )
		return false;

	// make sure LiftCenter is correctly positioned on the lift
	SetLocation(MyLift.Location + LiftOffset);
	SetBase(MyLift);

	// if mover is moving, wait
	if ( MyLift.bInterpolating || !ProceedWithMove(Other) )
	{
		Other.Controller.WaitForMover(MyLift);
		return true;
	}

	return false;
}

function bool ProceedWithMove(Pawn Other)
{
	local LiftExit Start;
	local float dist2D;
	local vector dir;

	// see if mover is at appropriate location/keyframe
	Start = LiftExit(Other.Anchor);

	if ( (Start != None) && (Start.KeyFrame != 255) )
	{
		if ( MyLift.KeyNum == Start.KeyFrame )
			return true;
	}
	else
	{
		//check distance directly - make sure close
		dir = Location - Other.Location;
		dir.Z = 0;
		dist2d = vsize(dir);
		if ( (Location.Z - CollisionHeight < Other.Location.Z - Other.CollisionHeight + MAXSTEPHEIGHT)
			&& (Location.Z - CollisionHeight > Other.Location.Z - Other.CollisionHeight - 1200)
			&& ( dist2D < MaxDist2D) )
		{
			return true;
		}
	}

	// if mover not operating, need to start it
	if ( MyLift.bClosed )
	{
		Other.SetMoveTarget(SpecialHandling(Other));
		return true;
	}

	return false;
}

defaultproperties
{
	Texture=Texture'Engine_res.S_LiftCenter'
	RemoteRole=ROLE_None
	bStatic=false
	bSpecialMove=true
	ExtraCost=400
	MaxDist2D=+400.000
	bNoAutoConnect=true
	bNeverUseStrafing=true
	bForceNoStrafing=true
}