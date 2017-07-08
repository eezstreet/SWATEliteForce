///////////////////////////////////////////////////////////////////////////////
// SquadCoverAction.uc - SquadCoverAction class
// this action is used to organize the Officer's cover behavior

class SquadCoverAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors
var private array<CoverGoal>	CoverGoals;

// copied from our goal
var(parameters) vector			CoverLocation;

// internal
var private LevelInfo			Level;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.Cleanup();

	CleanupCoverGoals();
}

private function CleanupCoverGoals()
{
	while (CoverGoals.Length > 0)
	{
		if (CoverGoals[0] != None)
		{
			CoverGoals[0].Release();
			CoverGoals[0] = None;
		}

		CoverGoals.Remove(0, 1);
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// State code

private function NavigationPoint GetClosestCoverFromPoint(Pawn Officer, NavigationPointList PointsInRoomThatCanHitCoverLocation)
{
	local int i;
	local NavigationPoint Iter, ClosestPoint;
	local float ClosestDistance, IterDistance;

	for(i=0; i<PointsInRoomThatCanHitCoverLocation.GetSize(); ++i)
	{
		Iter         = PointsInRoomThatCanHitCoverLocation.GetEntryAt(i);
		IterDistance = VSize(Officer.Location - Iter.Location);

		if ((ClosestPoint == None) || (IterDistance < ClosestDistance))
		{
			ClosestPoint    = Iter;
			ClosestDistance = IterDistance;
		}
	}

	if (ClosestPoint != None)
		PointsInRoomThatCanHitCoverLocation.Remove(ClosestPoint);

	return ClosestPoint;
}

private latent function CreateCoverGoals()
{
	local int i, NextOpenIndex;
	local Pawn Officer;
	local bool AimAround;
	local SwatAIRepository SwatAIRepo;
	local NavigationPointList PointsInRoomThatCanHitCoverLocation;
	local name CoverFromRoomName;
	local NavigationPoint CoverFromNavigationPoint;
	local vector CoverFromPoint;

	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	CoverFromRoomName = SwatAIRepo.GetClosestRoomNameToPoint(CommandOrigin, CommandGiver);
	yield();

	assert(SwatAIRepo != None);
	PointsInRoomThatCanHitCoverLocation = SwatAIRepo.GetNavigationPointsInRoomThatCanHitPoint(CoverFromRoomName, CoverLocation);
	yield();

	for(i=0; i<squad().pawns.length; ++i)
	{
		Officer = squad().pawns[i];

		CoverFromNavigationPoint = GetClosestCoverFromPoint(Officer, PointsInRoomThatCanHitCoverLocation);

		if (CoverFromNavigationPoint == None)
			CoverFromPoint = CommandOrigin;
		else
			CoverFromPoint = CoverFromNavigationPoint.Location;

		NextOpenIndex = CoverGoals.Length;
		CoverGoals[NextOpenIndex] = new class'CoverGoal'(AI_Resource(Officer.CharacterAI), CoverLocation, CommandOrigin, CoverFromPoint, AimAround);
		assert(CoverGoals[NextOpenIndex] != None);
		CoverGoals[NextOpenIndex].AddRef();

		CoverGoals[NextOpenIndex].postGoal(Self);

		// after telling one officer to aim at the point, we let the other officers aim around at that point
		AimAround = true;

		yield();
	}

	SwatAIRepo.ReleaseNavigationPointList(PointsInRoomThatCanHitCoverLocation);
}

protected function TriggerCoverReplySpeech()
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
	Level = resource.pawn().Level;
	assert(Level != None);

	WaitForZulu();

	TriggerCoverReplySpeech();
	CreateCoverGoals();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadCoverGoal'
}
