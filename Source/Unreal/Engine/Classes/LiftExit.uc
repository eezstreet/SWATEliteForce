//=============================================================================
// LiftExit.
//=============================================================================
class LiftExit extends NavigationPoint
	placeable
	native;

var() name LiftTag;
var	Mover MyLift;
var() byte SuggestedKeyFrame;	// mover keyframe associated with this exit - optional
var byte KeyFrame;

event bool SuggestMovePreparation(Pawn Other)
{
	local Controller C;
	
	if ( (MyLift == None) || (Other.Controller == None) )
		return false;
	if ( Other.Physics == PHYS_Flying )
	{
		if ( Other.AirSpeed > 0 )
			Other.Controller.MoveTimer = 2+ VSize(Location - Other.Location)/Other.AirSpeed;
		return false;
	}
	if ( (Other.Base == MyLift)
			|| ((LiftCenter(Other.Anchor) != None) && (LiftCenter(Other.Anchor).MyLift == MyLift)
				&& (Other.ReachedDestination(Other.Anchor))) )
	{
		// if pawn is on the lift, see if it can get off and go to this lift exit
		if ( (Location.Z < Other.Location.Z + Other.CollisionHeight)
			 && Other.LineOfSightTo(self) )
			return false;

		// make pawn wait on the lift
		Other.DesiredRotation = rotator(Location - Other.Location);
		Other.Controller.WaitForMover(MyLift);
		return true;
	}
	else
	{
		for ( C=Level.ControllerList; C!=None; C=C.nextController )
			if ( (C.Pawn != None) && (C.PendingMover == MyLift) && C.SameTeamAs(Other.Controller) && C.Pawn.ReachedDestination(self) )
			{
				Other.DesiredRotation = rotator(Location - Other.Location);
				Other.Controller.WaitForMover(MyLift);
				return true;
			}
	}
	return false;
}

defaultproperties
{
	Texture=Texture'Engine_res.S_LiftExit'
	SuggestedKeyFrame=255
	bSpecialMove=true
	bNeverUseStrafing=true
	bForceNoStrafing=true
}
