///////////////////////////////////////////////////////////////////////////////
// MoveInFormationGoal.uc - MoveInFormationGoal class
// this goal is given to the movement resource when in a Formation so that 
// an Officer can follow the player or another officer in formation
class MoveInFormationGoal extends MoveToActorGoal;
///////////////////////////////////////////////////////////////////////////////

// copied from our goal
var(parameters) float InnerMoveToThreshold;
var(parameters) float OuterMoveToThreshold;

var(parameters) float InnerWalkThreshold;
var(parameters) float OuterWalkThreshold;

///////////////////////////////////////////////////////////////////////////////
function SetMoveToThresholds(float InitialMoveToThreshold, float inInnerMoveToThreshold, float inOuterMoveToThreshold)
{
	assert(InitialMoveToThreshold >= 0.0);
	assert(inInnerMoveToThreshold >= 0.0);
	assert(inOuterMoveToThreshold >= 0.0);

	MoveToThreshold      = InitialMoveToThreshold;
	InnerMoveToThreshold = inInnerMoveToThreshold;
	OuterMoveToThreshold = inOuterMoveToThreshold;
}

function SetWalkThresholds(float InitialWalkThreshold, float inInnerWalkThreshold, float inOuterWalkThreshold)
{
	assert(InitialWalkThreshold >= 0.0);
	assert(inInnerWalkThreshold >= 0.0);
	assert(inOuterWalkThreshold >= 0.0);

	WalkThreshold      = InitialWalkThreshold;
	InnerWalkThreshold = inInnerWalkThreshold;
	OuterWalkThreshold = inOuterWalkThreshold;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	MoveToThreshold = 75.0
	WalkThreshold   = 100.0

	InnerMoveToThreshold = 125.0
	OuterMoveToThreshold = 75.0

	InnerWalkThreshold   = 150.0
	OuterWalkThreshold   = 100.0

	bInactive  = false
	bPermanent = false
    goalName   = "MoveInFormation"
}
