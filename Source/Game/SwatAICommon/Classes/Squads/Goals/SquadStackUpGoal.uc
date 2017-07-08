///////////////////////////////////////////////////////////////////////////////
// SquadStackUpGoal.uc - SquadStackUpGoal class
// this goal is used to organize the Officer's stack up behavior

class SquadStackUpGoal extends SquadCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// automatically copied to our action
var(parameters) Door	TargetDoor;
var(parameters) bool	bTriggerCouldntBreachLockedSpeech;

///////////////////////////////////////////////////////////////////////////////
//
// Constructors

// Use this constructor
overloaded function construct( AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, Door inTargetDoor, optional bool bInTriggerCouldntBreachLockedSpeech )
{
	super.construct(r, inCommandGiver, inCommandOrigin);

	assert(inTargetDoor != None);
	TargetDoor = inTargetDoor;

	bTriggerCouldntBreachLockedSpeech = bInTriggerCouldntBreachLockedSpeech;
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function Door GetDoorBeingUsed()
{
	return TargetDoor;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadStackUp"
}