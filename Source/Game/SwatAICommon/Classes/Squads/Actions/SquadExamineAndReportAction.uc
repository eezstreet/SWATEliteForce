///////////////////////////////////////////////////////////////////////////////
// SquadExamineAndReportAction.uc - SquadExamineAndReportAction class
// this action is used to organize the Officer's Examine & Report behavior

class SquadExamineAndReportAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Actor				ExamineTarget;

// behaviors we use
var private array<MoveToActorGoal>	MoveToActorGoals;

///////////////////////////////////////////////////////////////////////////////
//
// cleanup

function cleanup()
{
	super.cleanup();

	ClearOutMoveToGoals();
}

private function ClearOutMoveToGoals()
{
	while (MoveToActorGoals.Length > 0)
	{
		if (MoveToActorGoals[0] != None)
		{
			MoveToActorGoals[0].Release();
			MoveToActorGoals[0] = None;
		}

		MoveToActorGoals.Remove(0, 1);
	}
}

///////////////////////////////////////////////////////////////////////////////

// move everyone in the squad to the target.
latent function ExamineTheTarget()
{
	local int PawnIterIndex, MoveToActorIndex;
	local Pawn PawnIter;

	for(PawnIterIndex=0; PawnIterIndex<squad().pawns.length; ++PawnIterIndex)
	{
		PawnIter = squad().pawns[PawnIterIndex];

		MoveToActorGoals[MoveToActorIndex] = new class'MoveToActorGoal'(AI_Resource(PawnIter.movementAI), 80, ExamineTarget);
		assert(MoveToActorGoals[MoveToActorIndex] != None);
		MoveToActorGoals[MoveToActorIndex].AddRef();

		MoveToActorGoals[MoveToActorIndex].SetRotateTowardsPointsDuringMovement(true);
		MoveToActorGoals[MoveToActorIndex].PostGoal(self);

		++MoveToActorIndex;
	}

	waitForAllGoalsInList(MoveToActorGoals);

	// cleanup
	ClearOutMoveToGoals();
}

function ReportAboutTarget()
{
	local Pawn ReportingOfficer;
	
	ReportingOfficer = GetFirstOfficer();

	// trigger the effect event called Examined
	ExamineTarget.TriggerEffectEvent('Examined', ReportingOfficer,,,,true);	// play the event on the other (the officer)
}

state Running
{
Begin:
	WaitForZulu();

	ExamineTheTarget();
	ReportAboutTarget();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadExamineAndReportGoal'
}