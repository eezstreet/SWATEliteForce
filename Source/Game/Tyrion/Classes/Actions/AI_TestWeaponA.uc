//=====================================================================
// AI_TestWeaponA
// Test Class for child actions
//=====================================================================

class AI_TestWeaponA extends AI_WeaponAction
	editinlinenew;

//=====================================================================
// Variables

//=====================================================================
// Functions

//=====================================================================
// State code

state Running
{
Begin:
	log( self.name @ "started. Sleeping for 15 seconds." );
	Sleep(15.0);
	log( self.name @ "will terminate now." );

	succeed();
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_TestWeaponGoalA'
}