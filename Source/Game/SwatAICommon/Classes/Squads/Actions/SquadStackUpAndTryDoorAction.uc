///////////////////////////////////////////////////////////////////////////////
// SquadStackUpAndTryDoorAction.uc - SquadStackUpAndTryDoorAction class
// this action is used to organize the Officer's stack up and try door behavior

class SquadStackUpAndTryDoorAction extends SquadStackUpAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private TryDoorGoal CurrentTryDoorGoal;

///////////////////////////////////////////////////////////////////////////////
//
// cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentTryDoorGoal != None)
	{
		CurrentTryDoorGoal.Release();
		CurrentTryDoorGoal = None;
	}
}

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	super.goalAchievedCB(goal, child);

	if (resource.pawn().logTyrion)
		log("SquadStackUpAndTryDoorAction::goalAchievedCB - pawn is: " $ goal.resource.Pawn() $ " goal is: " $ goal $ " child is: " $ child);
	
	// if we haven't tried the door yet, and the stack up goal just was achieved by the first officer
	if ((CurrentTryDoorGoal == None) && goal.IsA('StackUpGoal') && (OfficersInStackUpOrder[0] == goal.resource.Pawn()))
	{
		if (CanInteractWithTargetDoor())
		{
			TryDoor(goal.resource.Pawn());
		}

		runAction();
	}
	else if (goal == CurrentTryDoorGoal)	// if the try door goal just completed, run!
	{
		PostStackedUpGoal(GetFirstOfficer(), StackUpPoints[0]);

		runAction();
	}
}

// handle officers dying during a stack up and try door
protected function NotifyPawnDied(Pawn pawn)
{
	super.NotifyPawnDied(pawn);

	assert(pawn != None);

	// this will restart the behavior
	instantFail(ACT_GENERAL_FAILURE);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

protected function bool ShouldFirstOfficerBeStackedUp()
{
	return (OfficersInStackupOrder[0] == None) || !IsOfficerAtSideOpenPoint(OfficersInStackupOrder[0]);
}

function TryDoor(Pawn Officer)
{
	assert(Officer != None);
	assert(CurrentTryDoorGoal == None);

	// remove the stacked up goal on the officer
	RemoveStackedUpGoalOnOfficer(Officer);

	CurrentTryDoorGoal = new class'TryDoorGoal'(AI_Resource(Officer.characterAI), TargetDoor, !bTriggerCouldntBreachLockedSpeech);
	assert(CurrentTryDoorGoal != None);
	CurrentTryDoorGoal.AddRef();

	CurrentTryDoorGoal.postGoal(self);
}

private function RemoveTryDoorGoal()
{
	if (CurrentTryDoorGoal != None)
	{
		CurrentTryDoorGoal.unPostGoal(self);
		CurrentTryDoorGoal.Release();
		CurrentTryDoorGoal = None;
	}
}

state Running
{
Begin:
	// if we need to stack up, stack up and wait until the stack up goal on the first officer completes
	if (NeedsToStackUp())
	{
		TriggerOrderedToStackUpReplySpeech();

		InternalStackUpSquad();
		pause();

		if ((CurrentTryDoorGoal != None) && !CurrentTryDoorGoal.hasCompleted())
			WaitForGoal(CurrentTryDoorGoal);

		WaitForZulu(TargetDoor);
	}
	else
	{
		// otherwise just try the door if we don't have to stack up
		TryDoor(GetFirstOfficer());

		WaitForZulu(TargetDoor);
		pause();
	}

	RemoveTryDoorGoal();

	TriggerCompletedSpeech();

	// doesn't complete until interrupted
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadStackUpAndTryDoorGoal'
}