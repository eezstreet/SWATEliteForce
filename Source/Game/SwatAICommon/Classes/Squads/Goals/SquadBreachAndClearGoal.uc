///////////////////////////////////////////////////////////////////////////////
// SquadBreachAndClearGoal.uc - SquadBreachAndClearGoal class
// this goal is used to organize the Officer's breach & clear behavior

class SquadBreachAndClearGoal extends SquadMoveAndClearGoal;
///////////////////////////////////////////////////////////////////////////////

var private bool UseBreachingCharge;
var private int BreachingMethod;

///////////////////////////////////////////////////////////////////////////////
// constructor
overloaded function construct(AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, Door inTargetDoor, optional bool bUseBreachingCharge, optional int iBreachingMethod) {
	super.construct(r, inCommandGiver, inCommandOrigin, inTargetDoor);
	UseBreachingCharge = bUseBreachingCharge;
	BreachingMethod = iBreachingMethod;
}

function bool DoWeUseBreachingCharge() {
	return UseBreachingCharge;
}

function int GetBreachingMethod() {
	return BreachingMethod;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadBreachAndClear"
}
