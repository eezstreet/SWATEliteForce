class CustomScenarioAdvancedHostageRoster extends HostageRoster;

function Actor PickAndSpawnArchetype(Spawner Spawner, CustomScenario CustomScenario, bool bTesting, optional int RosterNumber)
{
	// FIXME: this is a giant re-use of already-existing code in Archetype.static.PickArchetype. Do this cleanly, damn it!
	local name Archetype;
	local Actor Spawned;
	local int TotalChance;
    local int RandChance;
    local int AccumulatedChance;
    local Archetype.ChanceArchetypePair Picked;
    local int i;
    
    if (Archetypes.length == 0)
    {
        log("[ARCHETYPE] .. (no Archetypes specified)");
        return None;
    }
    
    //calculate the sum of chances of the Archetypes
    for (i=0; i<Archetypes.length; ++i)
        TotalChance += Archetypes[i].Chance;

    RandChance = Rand(TotalChance);

    //find the selected Archetype
    for (i=0; i<Archetypes.length; ++i)
    {
        AccumulatedChance += Archetypes[i].Chance;
        
        if (AccumulatedChance >= RandChance)
        {
            Picked = Archetypes[i];

            log("[ARCHETYPE] .. picked "$Picked.Archetype$" (Chance="$Picked.Chance$" out of "$TotalChance$" total) for roster "$RosterNumber);

            //we found our archetype
            break;
        }
    }

    if(i == Archetypes.Length)
    {
    	log("[ARCHETYPE] .. some sort of fucked up logic here!!");
    	return None;
    }

	Archetype = class'Archetype'.static.PickArchetype(Archetypes);
	Spawned = Spawner.SpawnArchetype(Picked.Archetype, bTesting, CustomScenario, RosterNumber, i);

	return Spawned;
}