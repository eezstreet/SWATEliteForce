//=====================================================================
// Tests Tyrion interrupt functionality
//=====================================================================

class TyrionInterruptTest extends TyrionUnitTest;

//=====================================================================
// Variables

var() name pawnName;

var AI_CharacterResource characterResource;
var AI_MovementResource movementResource;
var AI_WeaponResource weaponResource;

var AI_Goal goal1;
var AI_Goal goal2;

//=====================================================================
// State Code

state UnitTestState
{
	function BeginState()
	{
		workPawn = getPawn(string(pawnName));

		// get specified pawn
		if (workPawn == None)
		{
			signalFailed("Failed to find Pawn named " $ string(pawnName) $ ".");
			return;
		}

		characterResource = AI_CharacterResource(workPawn.characterAI);
		movementResource = AI_MovementResource(workPawn.movementAI);
		weaponResource = AI_WeaponResource(workPawn.weaponAI);

		// get AI controller
		workController = AI_Controller(workPawn.Controller);
		if (workController == None)
		{
			signalFailed(string(pawnName) $ " does not have an AI_Controller.");
			return;
		}

		characterResource.addAbility( new class'AI_TestCharacterA' );
		characterResource.addAbility( new class'AI_TestCharacterB' );
		characterResource.addAbility( new class'AI_TestCharacterC' );
		movementResource.addAbility( new class'AI_TestMovementA' );
		movementResource.addAbility( new class'AI_TestMovementB' );
		weaponResource.addAbility( new class'AI_TestWeaponA' );
	}

Begin:

	logTest("Tyrion Interrupt Test started");
	logTest("First pass: no interruptions");

	goal1 = (new class'AI_TestCharacterGoalA'( characterResource, 50, 7 )).postGoal( None );
loop:
	if ( !goal1.hasCompleted() )
	{
		Sleep(1.0);
		goto 'loop';
	}

	logTest("Second pass: unPost goal after 11 seconds.");
	goal2 = (new class'AI_TestCharacterGoalA'( characterResource, 50, 7 )).postGoal( None );
	
	Sleep(11.0);
	goal2.unPostGoal( None );

	logTest("Tyrion Interrupt Test finished");

	if ( goal1.wasAchieved() && !goal2.wasAchieved() )
		signalPassed();
	else
		signalFailed(string(pawnName) $ " didn't achieve " $ goal1 $ " or achieved " $ goal2 );
}