///////////////////////////////////////////////////////////////////////////////
// SquadSecureAction.uc - SquadSecureAction class
// this action is used to organize the Officer's Restrain & Secure Evidence behavior

class SquadSecureAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private array<Pawn>						AvailableOfficers;
var private array<RestrainAndReportGoal>	CurrentRestrainAndReportGoals;
var private array<SecureEvidenceGoal>		CurrentSecureEvidenceGoals;
var private array<DisableTargetGoal>		CurrentDisableTargetGoals;

var private array<Actor>					TargetsBeingSecured;


///////////////////////////////////////////////////////////////////////////////
//
// Death

protected function NotifyPawnDied(Pawn pawn)
{
	local int i;

	super.NotifyPawnDied(pawn);

	for(i=0; i<AvailableOfficers.Length; ++i)
	{
		if (AvailableOfficers[i] == Pawn)
		{
			AvailableOfficers.Remove(i,1);
			break;
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	ClearOutRestrainAndReportGoals();
	ClearOutSecureEvidenceGoals();
	ClearOutDisableTargetGoals();

	CopyTargetsBeingSecuredToGoal();
}

private function ClearOutRestrainAndReportGoals()
{
	while (CurrentRestrainAndReportGoals.Length > 0)
	{
		if (CurrentRestrainAndReportGoals[0] != None)
		{
			CurrentRestrainAndReportGoals[0].Release();
			CurrentRestrainAndReportGoals.Remove(0, 1);
		}
	}
}

private function ClearOutSecureEvidenceGoals()
{
	while (CurrentSecureEvidenceGoals.Length > 0)
	{
		if (CurrentSecureEvidenceGoals[0] != None)
		{
			CurrentSecureEvidenceGoals[0].Release();
			CurrentSecureEvidenceGoals.Remove(0, 1);
		}
	}
}

private function ClearOutDisableTargetGoals()
{
	while(CurrentDisableTargetGoals.Length > 0)
	{
		if(CurrentDisableTargetGoals[0] != None)
		{
			CurrentDisableTargetGoals[0].Release();
			CurrentDisableTargetGoals.Remove(0, 1);
		}
	}
}

function CopyTargetsBeingSecuredToGoal()
{
	while (TargetsBeingSecured.Length > 0)
	{
		AddSecureTarget(TargetsBeingSecured[0]);

		TargetsBeingSecured.Remove(0, 1);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Helper Functions

function AddSecureTarget(Actor SecureTarget)
{
	SquadSecureGoal(achievingGoal).AddSecureTarget(SecureTarget);
}

function int GetNumSecureTargets()
{
	return SquadSecureGoal(achievingGoal).GetNumSecureTargets();
}

function bool IsSuspect(Actor SuspectTarget)
{
	return ISwatEnemy(SuspectTarget) != None;
}

function bool IsCivilian(Actor CivilianTarget)
{
	return ISwatHostage(CivilianTarget) != None;
}

function bool IsDisableable(Actor DisableableTarget)
{
	return DisableableTarget.IsA('IDisableableByAI');
}

function bool IsEvidence(Actor SecureTarget)
{
	return SecureTarget.IsA('IEvidence');
}

function bool PickBestFromList(array<Actor> ActorList, out Actor BestActor)
{
	local int i, j;
	local float BestLength, IterLength;
	local Pawn IterOfficer;

	if (ActorList.Length <= 0)
	{	// no actors...
		return false;
	}

	if (ActorList.Length == 1)
	{	// only one actor in this list, this must be the best
		BestActor = ActorList[0];
		return true;
	}

	ValidateAvailableOfficers();
	if (AvailableOfficers.Length == 0)
	{	// no available officers to handle this?
		return false;
	}

	for (i = 0; i < ActorList.Length; i++)
	{
		// On each actor, find the closest officer available and the distance
		for (j = 0; j < AvailableOfficers.Length; j++)
		{
			IterOfficer = AvailableOfficers[j];
			IterLength = IterOfficer.GetPathfindingDistanceToActor(ActorList[i], true);

			if (BestActor == None || IterLength < BestLength)
			{
				BestActor = ActorList[i];
				BestLength = IterLength;
			}
		}
	}

	return true;
}

function Actor GetNextSecureTarget()
{
	local array<Actor> SecureTargetsAvailable;
	local array<Actor> SuspectsAvailable;
	local array<Actor> CiviliansAvailable;
	local array<Actor> DisableablesAvailable;
	local array<Actor> EvidenceAvailable;
	local SquadSecureGoal SecureGoal;
	local int i;
	local Actor BestActor;

	SecureGoal = SquadSecureGoal(achievingGoal);
	SecureGoal.ValidateSecureTargets();
	SecureTargetsAvailable = SecureGoal.GetSecureTargets();

	// Populate list of suspects, civilians, disableables, evidence
	for (i = 0; i < SecureTargetsAvailable.Length; i++)
	{
		if (IsSuspect(SecureTargetsAvailable[i]))
		{
			SuspectsAvailable[SuspectsAvailable.Length] = SecureTargetsAvailable[i];
		}
		else if (IsCivilian(SecureTargetsAvailable[i]))
		{
			CiviliansAvailable[CiviliansAvailable.Length] = SecureTargetsAvailable[i];
		}
		else if (IsDisableable(SecureTargetsAvailable[i]))
		{
			DisableablesAvailable[DisableablesAvailable.Length] = SecureTargetsAvailable[i];
		}
		else if (IsEvidence(SecureTargetsAvailable[i]))
		{
			EvidenceAvailable[EvidenceAvailable.Length] = SecureTargetsAvailable[i];
		}
	}

	// Pick from suspects available, but prioritize closest one
	if (PickBestFromList(SuspectsAvailable, BestActor) ||
		PickBestFromList(DisableablesAvailable, BestActor) ||
		PickBestFromList(CiviliansAvailable, BestActor) ||
		PickBestFromList(EvidenceAvailable, BestActor))
	{
		return BestActor;
	}

	// hm...
	return None;
}

function RemoveSecureTarget(Actor SecureTarget)
{
	SquadSecureGoal(achievingGoal).RemoveSecureTarget(SecureTarget);
}

private function AddTargetBeingSecured(Actor SecureTarget)
{
	assert(! IsTargetBeingSecured(SecureTarget));
	TargetsBeingSecured[TargetsBeingSecured.Length] = SecureTarget;
}

private function RemoveTargetBeingSecured(Actor SecureTarget)
{
	local int i;

	log("RemoveTargetBeingSecured called on " $ SecureTarget);

	assert(IsTargetBeingSecured(SecureTarget));

	for(i=0; i<TargetsBeingSecured.Length; ++i)
	{
		if (TargetsBeingSecured[i] == SecureTarget)
		{
			TargetsBeingSecured.Remove(i, 1);
			break;
		}
	}
}

function bool IsTargetBeingSecured(Actor SecureTarget)
{
	local int i;

	for(i=0; i<TargetsBeingSecured.Length; ++i)
	{
		if (TargetsBeingSecured[i] == SecureTarget)
		{
			return true;
		}
	}

	return false;
}

///////////////////////////////////////////////////////////////////////////////
//
// Notifications from Our Goal

function NotifyNewSecureTarget()
{
	if (isIdle())
		runAction();
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion Callbacks

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	local RestrainAndReportGoal AchievedRestrainAndReportGoal;
	local SecureEvidenceGoal AchievedSecureEvidenceGoal;
	local DisableTargetGoal AchievedDisableTargetGoal;

	super.goalAchievedCB(goal, child);

	if (resource.pawn().logTyrion)
		log("Squad R&R goal achieved was: " $ goal.Name $ " goal.IsA('RestrainAndReportGoal'): "$goal.IsA('RestrainAndReportGoal'));

	// FIXME: I feel like there is a huge amount of code reuse here. Should maybe refactor this --eez
	if (goal.IsA('RestrainAndReportGoal'))
	{
		assert(AI_CharacterResource(goal.resource).m_Pawn != None);

		AchievedRestrainAndReportGoal = RestrainAndReportGoal(goal);

		RemoveTargetBeingSecured(AchievedRestrainAndReportGoal.CompliantTarget);
		RemoveRestrainAndReportGoal(AchievedRestrainAndReportGoal);

		MakeOfficerAvailable(AI_CharacterResource(goal.resource).m_Pawn);

		if (isIdle())
			runAction();
	}
	else if (goal.IsA('SecureEvidenceGoal'))
	{
		assert(AI_CharacterResource(goal.resource).m_Pawn != None);

		AchievedSecureEvidenceGoal = SecureEvidenceGoal(goal);

		RemoveTargetBeingSecured(Actor(AchievedSecureEvidenceGoal.EvidenceTarget));
		RemoveSecureEvidenceGoal(AchievedSecureEvidenceGoal);

		MakeOfficerAvailable(AI_CharacterResource(goal.resource).m_Pawn);

		if (isIdle())
			runAction();
	}
	else if (goal.IsA('DisableTargetGoal'))
	{
		assert(AI_CharacterResource(goal.resource).m_Pawn != None);

		AchievedDisableTargetGoal = DisableTargetGoal(goal);

		RemoveTargetBeingSecured(AchievedDisableTargetGoal.Target);
		RemoveDisableTargetGoal(AchievedDisableTargetGoal);

		MakeOfficerAvailable(AI_CharacterResource(goal.resource).m_Pawn);

		if(isIdle())
			runAction();
	}
}

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	local RestrainAndReportGoal NotAchievedRestrainAndReportGoal;
	local SecureEvidenceGoal NotAchievedSecureEvidenceGoal;
	local DisableTargetGoal NotAchievedDisableTargetGoal;
	local Pawn Officer;

	super.goalNotAchievedCB(goal, child, errorCode);


	// FIXME: This function, like goalAchievedCB, has a ton of code reuse. Consider refactoring this.
	if (goal.IsA('RestrainAndReportGoal'))
	{
		NotAchievedRestrainAndReportGoal = RestrainAndReportGoal(goal);

		Officer = AI_CharacterResource(goal.resource).m_Pawn;

		// add the target who wasn't restrained back in, if we failed because we couldn't get to them
		if (errorCode != ACT_CANT_FIND_PATH)
		{
			RemoveTargetBeingSecured(NotAchievedRestrainAndReportGoal.CompliantTarget);
			AddSecureTarget(NotAchievedRestrainAndReportGoal.CompliantTarget);

			if (isIdle())
				runAction();
		}

		RemoveRestrainAndReportGoal(NotAchievedRestrainAndReportGoal);

		if (class'Pawn'.static.checkConscious(Officer))
		{
			MakeOfficerAvailable(Officer);
		}
	}
	else if (goal.IsA('SecureEvidenceGoal'))
	{
		NotAchievedSecureEvidenceGoal = SecureEvidenceGoal(goal);

		Officer = AI_CharacterResource(goal.resource).m_Pawn;

		// add the target who wasn't restrained back in, if we failed because we couldn't get to them
		if (errorCode != ACT_CANT_FIND_PATH)
		{
			RemoveTargetBeingSecured(Actor(NotAchievedSecureEvidenceGoal.EvidenceTarget));
			AddSecureTarget(Actor(NotAchievedSecureEvidenceGoal.EvidenceTarget));

			if (isIdle())
				runAction();
		}

		RemoveSecureEvidenceGoal(NotAchievedSecureEvidenceGoal);

		if (class'Pawn'.static.checkConscious(Officer))
		{
			MakeOfficerAvailable(Officer);
		}
	}
	else if(goal.IsA('DisableTargetGoal'))
	{
		NotAchievedDisableTargetGoal = DisableTargetGoal(goal);

		Officer = AI_CharacterResource(goal.resource).m_Pawn;

		// add the target who wasn't disabled back in, if we failed because we couldn't get to them
		if(errorCode != ACT_CANT_FIND_PATH)
		{
			RemoveTargetBeingSecured(NotAchievedDisableTargetGoal.Target);
			AddSecureTarget(NotAchievedDisableTargetGoal.Target);

			if(isIdle())
				runAction();
		}

		RemoveDisableTargetGoal(NotAchievedDisableTargetGoal);

		if (class'Pawn'.static.checkConscious(Officer))
		{
			MakeOfficerAvailable(Officer);
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Character Goals

function RemoveRestrainAndReportGoal(RestrainAndReportGoal Goal)
{
	local int i;

	for(i=0; i<CurrentRestrainAndReportGoals.Length; ++i)
	{
		if (CurrentRestrainAndReportGoals[i] == Goal)
		{
			CurrentRestrainAndReportGoals[i].unPostGoal(self);
			CurrentRestrainAndReportGoals[i].Release();
			CurrentRestrainAndReportGoals.Remove(i, 1);
			break;
		}
	}
}

function RemoveSecureEvidenceGoal(SecureEvidenceGoal Goal)
{
	local int i;

	for(i=0; i<CurrentSecureEvidenceGoals.Length; ++i)
	{
		if (CurrentSecureEvidenceGoals[i] == Goal)
		{
			CurrentSecureEvidenceGoals[i].unPostGoal(self);
			CurrentSecureEvidenceGoals[i].Release();
			CurrentSecureEvidenceGoals.Remove(i, 1);
			break;
		}
	}
}

function RemoveDisableTargetGoal(DisableTargetGoal Goal)
{
	local int i;

	for(i = 0; i < CurrentDisableTargetGoals.Length; i++)
	{
		if(CurrentDisableTargetGoals[i] == Goal)
		{
			CurrentDisableTargetGoals[i].unPostGoal(self);
			CurrentDisableTargetGoals[i].Release();
			CurrentDisableTargetGoals.Remove(i, 1);
			break;
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Available Officers

private function PopulateAvailableOfficers()
{
	local int i;

	for(i=0; i<squad().pawns.length; ++i)
	{
		AvailableOfficers[AvailableOfficers.Length] = squad().pawns[i];
	}
}

private function MakeOfficerAvailable(Pawn Officer)
{
	assert(Officer != None);

	AvailableOfficers[AvailableOfficers.Length] = Officer;
}

private function MakeOfficerUnavailable(Pawn Officer)
{
	local int i;

	for(i=0; i<AvailableOfficers.Length; ++i)
	{
		if (AvailableOfficers[i] == Officer)
		{
			AvailableOfficers.Remove(i, 1);
			break;
		}
	}
}

private function bool AreAnyOfficersAvailable()
{
	ValidateAvailableOfficers();
	return (AvailableOfficers.Length > 0);
}

private function ValidateAvailableOfficers()
{
	local int i;

	for(i=0; i<AvailableOfficers.Length; ++i)
	{
		if (! class'Pawn'.static.checkConscious(AvailableOfficers[i]))
		{
			AvailableOfficers.Remove(i,1);
		}
	}
}

private function Pawn GetClosestAvailableOfficerToTarget(Actor Target)
{
	local int i;
	local float IterDistance, ClosestDistance;
	local Pawn IterOfficer, ClosestOfficer;

	ValidateAvailableOfficers();

	for(i=0; i<AvailableOfficers.Length; ++i)
	{
		IterOfficer = AvailableOfficers[i];
		IterDistance = IterOfficer.GetPathfindingDistanceToActor(Target, true);

		if ((ClosestOfficer == None) || (IterDistance < ClosestDistance))
		{
			ClosestOfficer  = IterOfficer;
			ClosestDistance = IterDistance;
		}
	}

	return ClosestOfficer;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// tells the closest officer with handcuffs to restrain the target pawn
latent function RestrainAndReportOnTarget(Pawn RestrainTarget)
{
	local Pawn Officer;
	local RestrainAndReportGoal CurrentRestrainAndReportGoal;

	assert(RestrainTarget != None);

	Officer = GetClosestAvailableOfficerToTarget(RestrainTarget);
	MakeOfficerUnavailable(Officer);

	CurrentRestrainAndReportGoal = new class'RestrainAndReportGoal'(AI_Resource(Officer.characterAI), RestrainTarget);
	assert(CurrentRestrainAndReportGoal != None);
	CurrentRestrainAndReportGoal.AddRef();
	CurrentRestrainAndReportGoals[CurrentRestrainAndReportGoals.Length] = CurrentRestrainAndReportGoal;

	CurrentRestrainAndReportGoal.postGoal(self);
}

// tells the closest officer to secure the target evidence
latent function SecureEvidence(IEvidence SecureEvidenceTarget)
{
	local Pawn Officer;
	local SecureEvidenceGoal CurrentSecureEvidenceGoal;

	assert(SecureEvidenceTarget != None);

	Officer = GetClosestAvailableOfficerToTarget(Actor(SecureEvidenceTarget));
	MakeOfficerUnavailable(Officer);

	CurrentSecureEvidenceGoal = new class'SecureEvidenceGoal'(AI_Resource(Officer.characterAI), SecureEvidenceTarget);
	assert(CurrentSecureEvidenceGoal != None);
	CurrentSecureEvidenceGoal.AddRef();
	CurrentSecureEvidenceGoals[CurrentSecureEvidenceGoals.Length] = CurrentSecureEvidenceGoal;

	CurrentSecureEvidenceGoal.postGoal(self);
}

// tells the closest officer to disable the target actor
latent function DisableTarget(Actor DisableTarget)
{
	local Pawn Officer;
	local DisableTargetGoal CurrentDisableTargetGoal;

	assert(DisableTarget != None);

	Officer = GetClosestAvailableOfficerToTarget(DisableTarget);
	MakeOfficerUnavailable(Officer);

	CurrentDisableTargetGoal = new class'DisableTargetGoal'(AI_Resource(Officer.characterAI), DisableTarget);
	assert(CurrentDisableTargetGoal != None);
	CurrentDisableTargetGoal.AddRef();
	CurrentDisableTargetGoals[CurrentDisableTargetGoals.Length] = CurrentDisableTargetGoal;

	CurrentDisableTargetGoal.postGoal(self);
}

latent function SecureCurrentTargets()
{
	local Actor IterTarget;

	if (resource.pawn().logAI)
		log("SecureCurrentTargets - GetNumSecureTargets():" $ GetNumSecureTargets() $ " AreAnyOfficersAvailable(): " $ AreAnyOfficersAvailable());

	while(AreAnyOfficersAvailable())
	{
		IterTarget = GetNextSecureTarget();
		if (IterTarget == None)
		{
			break;
		}

		// only secure a target if it's not already being secured
		if (! IsTargetBeingSecured(IterTarget))
		{
			if (IterTarget.IsA('Pawn'))
			{
				RestrainAndReportOnTarget(Pawn(IterTarget));
			}
			else if(IsDisableable(IterTarget))
			{
				DisableTarget(IterTarget);
			}
			else
			{
				assert(IsEvidence(IterTarget));

				SecureEvidence(IEvidence(IterTarget));
			}

			AddTargetBeingSecured(IterTarget);
		}

		RemoveSecureTarget(IterTarget);
	}
}

private function TriggerReplyToOrderSpeech()
{
	local Pawn ClosestOfficerToCommandGiver;

	ClosestOfficerToCommandGiver = GetClosestOfficerTo(CommandGiver, false, false);

	if (ClosestOfficerToCommandGiver != None)
	{
		// trigger a generic reply
		ISwatOfficer(ClosestOfficerToCommandGiver).GetOfficerSpeechManagerAction().TriggerGenericOrderReplySpeech();
	}
}

state Running
{
Begin:
	PopulateAvailableOfficers();

	if (! bHasBeenCopied)
		TriggerReplyToOrderSpeech();

	WaitForZulu();

	// while there are still targets left, or if there is still securing going on
	while ((GetNumSecureTargets() > 0)
				|| (CurrentRestrainAndReportGoals.Length > 0)
				|| (CurrentSecureEvidenceGoals.Length > 0)
				|| (CurrentDisableTargetGoals.Length > 0))
	{
		SecureCurrentTargets();

		if (resource.pawn().logTyrion)
			log("pausing Squad securing");

		pause();

		// wait one tick before continuing to allow things to clean up
		yield();
	}

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadSecureGoal'
}
