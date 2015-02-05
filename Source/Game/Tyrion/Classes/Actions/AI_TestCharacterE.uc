//=====================================================================
// AI_TestCharacterE
// Test Class for Actions - resource test 2
//=====================================================================

class AI_TestCharacterE extends AI_CharacterAction
	editinlinenew;

//=====================================================================
// Variables

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
	log( self.name @ "started. Using weaponResource (pri 25)." );

	WaitForGoal( (new class'AI_TestWeaponGoalA'( weaponResource(), 25 )).postGoal( self ) );
	Sleep(2.0);

	log( self.name @ "will terminate now." );

	if ( goalsAchievedN == 1 )
		succeed();
	else
		fail( ACT_ErrorCodes.ACT_GENERAL_FAILURE );
}

//=====================================================================

function classConstruct()
{
	resourceUsage = class'AI_Resource'.const.RU_ARMS;
}

defaultproperties
{
	satisfiesGoal = class'AI_TestCharacterGoalC'
//	resourceUsage = 2 // should be RU_ARMS! can't access
}