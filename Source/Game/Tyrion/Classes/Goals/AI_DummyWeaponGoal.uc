//=====================================================================
// AI_DummyWeaponGoal
//=====================================================================

class AI_DummyWeaponGoal extends AI_WeaponGoal
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
	GoalName = "AI_DummyWeapon"
}

