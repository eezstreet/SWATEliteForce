//=====================================================================
// AI_DummyMovement
// Action that simply sleeps
//=====================================================================

class AI_DummyMovement extends AI_MovementAction
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
	if ( resource.pawn().logTyrion )
		log( self.name @ "started." );

	pause();

	succeed();
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_DummyMovementGoal'
}