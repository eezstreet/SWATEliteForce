//=====================================================================
// AI_TestCharacterGoalA
// Test Class for Goals - this is an active / achievable goal
//=====================================================================

class AI_TestCharacterGoalA extends AI_CharacterGoal
	editinlinenew;

//=====================================================================
// Variables

var() int constraint1;

//=====================================================================
// Functions

overloaded function construct( AI_Resource r, int pri, int const1 )
{
	priority = pri;
	constraint1 = const1;

	super.construct( r );
}

//=====================================================================

defaultproperties
{
	bInactive = false
	bPermanent = false
}

