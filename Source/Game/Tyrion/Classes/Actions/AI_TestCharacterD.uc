//=====================================================================
// AI_TestCharacterD
// Test Class for Actions - resource test 1
//=====================================================================

class AI_TestCharacterD extends AI_CharacterAction
	editinlinenew;

//=====================================================================
// Variables

var AI_Goal goal1;
var AI_Goal goal2;

//=====================================================================
// Functions

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	super.goalAchievedCB( goal, child );

	log( self.name @ "goalAchievedCB called for" @ goal.name @ "by" @ child.name );
}

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode ) 
{
	super.goalNotAchievedCB( goal, child, errorCode );

	log( self.name @ "goalNotAchievedCB called for" @ goal.name @ "by" @ child.name );
}

//---------------------------------------------------------------------

function cleanup()
{
	super.cleanup();

	if ( goal1 != None )
	{
		goal1.Release();
		goal1 = None;
	}

	if ( goal2 != None )
	{
		goal2.Release();
		goal2 = None;
	}
}

//=====================================================================
// State code

state Running
{
Begin:
	log( self.name @ "started. Using movementResource (pri 20) and weaponResource (pri 30)." );

	goal1 = (new class'AI_TestMovementGoalA'( movementResource(), 20 )).postGoal( self ).myAddRef();
	goal2 = (new class'AI_TestWeaponGoalA'( weaponResource(), 30 )).postGoal( self ).myAddRef();
	
	WaitForAllGoals( goal1, goal2 );
	// fail if any child goals failed
	if ( !goal1.wasAchieved() || !goal2.wasAchieved() )
	{
		log( self.name @ "has failed." );
		fail( ACT_ErrorCodes.ACT_GENERAL_FAILURE );
	}

	Sleep(2.0);

	log( self.name @ "has succeeded." );
	succeed();
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_TestCharacterGoalB'
}