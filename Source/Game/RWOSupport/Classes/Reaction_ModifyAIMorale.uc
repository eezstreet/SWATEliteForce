class Reaction_ModifyAIMorale extends Reaction;

var(Reaction) range				MoraleModicationAmount "This range will be used to add or subtract from the AI's current morale";
var(Reaction) array<name>		SpawnerGroups "Specify one or multiple SpawnerGroups whose members you want to modify their morale";

enum MoraleModAIType
{
	HostageAndEnemy,
	EnemyOnly,
	HostageOnly
};

var(Reaction) MoraleModAIType	ModificationAIType "The type of AI we will be modifying the morale of";

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

private function bool ShouldModifyMorale(Pawn AI)
{
	// test the spawner group if we need to
	if (SpawnerGroups.Length > 0)
	{
		if (AI.IsA('SwatEnemy'))
		{
			if (! IsOnSpawnerGroupsList(ISwatEnemy(AI).SpawnedFromGroup()))
			{
				return false;
			}
		}
		else if (AI.IsA('SwatHostage'))
		{
			if (! IsOnSpawnerGroupsList(ISwatHostage(AI).SpawnedFromGroup()))
			{
				return false;
			}
		}
	}

	// test the class type based on the designer's specified AI type(s)
	switch(ModificationAIType)
	{
		case HostageAndEnemy:
			return (AI.IsA('SwatEnemy') || AI.IsA('SwatHostage'));
		case EnemyOnly:
			return (AI.IsA('SwatEnemy'));
		case HostageOnly:
			return (AI.IsA('SwatHostage'));
	}
}

private function ModifyMoraleOf(Pawn AI)
{
	local float RandomMoraleChange;

	RandomMoraleChange = RandRange(MoraleModicationAmount.Min, MoraleModicationAmount.Max);

	ISwatAI(AI).GetCommanderAction().ChangeMorale(RandomMoraleChange, "Morale changed by Reaction_ModifyAIMorale"@Name@"at time"@AI.Level.TimeSeconds);
}

protected function Execute(Actor Owner, Actor Other)
{
	local Pawn PawnIter;
	for (PawnIter = Owner.Level.pawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
	{
		if (ShouldModifyMorale(PawnIter))
		{
			ModifyMoraleOf(PawnIter);
		}
	}
}
