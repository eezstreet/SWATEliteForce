///////////////////////////////////////////////////////////////////////////////
// SquadBreachAndClearGoal.uc - SquadBreachAndClearGoal class
// this goal is used to organize the Officer's breach & clear behavior

class SquadBreachAndClearGoal extends SquadMoveAndClearGoal;
///////////////////////////////////////////////////////////////////////////////

var private bool UseBreachingCharge;

///////////////////////////////////////////////////////////////////////////////
// constructor
overloaded function construct(AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, Door inTargetDoor, optional bool bUseBreachingCharge) {
	super.construct(r, inCommandGiver, inCommandOrigin, inTargetDoor);
	UseBreachingCharge = bUseBreachingCharge;
}

function bool DoWeUseBreachingCharge() {
	return UseBreachingCharge;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadBreachAndClear"
}