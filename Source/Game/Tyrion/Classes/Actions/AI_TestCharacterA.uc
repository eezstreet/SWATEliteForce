//=====================================================================
// AI_TestCharacterA
// Test Class for Actions - goal posting and interrupts test
//=====================================================================

class AI_TestCharacterA extends AI_CharacterAction
	editinlinenew;

//=====================================================================
// Variables

var(parameters) int parameter1;				// to test goal constraints
var(parameters) float parameter2;

var AI_CharacterAction copiedAction;		// to test copying

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
	log( self.name @ "started. Posting child goals for Movement and Weapon." );
	//log( "AI_Test: parameter1: " $ parameter1 $ "   parameter2: " $ parameter2 );

	WaitForAllGoals(
		(new class'AI_TestMovementGoalA'( movementResource(), 50 )).postGoal( self ),
		(new class'AI_TestWeaponGoalA'( weaponResource(), 50 )).postGoal( self ) );

	log( self.name @ "will terminate now." );

	if (goalsAchievedN == 2 )
		succeed();
	else
		fail( ACT_ErrorCodes.ACT_GENERAL_FAILURE );
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_TestCharacterGoalA'
}