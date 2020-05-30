class HostageRoster extends Roster
	dependsOn(SwatGUIConfig);

import enum eFloatOptions from SwatGUIConfig;

function int MutateSpawnCount(int SpawnCount, SwatGUIConfig GC)
{
	// Don't change the spawn count if only one hostage will spawn.
	// These are most likely specific hostages like Gladys Fairfax
	if(Count.Min == 1 && Count.Max == 1)
	{
		return SpawnCount;
	}

	return SpawnCount * GC.ExtraFloatOptions[eFloatOptions.ExtraFloat_HostageSpawnModifier];
}

defaultproperties
{
    ArchetypeClass=class'HostageArchetype'
}
