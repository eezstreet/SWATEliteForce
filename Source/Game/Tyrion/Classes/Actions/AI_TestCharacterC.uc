//=====================================================================
// AI_TestCharacterC
// Test Class for Actions - priorities test
//=====================================================================

class AI_TestCharacterC extends AI_CharacterAction
	editinlinenew;

//=====================================================================
// Variables

var(parameters) int parameter1;				// to test goal constraints
var(parameters) float parameter2;

var int goalsAchievedN;						// counts how many goalAchievedCB's were received

//=====================================================================
// Functions

function goalAchievedCB( AI_Goal goal, AI_Action action )
{
	super.goalAchievedCB( goal, action );

	goalsAchievedN++;
	log( self.name @ "goalAchievedCB called for" @ goal.name @ "by" @ action.name );
}

//=====================================================================
// State code

state Running
{
Begin:
	log( self.name @ "started. Creating a low-pri goal for movementResource." );

	(new class'AI_TestMovementGoalA'( movementResource(), 20 )).postGoal( self );
	Sleep(2.0);

	log( self.name @ "is creating a high-pri goal for the same resource..." );
	WaitForGoal( (new class'AI_TestMovementGoalA'( movementResource(), 90 )).postGoal( self ) );
	Sleep(2.0);

	log( self.name @ "will terminate now." );

	if ( goalsAchievedN == 1 )
		succeed();
	else
		fail( ACT_ErrorCodes.ACT_GENERAL_FAILURE );
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_TestCharacterGoalC'
}