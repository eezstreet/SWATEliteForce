class Reaction_AlertAIs extends Reaction;

var(Reaction) array<name>		SpawnerGroups "Specify one or multiple SpawnerGroups whose members that you want to alert";


private function bool IsOnSpawnerGroupsList(name TestSpawnerGroup)
{
	local int i;

	for(i=0; i<SpawnerGroups.Length; ++i)
	{
		if (SpawnerGroups[i] == TestSpawnerGroup)
		{
			return true;
		}
	}

	// didn't find it in the list
	return false;
}

// if the AI is an enemy, and 
private function bool ShouldAlertAI(Pawn AI)
{
	return (AI.IsA('SwatEnemy') &&
			((SpawnerGroups.Length == 0) || IsOnSpawnerGroupsList(ISwatEnemy(AI).SpawnedFromGroup())));
}

private function AlertAI(Pawn AI)
{
	assert(AI.IsA('SwatEnemy'));

	ISwatEnemy(AI).BecomeAware();
}

protected function Execute(Actor Owner, Actor Other)
{
    local Pawn PawnIter;
	for (PawnIter = Owner.Level.pawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
	{
		if (ShouldAlertAI(PawnIter))
		{
			AlertAI(PawnIter);
		}
	}
}
