///////////////////////////////////////////////////////////////////////////////
// FlushPoint.uc - FlushPoint class
// A point that AIs can run to to to destroy evidence, connectable to Unreal's pathfinding system

class FlushPoint extends Engine.PathNode;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var() bool			ShouldCrouchAtPoint;

var private Pawn	FlushPointUser;	// who is currently using this point


///////////////////////////////////////////////////////////////////////////////
//
// Implementation

function ClaimPoint(Pawn NewFlushPointUser)
{
	FlushPointUser = NewFlushPointUser;

	if (FlushPointUser.logAI)
		log(FlushPointUser.Name $ " claimed " $ Name);
}

function Pawn GetFlushPointUser()
{
	if (! class'Pawn'.static.checkConscious(FlushPointUser))
		FlushPointUser = None;

	return FlushPointUser;
}

function UnclaimPoint()
{
	if ((FlushPointUser != None) && FlushPointUser.logAI)
		log(FlushPointUser.Name $ " unclaimed " $ Name);

	FlushPointUser = None;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Texture=Texture'Swat4EditorTex.FleePoint'
    bPropagatesSound=false
	ShouldCrouchAtPoint=true
}