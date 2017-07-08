//=====================================================================
// AI_TestMovementB
// Test Class for child actions - achieves TestInactiveAchievableGoal
//=====================================================================

class AI_TestMovementB extends AI_MovementAction
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
	log( self.name @ "started. Sleeping for 5 seconds." );
	Sleep(5.0);
	log( self.name @ "will terminate now." );

	succeed();
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_TestInactiveAchievableGoal'
}