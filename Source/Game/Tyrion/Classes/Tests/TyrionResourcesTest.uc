//=====================================================================
// Tests Tyrion resources functionality
//=====================================================================

class TyrionResourcesTest extends TyrionUnitTest;

//=====================================================================
// Variables

var() name pawnName;

var AI_CharacterResource characterResource;
var AI_MovementResource movementResource;
var AI_WeaponResource weaponResource;

var AI_Goal goal1;
var AI_Goal goal2;
var AI_Goal goal3;

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

		characterResource.addAbility( new class'AI_TestCharacterD' );
		characterResource.addAbility( new class'AI_TestCharacterE' );
		movementResource.addAbility( new class'AI_TestMovementA' );
		movementResource.addAbility( new class'AI_TestMovementB' );
		weaponResource.addAbility( new class'AI_TestWeaponA' );
	}

Begin:

	logTest("Tyrion Resources Test started");

	log("1. Starting a character action (AI_TestCharacterD) that uses arms and legs");
	
	goal1 = (new class'AI_TestCharacterGoalB'( characterResource, 50 )).postGoal( None );
	Sleep(3.0);

	log("2. Posting a high priority goal for the legs"); // AI_TestCharacterD should have its leg resource stolen and terminate)

	goal2 = (new class'AI_TestMovementGoalA'( movementResource, 90 )).postGoal( None );

	// remove goal1 if the action achieving it fails
loop1:
	if( !goal1.hasCompleted() )
	{
		Sleep(0.5);
		goto 'loop1';
	}
	if( !goal1.wasAchieved() )
	{
		log( "   AI_TestCharacterD was 'unposted'" );
		goal1.unPostGoal( None );
	}

	log("3. Starting another character action (AI_TestCharacterE) that uses only weapons"); // there should be no resource conflicts

	goal3 = (new class'AI_TestCharacterGoalC'( characterResource, 50 )).postGoal( None );
loop2:
	if ( !goal2.hasCompleted() || !goal3.hasCompleted() )
	{
		Sleep(1.0);
		goto 'loop2';
	}

	logTest("Tyrion Resources Test finished");

	if ( !goal1.wasAchieved() && goal2.wasAchieved() && goal3.wasAchieved())
		signalPassed();
	else
		signalFailed(string(pawnName) $ " achieved " $ goal1 $ " or didn't achieve " $ goal2 $ " and " $ goal3);
}