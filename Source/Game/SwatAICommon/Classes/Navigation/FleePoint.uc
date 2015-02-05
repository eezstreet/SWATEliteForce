///////////////////////////////////////////////////////////////////////////////
// FleePoint.uc - FleePoint class
// A point that AIs can barricade themselves at, connectable to Unreal's pathfinding system
// Used for the Barricading and Fleeing behavior
// Should only be placed in rooms, and not hallways

class FleePoint extends Engine.PathNode;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var() bool			ShouldCrouchAtPoint;

var private Pawn	FleePointUser;	// who is currently using this point


///////////////////////////////////////////////////////////////////////////////
//
// Implementation

function ClaimPoint(Pawn NewFleePointUser)
{
	FleePointUser = NewFleePointUser;

	if (FleePointUser.logAI)
		log(FleePointUser.Name $ " claimed " $ Name);
}

function Pawn GetFleePointUser()
{
	if (! class'Pawn'.static.checkConscious(FleePointUser))
		FleePointUser = None;

	return FleePointUser;
}

function UnclaimPoint()
{
	if ((FleePointUser != None) && FleePointUser.logAI)
		log(FleePointUser.Name $ " unclaimed " $ Name);

	FleePointUser = None;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Texture=Texture'Swat4EditorTex.FleePoint'
    bPropagatesSound=false
	ShouldCrouchAtPoint=true
}