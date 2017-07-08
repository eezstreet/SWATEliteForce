//=====================================================================
// AI_TestWeaponGoalA
// Test Class for Goals - this is an active / achievable goal
//=====================================================================

class AI_TestWeaponGoalA extends AI_WeaponGoal
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
}

