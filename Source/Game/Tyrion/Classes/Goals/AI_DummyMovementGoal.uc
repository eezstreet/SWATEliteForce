//=====================================================================
// AI_DummyMovementGoal
//=====================================================================

class AI_DummyMovementGoal extends AI_MovementGoal
	editinlinenew;

//=====================================================================
// Variables

//=====================================================================
// Functions

overloaded function construct( AI_Resource r, int pri )
{
	super.construct( r );

	priority = pri;
}
 
//=====================================================================

defaultproperties
{
	bInactive = false
	bPermanent = false

	GoalName = "AI_DummyMovement"
}

