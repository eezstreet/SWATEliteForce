//=====================================================================
// AI_TestMovementA
// Test Class for child actions
//=====================================================================

class AI_TestMovementA extends AI_MovementAction
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
	log( self.name @ "started. Sleeping for 10 seconds." );
	Sleep(10.0);
	log( self.name @ "will terminate now." );

	succeed();
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_TestMovementGoalA'
}