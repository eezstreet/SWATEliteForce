///////////////////////////////////////////////////////////////////////////////
// CheckTrapsAction.uc - CheckTrapsAction class
// The Action that causes the Officers to test and see if a door is trapped

class CheckTrapsAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum AIDoorUsageSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Door				TargetDoor;

// behaviors we use
var private MoveToDoorGoal			CurrentMoveToDoorGoal;

// door usage side
var private	AIDoorUsageSide			TryDoorUsageSide;
var private rotator					TryDoorUsageRotation;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToDoorGoal != None)
	{
		CurrentMoveToDoorGoal.Release();
		CurrentMoveToDoorGoal = None;
	}

	// stop animating
	ISwatAI(m_Pawn).AnimStopSpecial();

	// unlock our aim (if it isn't already)
	ISwatAI(m_Pawn).UnlockAim();

	// make sure we re-enable collision avoidance
	m_Pawn.EnableCollisionAvoidance();
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  failing.");

	// just fail
	InstantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
//
//

private function ReportResultsToTeam()
{
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);
	assert(SwatAIRepo != None);

	TriggerReportResultsSpeech();
}

private function TriggerReportResultsSpeech()
{
	local ISwatDoor SwatTargetDoor;

	SwatTargetDoor = ISwatDoor(TargetDoor);
	assert(SwatTargetDoor != None);

  if(SwatTargetDoor.IsBoobyTrapTriggered()) {
    ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerExaminedAfterTrapWentOffSpeech();
  } else if(SwatTargetDoor.IsBoobyTrapped()) {
    ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerExaminedFoundTrapSpeech();
  } else {
    ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerExaminedFoundNoTrapSpeech();
  }
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveToTryDoor()
{
	CurrentMoveToDoorGoal = new class'MoveToDoorGoal'(movementResource(), achievingGoal.priority, TargetDoor);
	assert(CurrentMoveToDoorGoal != None);
	CurrentMoveToDoorGoal.AddRef();

	CurrentMoveToDoorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToDoorGoal.SetShouldWalkEntireMove(false);
	CurrentMoveToDoorGoal.SetPreferSides();

	CurrentMoveToDoorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToDoorGoal);

	// save the side of the door we're going to try from
	TryDoorUsageSide     = CurrentMoveToDoorGoal.DoorUsageSide;
	TryDoorUsageRotation = CurrentMoveToDoorGoal.DoorUsageRotation;

	CurrentMoveToDoorGoal.unPostGoal(self);

	CurrentMoveToDoorGoal.Release();
	CurrentMoveToDoorGoal = None;
}

latent function TryDoor()
{
	local int AnimSpecialChannel;
	local name AnimName;
	local ISwatDoor SwatDoorTarget;

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	AnimName		   = SwatDoorTarget.GetTryDoorAnimation(m_Pawn, TryDoorUsageSide);
	AnimSpecialChannel = m_Pawn.AnimPlaySpecial(AnimName);

	m_Pawn.FinishAnim(AnimSpecialChannel);
}

private function bool CanInteractWithTargetDoor()
{
	return (! TargetDoor.IsEmptyDoorWay() && TargetDoor.IsClosed() && !TargetDoor.IsOpening() && !ISwatDoor(TargetDoor).IsBroken());
}

state Running
{
Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	// test to see if we can interact with this door first
	if (CanInteractWithTargetDoor())
	{
		MoveToTryDoor();

		useResources(class'AI_Resource'.const.RU_LEGS);

		// test again to see if we can interact with this door
		if (CanInteractWithTargetDoor())
		{
			// keep us facing the correct direction
			ISwatAI(m_Pawn).AimToRotation(TryDoorUsageRotation);
			ISwatAI(m_Pawn).LockAim();
			ISwatAI(m_Pawn).AnimSnapBaseToAim();

			TryDoor();

			ISwatAI(m_Pawn).UnlockAim();

			// re-enable collision avoidance
			m_Pawn.EnableCollisionAvoidance();
			ReportResultsToTeam();
		}
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'CheckTrapsGoal'
}
