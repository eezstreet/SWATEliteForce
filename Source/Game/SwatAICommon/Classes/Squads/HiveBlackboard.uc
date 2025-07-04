///////////////////////////////////////////////////////////////////////////////
// HiveBlackboard.uc - the HiveBlackboard class
// The Hive Blackboard is used to store shared information between the officers

class HiveBlackboard extends Core.Object
	native;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Variables

var Pawn						PlayerEnemy;
var array<Pawn>					EncounteredHostages; 
var array<Pawn>					EncounteredEnemies;
var array<Pawn>					AssignedTargets;

var array<Pawn>					CompliantAIs;
var array<Pawn>					RestrainedAIs;
var array<Pawn>					AIsBeingWatched;

var Map<NavigationPoint, Pawn>	EngagingPointMap;

///////////////////////////////////////////////////////////////////////////////
//
// Enemy / Hostage Tracking

native function UpdateHostage(Pawn Hostage);
native function UpdateEnemy(Pawn Enemy);
native function bool HasAIBeenEncountered(Pawn TestAI);

function MakePlayerEnemy(Pawn Player)
{
	assert(Player != None);

	PlayerEnemy = Player;
}

function bool IsACompliantAI(Pawn AI)
{
	local int i;

	assert(AI != None);

	for(i=0; i<CompliantAIs.Length; ++i)
	{
		if (CompliantAIs[i] == AI)
			return true;
	}

	return false;
}

function AddCompliantAI(Pawn AI)
{
	assert(AI != None);
	
	// only add the AI if they're not already on the list
	if (! IsACompliantAI(AI))
	{
		CompliantAIs[CompliantAIs.Length] = AI;
	}
}

function RemoveCompliantAI(Pawn AI)
{
	local int i;

	assert(AI != None);
	
	for(i=0; i<CompliantAIs.Length; ++i)
	{
		if (CompliantAIs[i] == AI)
		{
			CompliantAIs.Remove(i, 1);
			break;
		}
	}
}

function ValidateRestrainedAIs()
{
	local int i;

	for(i=0; i<RestrainedAIs.Length; ++i)
	{
		if (! class'Pawn'.static.checkConscious(RestrainedAIs[i]))
		{
			RestrainedAIs.Remove(i, 1);
			--i;
		}
	}
}

private function bool IsARestrainedAI(Pawn AI)
{
	local int i;
	assert(AI != None);

	for (i=0; i<RestrainedAIs.Length; ++i)
	{
		if (RestrainedAIs[i] == AI)
		{
			return true;
		}
	}

	// didn't find the AI 
	return false;
}

function AddRestrainedAI(Pawn AI)
{
	assert(AI != None);
	
	if (! IsARestrainedAI(AI))
	{
		RestrainedAIs[RestrainedAIs.Length] = AI;
	}
}

function RemoveRestrainedAI(Pawn AI)
{
	local int i;

	assert(AI != None);
	
	for(i=0; i<RestrainedAIs.Length; ++i)
	{
		if (RestrainedAIs[i] == AI)
		{
			RestrainedAIs.Remove(i, 1);
			break;
		}
	}
}

function AddWatchedAI(Pawn AI)
{
	assert(AI != None);
	assert(! IsAIBeingWatched(AI));

	AIsBeingWatched[AIsBeingWatched.Length] = AI;
}

function RemoveWatchedAI(Pawn AI)
{
	local int i;

	assert(AI != None);

	for(i=0; i<AIsBeingWatched.Length; ++i)
	{
		if (AIsBeingWatched[i] == AI)
		{
			AIsBeingWatched.Remove(i, 1);
			break;
		}
	}
}

function bool IsAIBeingWatched(Pawn AI)
{
	local int i;

	assert(AI != None);

	for(i=0; i<AIsBeingWatched.Length; ++i)
	{
		if (AIsBeingWatched[i] == AI)
			return true;
	}

	return false;
}

function AddAssignedTarget(Pawn AI)
{
	assert(AI != None);

	// only add new assignments
	if (! IsAnAssignedTarget(AI))
	{
		AssignedTargets[AssignedTargets.Length] = AI;
	}
}

function bool AreAnyAssignedTargetsThreatening()
{
	local int i;

	for(i=0; i<AssignedTargets.Length; ++i)
	{
		if (AssignedTargets[i].IsA('SwatEnemy') && ISwatEnemy(AssignedTargets[i]).IsAThreat())
			return true;
	}

	return false;
}

function bool AreAnyAssignedTargetsSuspects()
{
	local int i;

	for (i = 0; i < AssignedTargets.Length; i++)
	{
		if (AssignedTargets[i].IsA('SwatEnemy'))
		{
			return true;
		}
	}

	return false;
}

function RemoveAssignedTarget(Pawn AI)
{
	local int i;

	for(i=0; i<AssignedTargets.Length; ++i)
	{
		if (AssignedTargets[i] == AI)
		{
			AssignedTargets.Remove(i, 1);
			break;
		}
	}
}

function bool IsAnAssignedTarget(Pawn AI)
{
	local int i;

	assert(AI != None);

	for(i=0; i<AssignedTargets.Length; ++i)
	{
		if (AssignedTargets[i] == AI)
			return true;
	}

	return false;
}