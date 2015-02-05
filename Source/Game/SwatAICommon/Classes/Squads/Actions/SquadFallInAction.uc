///////////////////////////////////////////////////////////////////////////////
// SquadFallInAction.uc - SquadFallInAction class
// this action is used to organize the Officer's Fall In behavior
// - this can be considered total hack for now

class SquadFallInAction extends OfficerSquadAction
	config(AI);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// our formation for falling in
var private Formation	FallInFormation;

// our timer for replying
var private Timer		CompletedTimer;
var config float		CompletedTimerUpdateRate;
var config float		CopyCompletedTimerUpdateRate;

// config
var config float		MinDistanceToTriggerReplySpeech;
var config float		MinDistanceToTriggerCompletedSpeech;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (FallInFormation != None)
	{
		FallInFormation.Cleanup();
		FallInFormation.Release();
		FallInFormation = None;
	}

	CleanupCompletedTimer();
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// if any of our fall in goals fail, we succeed so we don't get reposted!
	if (goal.IsA('FallInGoal'))
	{
		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Death

protected function NotifyPawnDied(Pawn pawn)
{
	super.NotifyPawnDied(pawn);

	instantFail(ACT_GENERAL_FAILURE);
}

///////////////////////////////////////////////////////////////////////////////
//
// Reply Timer

private function SpawnCompletedTimer()
{
	assert(CompletedTimer == None);
	assert(CommandGiver != None);

	CompletedTimer = CommandGiver.Spawn(class'Timer');
	CompletedTimer.timerDelegate = CheckFallInCompleted;

	if (bHasBeenCopied)
	{
		CompletedTimer.startTimer(CopyCompletedTimerUpdateRate, true);
	}
	else
	{
		CompletedTimer.startTimer(CompletedTimerUpdateRate, true);
	}
}

private function bool ShouldReplyCompleted()
{
	local int i;
	local Pawn Iter;
	local bool bOneOfficerHasLineOfSightToCommandGiver;

	for(i=0; i<squad().pawns.length; ++i)
	{
		Iter = squad().pawns[i];

		// assumes that the command giver is the leader of the formation
		if (VSize(Iter.Location - CommandGiver.Location) > MinDistanceToTriggerCompletedSpeech)
		{
			return false;
		}
	}

	for(i=0; i<squad().pawns.length; ++i)
	{
		Iter = squad().pawns[i];

		if (squad().pawns[i].LineOfSightTo(CommandGiver))
		{
			bOneOfficerHasLineOfSightToCommandGiver = true;
			break;
		}
	}

	// returns true if one officer has a line of sight to the command giver
	return bOneOfficerHasLineOfSightToCommandGiver;
}

function CheckFallInCompleted()
{
	local Pawn OfficerInFront;
	if (ShouldReplyCompleted())
	{
		// the officer to say something will be the officer right in back of the leader
		OfficerInFront = FallInFormation.GetOrderedMember(0);

		// if we're a copy, let the player know which team is in position
		if (bHasBeenCopied)
		{
			OfficerTeamInfo(squad()).TriggerTeamReportedSpeech(OfficerInFront);
		}

		ISwatOfficer(OfficerInFront).GetOfficerSpeechManagerAction().TriggerCompletedFallInSpeech();

		// we no longer need the timer.
		CleanupCompletedTimer();
	}
}

private function CleanupCompletedTimer()
{
	if (CompletedTimer != None)
	{
		CompletedTimer.stopTimer();
		CompletedTimer.timerDelegate = None;
		CompletedTimer.Destroy();
		CompletedTimer = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

latent function FallInSquad()
{
	local Pawn Officer;
	local array<Pawn> FormationMembers;
	local int i;

	FallInFormation = new class'Formation'(CommandGiver);
	assert(FallInFormation != None);
	FallInFormation.AddRef();

	for(i=0; i<squad().pawns.length; ++i)
	{
		FormationMembers[FormationMembers.Length] = squad().pawns[i];
	}

	FallInFormation.AddMembers(FormationMembers);	

	for(i=0; i<squad().pawns.length; ++i)
	{
		Officer = squad().pawns[i];

		ISwatOfficer(Officer).SetCurrentFormation(FallInFormation);

		// post the fall in goal
		(new class'FallInGoal'(AI_CharacterResource(Officer.CharacterAI))).postGoal(self);
	}
}

// returns the first officer we find that is far enough away from the command giver to give the speech
// returns None if no officer is far enough away
private function Pawn FindOfficerToTriggerFallInSpeech()
{
	local int i;
	local Pawn Iter;

	for(i=0; i<squad().pawns.length; ++i)
	{
		Iter = squad().pawns[i];
		if (VSize(Iter.Location - CommandGiver.Location) >= MinDistanceToTriggerReplySpeech)
		{
			return Iter;
		}
	}

	// nobody is far enough away
	return None;
}

private function TriggerFallInSpeech()
{
	local Pawn Officer;

	Officer = FindOfficerToTriggerFallInSpeech();

	if (Officer != None)
	{
		ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerRepliedFallInSpeech();
	}
}

state Running
{
Begin:
	// we only trigger the reply speech if we're not a copy
	if (! bHasBeenCopied)
	{
		TriggerFallInSpeech();
	}

	SpawnCompletedTimer();

	WaitForZulu();

	FallInSquad();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadFallInGoal'
}