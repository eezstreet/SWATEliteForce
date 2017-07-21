///////////////////////////////////////////////////////////////////////////////
// EngageForComplianceAction.uc - EngageTargetAction class
// The Action that causes an Officer AI to engage a target for compliance

class EngageForComplianceAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Pawn					TargetPawn;

// our behaviors
//var private SWATTakeCoverAndAimGoal		CurrentSWATTakeCoverAndAimGoal;
var private OrderComplianceGoal			CurrentOrderComplianceGoal;
var protected MoveOfficerToEngageGoal   CurrentMoveOfficerToEngageGoal;

// config variables
var config float						MinComplianceOrderSleepTime;
var config float						MaxComplianceOrderSleepTime;

const kMinComplianceUpdateTime = 0.1;
const kMaxComplianceUpdateTime = 0.25;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentOrderComplianceGoal != None)
	{
		CurrentOrderComplianceGoal.Release();
		CurrentOrderComplianceGoal = None;
	}

//	if (CurrentSWATTakeCoverAndAimGoal != None)
//	{
//		CurrentSWATTakeCoverAndAimGoal.Release();
//		CurrentSWATTakeCoverAndAimGoal = None;
//	}
	
	if (CurrentMoveOfficerToEngageGoal != None)
	{
		CurrentMoveOfficerToEngageGoal.Release();
		CurrentMoveOfficerToEngageGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

//	if ((goal == CurrentOrderComplianceGoal) || (goal == CurrentMoveOfficerToEngageGoal) || (goal == CurrentSWATTakeCoverGoal))
	if ((goal == CurrentOrderComplianceGoal) || (goal == CurrentMoveOfficerToEngageGoal))
	{
		// if ordering compliance or movement fails, we succeed so we don't get reposted, 
		// the OfficerCommanderAction will figure out what to do
		InstantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// we only move to engage the target for compliance if we should 
// (not in the middle of executing a move and clear!)
private function bool ShouldMoveTowardsComplianceTarget()
{
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	// test to see if we're moving and clearing

	return (! SwatAIRepo.IsOfficerMovingAndClearing(m_Pawn));
}

//private function bool ShouldTakeCover()
//{
//	local SwatAIRepository SwatAIRepo;
//	SwatAIRepo = SwatAIRepository(Level.AIRepo);
//
//	// test to see if we're moving and clearing
//	return (! SwatAIRepo.IsOfficerMovingAndClearing(m_Pawn));
//
//}

private function MoveTowardsComplianceTarget()
{
	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " will move to engage the target for compliance");

	assert(CurrentMoveOfficerToEngageGoal == None);

	CurrentMoveOfficerToEngageGoal = new class'MoveOfficerToEngageGoal'(movementResource(), achievingGoal.Priority, TargetPawn);
	assert(CurrentMoveOfficerToEngageGoal != None);
	CurrentMoveOfficerToEngageGoal.AddRef();

	CurrentMoveOfficerToEngageGoal.SetRotateTowardsPointsDuringMovement(true);

	// post the move to goal and wait for it to complete
	CurrentMoveOfficerToEngageGoal.postGoal(self);
}

//private function TakeCoverRelativeToTarget()
//{
//	if (m_Pawn.logAI)
//		log(m_Pawn.Name $ " will move to engage the target for compliance");

//	assert(CurrentSWATTakeCoverAndAimGoal == None);

//	CurrentSWATTakeCoverAndAimGoal = new class'SWATTakeCoverAndAimGoal'(movementResource(), achievingGoal.Priority, TargetPawn);
//	assert(CurrentSWATTakeCoverAndAimGoal != None);
//	CurrentSWATTakeCoverAndAimGoal.AddRef();

	// post the move to goal and wait for it to complete
//	CurrentSWATTakeCoverAndAimGoal.postGoal(self);
//}

private function OrderTargetToComply()
{
	assert(CurrentOrderComplianceGoal == None);

	CurrentOrderComplianceGoal = new class'OrderComplianceGoal'(weaponResource(), TargetPawn);
	assert(CurrentOrderComplianceGoal != None);
	CurrentOrderComplianceGoal.AddRef();

	CurrentOrderComplianceGoal.postGoal(self);
}

state Running
{
 Begin:
	OrderTargetToComply();
	
	while (! CurrentOrderComplianceGoal.hasCompleted())
	{
		if ((CurrentMoveOfficerToEngageGoal == None) && ShouldMoveTowardsComplianceTarget())
		{
			MoveTowardsComplianceTarget();
		}
//		if ((CurrentSWATTakeCoverAndAimGoal == None) && ShouldTakeCover())
//		{
//			TakeCoverRelativeToTarget();
//		}

		sleep(RandRange(kMinComplianceUpdateTime, kMaxComplianceUpdateTime));
	}

	succeed();
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'EngageForComplianceGoal'
}
