///////////////////////////////////////////////////////////////////////////////
// SquadDeployLightstickAction.uc - SquadDeployLightstickAction class
// this action is used to organize the Officer's DeployLightstick behavior

class SquadDeployLightstickAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private array<Pawn>						AvailableOfficers;
var private array<DropLightstickGoal>		CurrentDropLightstickGoals;

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

	ClearOutDropLightstickGoals();

//	CopyTargetsBeingSecuredToGoal();
}

private function ClearOutDropLightstickGoals()
{
	while (CurrentDropLightstickGoals.Length > 0)
	{
		if (CurrentDropLightstickGoals[0] != None)
		{
			CurrentDropLightstickGoals[0].Release();
			CurrentDropLightstickGoals.Remove(0, 1);
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Helper Functions

function AddDropPoint(vector DropPoint)
{
	SquadDeployLightstickGoal(achievingGoal).AddDropPoint(DropPoint);
}

function int GetNumDropPoints()
{
	return SquadDeployLightstickGoal(achievingGoal).GetNumDropPoints();
}

function vector GetDropPoint(int DropPointIndex)
{
	return SquadDeployLightstickGoal(achievingGoal).GetDropPoint(DropPointIndex);
}

function RemoveDropPoint(vector DropPoint)
{
	SquadDeployLightstickGoal(achievingGoal).RemoveDropPoint(DropPoint);
}

function bool IsDropPointBeingServiced(vector DropPoint)
{
	local int i;

	for(i=0; i<CurrentDropLightstickGoals.Length; ++i)
	{
		if (CurrentDropLightstickGoals[i].DropPoint == DropPoint)
		{
			return true;
		}
	}

	return false;
}


///////////////////////////////////////////////////////////////////////////////
//
// Notifications from Our Goal

function NotifyNewDropPoint()
{
	if (isIdle())
		runAction();
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion Callbacks

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	local DropLightstickGoal AchievedDropLightstickGoal;

	super.goalAchievedCB(goal, child);

	if (resource.pawn().logTyrion)
		log("Squad R&R goal achieved was: " $ goal.Name $ " goal.IsA('DeployLightstickGoal'): "$goal.IsA('DeployLightstickGoal'));

	assert(AI_CharacterResource(goal.resource).m_Pawn != None);

	AchievedDropLightstickGoal = DropLightstickGoal(goal);

	RemoveDropLightstickGoal(AchievedDropLightstickGoal);

	MakeOfficerAvailable(AI_CharacterResource(goal.resource).m_Pawn);

	if (isIdle())
		runAction();
}

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	local DropLightstickGoal NotAchievedDropLightstickGoal;
	local Pawn Officer;

	super.goalNotAchievedCB(goal, child, errorCode);

	NotAchievedDropLightstickGoal = DropLightstickGoal(goal);

	Officer = AI_CharacterResource(goal.resource).m_Pawn;

	// add the target who wasn't restrained back in, if we failed because we couldn't get to them
	//if (errorCode != ACT_CANT_FIND_PATH)
	//{
	//	RemoveTargetBeingSecured(Actor(NotAchievedSecureEvidenceGoal.EvidenceTarget));
	//	AddSecureTarget(Actor(NotAchievedSecureEvidenceGoal.EvidenceTarget));
	//	if (isIdle())
	//		runAction();
	//}

	RemoveDropLightstickGoal(NotAchievedDropLightstickGoal);

	if (class'Pawn'.static.checkConscious(Officer))
	{
		MakeOfficerAvailable(Officer);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Character Goals

function RemoveDropLightstickGoal(DropLightstickGoal Goal)
{
	local int i;

	for(i=0; i<CurrentDropLightstickGoals.Length; ++i)
	{
		if (CurrentDropLightstickGoals[i] == Goal)
		{
			CurrentDropLightstickGoals[i].unPostGoal(self);
			CurrentDropLightstickGoals[i].Release();
			CurrentDropLightstickGoals.Remove(i, 1);
			break;
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Available Officers (copied from "SquadSecureAction")
// (only necessary if a squad can delpoy several lightsticks at once)

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

private function Pawn GetClosestAvailableOfficerToTarget(vector Destination)
{
	local int i;
	local float IterDistance, ClosestDistance;
	local Pawn IterOfficer, ClosestOfficer;

	ValidateAvailableOfficers();

	for(i=0; i<AvailableOfficers.Length; ++i)
	{
		IterOfficer = AvailableOfficers[i];
		IterDistance = IterOfficer.GetPathfindingDistanceToPoint(Destination, true);

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

// tells the closest non-busy officer to drop a lightstick at the specified location
latent function DropLightstick(vector DropPoint)
{
	local Pawn Officer;
	local DropLightstickGoal CurrentDropLightStickGoal;

	Officer = GetClosestAvailableOfficerToTarget(DropPoint);
	MakeOfficerUnavailable(Officer);

	CurrentDropLightstickGoal = new class'DropLightstickGoal'(AI_Resource(Officer.characterAI), DropPoint);
	CurrentDropLightStickGoal.SetPlaySpeech(SquadDeployLightstickGoal(achievingGoal).GetPlaySpeech());
	assert(CurrentDropLightstickGoal != None);
	CurrentDropLightstickGoal.AddRef();
	CurrentDropLightstickGoals[CurrentDropLightstickGoals.Length] = CurrentDropLightstickGoal;

	CurrentDropLightstickGoal.postGoal(self);
}


latent function DropLightsticksAtDropPoints()
{
	local vector IterTarget;

	if (resource.pawn().logAI)
		log("DropLightsticksAtDropPoints - GetNumDropPoints():" $ GetNumDropPoints() $ " AreAnyOfficersAvailable(): " $ AreAnyOfficersAvailable());

	while((GetNumDropPoints() > 0) && AreAnyOfficersAvailable())
	{
		IterTarget = GetDropPoint(0);

		// only secure a target if it's not already being secured
		if (! IsDropPointBeingServiced(IterTarget))
		{
			DropLightstick(IterTarget);
		}

		RemoveDropPoint(IterTarget);
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
	
	if (! bHasBeenCopied && SquadDeployLightstickGoal(achievingGoal).GetPlaySpeech())
		TriggerReplyToOrderSpeech();

	WaitForZulu();

	// while there are still targets left, or if there is still dropping going on
	while (GetNumDropPoints() > 0 || CurrentDropLightstickGoals.Length > 0)
	{
		DropLightsticksAtDropPoints();

		if (resource.pawn().logTyrion)
			log("pausing lightstick dropping");

		pause();

		// wait one tick before continuing to allow things to clean up
		yield();
	}

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadDeployLightstickGoal'
}