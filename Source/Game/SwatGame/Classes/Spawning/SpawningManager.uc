class SpawningManager extends Core.Object implements Engine.ISpawningManager
    editinlinenew
    hidecategories(object)
    collapsecategories;

import enum EStartPointDependent from Spawner;
import enum EEntryType from SwatGame.SwatStartPointBase;
import enum eDifficultyLevel from SwatGUIConfig;

////////////////////////////////////////////////////////////////////
// NOTE: Dynamic class variables should be reset to their initial state
//    in ResetForMPQuickRestart()
////////////////////////////////////////////////////////////////////

var (Swat) editinline array<Roster> Rosters;
var (Swat) editinline array<MPRoster> MPRosters;

var private LevelInfo Level;

var bool HasSpawned;
var array<Spawner> UnallocatedSpawners;

var private Roster CurrentRoster;               //the Roster we're currently spawning from, or None if we're not currently spawning from Rosters

const NUM_ARCHETYPE_CATEGORIES = 3;

function Initialize(LevelInfo inLevel)
{
    Level = inLevel;
}

//returns results as an array of ints, each index is the total of EArchetypeCategory spawned
//  (ie. enemies, hostages, etc.)
function array<int> DoSpawning(SwatGameInfo Game, optional bool bTesting)
{
    local Spawner Spawner;
    local name Archetype;
    local array<Spawner> CandidateSpawners;
    local int Count;
    local int SelectedIndex;
    local Actor Spawned;
    local array<int> SpawnedCounts;             //for testing, number of spawned enemies/hostages/inanimates
    local int i, j, k;
    local CustomScenario CustomScenario;
    local bool UsingCustomScenario;
    local Objective ObjectiveFromRoster;        //this will hold the objective (if any) has targets spawned from the current Roster
    local SwatRepo Repo;
    local EEntryType StartPoint;
    local int HighPriority;
    local eDifficultyLevel DifficultyLevel;
    local bool ThisRosterNotAllowed;

    // DoSpawning() should only be called in standalone games.
    assert( Level.NetMode == NM_Standalone || Level.IsCOOPServer );

    //we only expect to do this once per run
    assert(!HasSpawned || bTesting);

    //reference any custom scenario
    CustomScenario = SwatGameInfo(Level.Game).GetCustomScenario();
    UsingCustomScenario = (CustomScenario != None);

    //we may want to know where the player is starting
    Repo = SwatRepo(Level.GetRepo());
    assert(Repo != None);
    StartPoint = Repo.GetDesiredEntryPoint();

    // Determine the difficulty level
    if(Level.IsCOOPServer) {
      DifficultyLevel = Difficulty_Elite; // Gloves are off in co-op mode..!
    } else {
      DifficultyLevel = Repo.GuiConfig.CurrentDifficulty;
    }

    log("Difficulty level is "$DifficultyLevel$", spawning appropriate rosters...");

    //empty unallocated spawners list (we may be testing)
    UnallocatedSpawners.Remove(0, UnallocatedSpawners.length);

    //build list of spawners
    foreach Game.AllActors(class'Spawner', Spawner)
    {
        //try to disqualify the spawner for this level

        //spawners can only spawn once.
        if (Spawner.HasSpawned)
            continue;

        //disabled spawners shouldn't spawn
        if (Spawner.Disabled)
            continue;

        //slave-only spawners will only spawn if their master spawns
        //(in Custom Scnearios, slave spawners are regular spawners)
        if  (
                !UsingCustomScenario
            &&  Spawner.SpawnMode == SpawnMode_SlaveOnly
            )
            continue;

        //obey the spawner's "MissionSpawn" wishes
        if (Spawner.MissionSpawn > MissionSpawn_Any)
        {
            if  (
                    Spawner.MissionSpawn == MissionSpawn_CampaignOnly
                &&  UsingCustomScenario
                &&  !CustomScenario.UseCampaignObjectives
                )
                continue;

            if  (
                    !UsingCustomScenario
                &&  Spawner.MissionSpawn == MissionSpawn_CustomOnly
                )
                continue;
        }

        //spawners may be disabled based on the selected player start point
        if (Spawner.StartPointDependent > StartPoint_Any)
        {
			// dbeswick: don't use these spawns during coop games, frequently both spawns are in use
			if ( Level.IsCOOPServer )
				continue;

            if  (
                    Spawner.StartPointDependent == EStartPointDependent.StartPoint_OnlyPrimary
                &&  StartPoint != EEntryType.ET_Primary
                )
                continue;

            if  (
                    Spawner.StartPointDependent == EStartPointDependent.StartPoint_OnlySecondary
                &&  StartPoint != EEntryType.ET_Secondary
                )
                continue;
        }

        //okay, its qualified
        UnallocatedSpawners[UnallocatedSpawners.length] = Spawner;
    }

    //give any custom scenario a chance to mutate the roster list
    if (UsingCustomScenario)
        CustomScenario.MutateLevelRosters(self, Rosters);

    //select spawners to spawn level rosters
    for (i=0; i<Rosters.length; ++i)
    {
        CurrentRoster = Rosters[i];

            log("[SPAWNING] SpawningManager is selecting "$CurrentRoster.Count.Min
                    $" to "$CurrentRoster.Count.Max
                    $" Spawner(s) to spawn CurrentRoster index "$i
                    $" named "$CurrentRoster.name
                    $" from SpawnerGroup="$CurrentRoster.SpawnerGroup);

        ObjectiveFromRoster = GetMissionObjectiveForSpawnerGroup(CurrentRoster.SpawnerGroup);
        assertWithDescription(CurrentRoster.Count.Min > 0 || ObjectiveFromRoster == None,
                "[tcohen] While the SpawningManger was preparing to spawn from the level Roster index "$i
                $", it determined that the Roster's SpawnerGroup is the SpawnerGroup for the Mission Objective "$ObjectiveFromRoster
                $", but the Roster's Count Min is zero.  If zero were to be selected, then the player wouldn't need to do anything to complete the Objective!");

        // Disallow this roster if our difficulty is in the DisallowedDifficulties
        for(j = 0; j < CurrentRoster.DisallowedDifficulties.Length; j++) {
          if(CurrentRoster.DisallowedDifficulties[j] == DifficultyLevel) {
            ThisRosterNotAllowed = true;
            break;
          }
        }
        if(ThisRosterNotAllowed) {
          ThisRosterNotAllowed = false;
          continue;
        }

        if (Game.DebugSpawning)
        {
            if (ObjectiveFromRoster == None)
                log("[SPAWNING] ... this Roster does not represent the Targets for any Objective");
            else
                log("[SPAWNING] ... this Roster represents the Targets for Objective "$ObjectiveFromRoster);
        }

        //empty candidate spawners
        CandidateSpawners.Remove(0, CandidateSpawners.length);

        log("[SPAWNING] ... candidate Spawners for SpawnerGroup="$CurrentRoster.SpawnerGroup$" are:");

        //build a list of spawners - from the list of unallocated spawners - that can spawn this roster
        for (j=0; j<UnallocatedSpawners.length; ++j)
        {
            Spawner = UnallocatedSpawners[j];

            //try to disqualify the spawner for this roster

            if (CurrentRoster.ArchetypeClass != Spawner.ArchetypeClass)     //wrong archetype class
                continue;

            if (UsingCustomScenario)
            {
                if  (
                        CurrentRoster.SpawnerGroup != 'CustomRosterSpawnerGroup'    //the roster should be spawned from a SpawnerGroup
                    &&  CurrentRoster.SpawnerGroup != Spawner.GetSpawnerGroup()     //wrong SpawnerGroup
                    )
                    continue;
            }
            else                                                            //!UsingCustomScenario
            {
                if (CurrentRoster.SpawnerGroup != Spawner.GetSpawnerGroup())        //wrong spawner group
                    continue;
            }

            if (Game.DebugSpawning)
                log("[SPAWNING] ... - "$Spawner$": SpawnerGroup="$Spawner.GetSpawnerGroup()$", Tag="$Spawner.Tag);
            CandidateSpawners[CandidateSpawners.length] = Spawner;
        }

        //we can't spawn more than the number of candidate spawners
        AssertWithDescription(CandidateSpawners.length >= CurrentRoster.Count.Max,
                "[tcohen] (SwatLevelInfo was selecting spawners to spawn level rosters) "
                $"There aren't enough qualified spawners to spawn the max from roster #"$i
                $" with SpawnerGroup="$CurrentRoster.SpawnerGroup
                $": Roster max count is "$CurrentRoster.Count.Max
                $", and there is/are only "$CandidateSpawners.length
                $" candidate spawners available.");

        //min should be <= max
        AssertWithDescription(CurrentRoster.Count.Min <= CurrentRoster.Count.Max,
                "[tcohen] SpawningManager::DoSpawning() Roster #"$i
                $" has Min="$CurrentRoster.Count.Min
                $" and Max="$CurrentRoster.Count.Max
                $".  Please make Max greater than or equal to Min.");

        //how many will we spawn from this roster?
        Count = Rand(CurrentRoster.Count.Max - CurrentRoster.Count.Min + 1) + CurrentRoster.Count.Min;

        if (Game.DebugSpawning)
            log("[SPAWNING] ... decided to spawn "$Count
                    $" from "$CurrentRoster.name$":");

        //select spawners - from the candidate spawners - to spawn this roster
        for (j=0; j<Count; ++j)
        {
            if(CandidateSpawners.length <= 0) {
              assertWithDescription(false, "Ran out of candidate spawners for Roster "$CurrentRoster.SpawnerGroup);
              break;
            }

            //find out if any of the candidate spawners have priority
            HighPriority = 0;
            for (k=0; k<CandidateSpawners.length; ++k)
            {
                if (CandidateSpawners[k].Priority > HighPriority)
                {
                    SelectedIndex = k;
                    HighPriority = CandidateSpawners[k].Priority;
                }
            }
            if (HighPriority == 0)   //we didn't find any Spawner with priority
                SelectedIndex = Rand(CandidateSpawners.length);
            //else  //we found a Spawner with priority, and set SelectedIndex to that

            Spawner = CandidateSpawners[SelectedIndex];

            Archetype = CurrentRoster.PickArchetype();

            if (Game.DebugSpawning)
                log("[SPAWNING] ... "$j+1
                        $") selected "$Spawner
                        $" (Tag="$Spawner.Tag
                        $", Priority="$Spawner.Priority
                        $"), and chose to spawn from Archetype "$Archetype$".");

            //tell the spawner to spawn (it will call SpawnerAlocated() to remove itself from the unallocated spawners list)
            Spawned = Spawner.SpawnArchetype(
                    Archetype,
                    bTesting,
                    CustomScenario);

            //for testing, record counts of each type of spawned Actor
            if (Spawned != None)
                SpawnedCounts[Spawner.ProfileArrayIndex] = SpawnedCounts[Spawner.ProfileArrayIndex] + 1;    //note can't use ++ operator because it can't grow the dyn. array

            //the Label of the Spawned is the SpawnerGroup of the Roster
            Spawned.Label = CurrentRoster.SpawnerGroup;

            //its no longer a candidate since it has been allocated
            CandidateSpawners.Remove(SelectedIndex, 1);
        }
    }

    CurrentRoster = None;

    if (Game.DebugSpawning)
        log("[SPAWNING] SpawningManager is done spawning Rosters.");

    if (!UsingCustomScenario)
    {
        if (Game.DebugSpawning)
            log("[SPAWNING] Now telling remaining unallocated Spawners to spawn from local properties.");

        //for any remaining unallocated spawners, let them spawn from their local properties
        while (UnallocatedSpawners.length > 0)
        {
            Spawner = UnallocatedSpawners[0];

            if (!Spawner.Disabled)
            {
                Spawned = Spawner.SpawnFromLocalProperties(bTesting);

                //for testing, record counts of each type of spawned Actor
                if (Spawned != None)
                    SpawnedCounts[Spawner.ProfileArrayIndex] = SpawnedCounts[Spawner.ProfileArrayIndex] + 1;    //note can't use ++ operator because it can't grow the dyn. array
            }
        }
    }

    if (Game.DebugSpawning)
    {
        log("[SPAWNING] Summary:");
        if (SpawnedCounts.length > 0)
            log("[SPAWNING]     "$SpawnedCounts[0]$" Enemies");
        if (SpawnedCounts.length > 1)
            log("[SPAWNING]     "$SpawnedCounts[1]$" Hostages");
        if (SpawnedCounts.length > 2)
            log("[SPAWNING]     "$SpawnedCounts[2]$" Inanimates");
    }

    HasSpawned = true;

    return SpawnedCounts;
}

function bool IsSpawningFromRosters()
{
    return (CurrentRoster != None && CurrentRoster.SpawnerGroup != 'CustomRosterSpawnerGroup');
}

//returns results as an array of ints, each index is the total of EArchetypeCategory spawned
//  (ie. enemies, hostages, etc.)
// dbeswick: now you can specify a semicolon separated list of rosters
function DoMPSpawning(SwatGameInfo Game, coerce string MPRosterClassNames,optional bool bTesting)
{
    local Spawner Spawner;
    local name Archetype;
    local array<Spawner> CandidateSpawners;
    local int Count;
    local int SelectedIndex;
    local Actor Spawned;
    //local array<int> SpawnedCounts;     //for testing, number of spawned enemies/hostages/inanimates
    local int i, j, k;
    local Objective ObjectiveFromRoster;    //this will hold the objective (if any) has targets spawned from the current Roster
	local array<string> MPRosterSplitNames;
	local bool FoundRoster;

    // DoSpawning() should only be called in network games
    //assert( Level.NetMode != NM_Standalone );

    //we only expect to do this once per run
    assert(!HasSpawned || bTesting);

	// split rosters string by semicolons
	Split(MPRosterClassNames, ";", MPRosterSplitNames);

    mplog( self$"---SpawningManager::DoMPSpawning(). MPRosterClassName="$MPRosterClassNames );

    //empty unallocated spawners list (we may be testing)
    UnallocatedSpawners.Remove(0, UnallocatedSpawners.length);

    //build list of spawners
    foreach Game.AllActors(class'Spawner', Spawner)
        UnallocatedSpawners[UnallocatedSpawners.length] = Spawner;

    //select spawners to spawn level rosters
    for (i=0; i<MPRosters.length; ++i)
    {
		FoundRoster = false;
        CurrentRoster = MPRosters[i];
		for (k=0; k < MPRosterSplitNames.length; ++k)
		{
			if ( CurrentRoster.IsA( name(MPRosterSplitNames[k]) ) )
			{
	            FoundRoster = true;
				break;
			}
		}

		if (!FoundRoster)
			continue;

        if (Game.DebugSpawning)
            log("[SPAWNING] SpawningManager is selecting "$CurrentRoster.Count.Min
                    $" to "$CurrentRoster.Count.Max
                    $" Spawner(s) to spawn Roster index "$i
                    $" from SpawnerGroup="$CurrentRoster.SpawnerGroup);

        ObjectiveFromRoster = GetMissionObjectiveForSpawnerGroup(CurrentRoster.SpawnerGroup);
        assertWithDescription(CurrentRoster.Count.Min > 0 || ObjectiveFromRoster == None,
                "[tcohen] While the SpawningManger was preparing to spawn from the level Roster index "$i
                $", it determined that the Roster's SpawnerGroup is the SpawnerGroup for the Mission Objective "$ObjectiveFromRoster
                $", but the Roster's Count Min is zero.  If zero were to be selected, then the player wouldn't need to do anything to complete the Objective!");

        //empty candidate spawners
        CandidateSpawners.Remove(0, CandidateSpawners.length);

        if (Game.DebugSpawning)
            log("[SPAWNING] ... candidate Spawners for SpawnerGroup="$CurrentRoster.SpawnerGroup$" are:");

        //build a list of spawners - from the list of unallocated spawners - that can spawn this roster
        for (j=0; j<UnallocatedSpawners.length; ++j)
        {
            Spawner = UnallocatedSpawners[j];

            //try to disqualify the spawner

            if (CurrentRoster.ArchetypeClass != Spawner.ArchetypeClass)     //different archetype class
                continue;

            if (CurrentRoster.SpawnerGroup != Spawner.GetSpawnerGroup())     //different spawner group
                continue;

            if (Game.DebugSpawning)
                log("[SPAWNING] ... - "$Spawner$" (Tag="$Spawner.Tag$")");
            CandidateSpawners[CandidateSpawners.length] = Spawner;
        }

        //we can't spawn more than the number of candidate spawners
        AssertWithDescription(CandidateSpawners.length >= CurrentRoster.Count.Max,
                "[tcohen] (SwatLevelInfo was selecting spawners to spawn level rosters) "
                $"There aren't enough qualified spawners to spawn the max from roster #"$i
                $": Roster max count is "$CurrentRoster.Count.Max
                $", and there is/are only "$CandidateSpawners.length
                $" candidate spawners available.");

        //min should be <= max
        AssertWithDescription(CurrentRoster.Count.Min <= CurrentRoster.Count.Max,
                "[tcohen] In SwatLevelInfo, Roster #"$i
                $" has Min="$CurrentRoster.Count.Min
                $" and Max="$CurrentRoster.Count.Max
                $".  Please make Max greater than or equal to Min.");

        //how many will we spawn from this roster?
        Count = Rand(CurrentRoster.Count.Max - CurrentRoster.Count.Min + 1) + CurrentRoster.Count.Min;

        if (Game.DebugSpawning)
            log("[SPAWNING] ... decided to spawn "$Count
                    $" from "$CurrentRoster.name$":");

        //select spawners - from the candidate spawners - to spawn this roster
        for (j=0; j<Count; ++j)
        {
            assert(CandidateSpawners.length > 0);   //we should still have a candidate spawner left to spawn the archetype

            SelectedIndex = Rand(CandidateSpawners.length);

            Spawner = CandidateSpawners[SelectedIndex];

            Archetype = CurrentRoster.PickArchetype();

            if (Game.DebugSpawning)
                log("[SPAWNING] ... "$j+1
                        $") selected "$Spawner
                        $" (Tag="$Spawner.Tag
                        $"), and chose to spawn from Archetype "$Archetype$".");

            //tell the spawner to spawn (it will call SpawnerAlocated() to remove itself from the unallocated spawners list)
            Spawned = Spawner.SpawnArchetype(Archetype, bTesting);

            //for testing, record counts of each type of spawned Actor
            //if (Spawned != None)
            //    SpawnedCounts[Spawner.ProfileArrayIndex] = SpawnedCounts[Spawner.ProfileArrayIndex] + 1;    //note can't use ++ operator because it can't grow the dyn. array

            //its no longer a candidate since it has been allocated
            CandidateSpawners.Remove(SelectedIndex, 1);
        }
    }

    CurrentRoster = None;

    if (Game.DebugSpawning)
    {
        log("[SPAWNING] SwatLevelInfo is done spawning Rosters.");

        log("[SPAWNING] Now telling remaining unallocated Spawners to spawn from local properties.");
    }

    //for any remaining unallocated spawners, let them spawn from their local properties
    while (UnallocatedSpawners.length > 0)
    {
        Spawner = UnallocatedSpawners[0];

        Spawned = Spawner.SpawnFromLocalProperties(bTesting);

        //for testing, record counts of each type of spawned Actor
        //if (Spawned != None)
        //    SpawnedCounts[Spawner.ProfileArrayIndex] = SpawnedCounts[Spawner.ProfileArrayIndex] + 1;    //note can't use ++ operator because it can't grow the dyn. array
    }

    //log("[SPAWNING] Summary:");
    //if (SpawnedCounts.length > 0)
    //    log("[SPAWNING]     "$SpawnedCounts[0]$" MP objects");

    HasSpawned = true;

    //return SpawnedCounts;
}

//really just remove the spawner from the list of unallocated spawners
function SpawnerAllocated(Actor Spawner)
{
    local int i;
    local bool found;
    local Spawner ConcreteSpawner;

    ConcreteSpawner = Spawner(Spawner);
    assert(ConcreteSpawner != None);

    for (i=0; i<UnallocatedSpawners.length; ++i)
    {
        if (UnallocatedSpawners[i] == ConcreteSpawner)
        {
            UnallocatedSpawners.Remove(i, 1);
            found = true;
        }
    }

    if (ConcreteSpawner.SpawnMode != SpawnMode_Slave && ConcreteSpawner.SpawnMode != SpawnMode_SlaveOnly)
        assert(found);      //we shouldn't try to allocate a spawner that isn't in the unallocated spawners list
    //if the spawner is a slave, then it may spawn during level roster spawning even if its not qualified to spawn from a roster
}

//returns the objective whose targets are spawned among the spawners in the specified SpawnerGroup
function Objective GetMissionObjectiveForSpawnerGroup(name SpawnerGroup)
{
    local int i;
    local MissionObjectives MissionObjectives;

    MissionObjectives = SwatRepo(Level.GetRepo()).MissionObjectives;

    if( MissionObjectives == None )
        return None;

	for (i=0; i<MissionObjectives.Objectives.length; ++i)
		if (MissionObjectives.Objectives[i].HasSpawnerGroup(SpawnerGroup))
			return MissionObjectives.Objectives[i];

    return None;
}

//returns true iff there is some mission objective whose targets are spawned among the spawners in the specified SpawnerGroup
function bool IsMissionObjective(name SpawnerGroup)
{
    return (GetMissionObjectiveForSpawnerGroup(SpawnerGroup) != None);
}

function TestSpawn(SwatGameInfo Game, int Count)
{
    //for count > 0
    local int i, j;
    local array<int> CurrentResults;
    local array<int> TotalResults[NUM_ARCHETYPE_CATEGORIES];
    local array<float> AverageResults[NUM_ARCHETYPE_CATEGORIES];
    local array<int> MaxResults[NUM_ARCHETYPE_CATEGORIES];
    local array<int> MinResults[NUM_ARCHETYPE_CATEGORIES];
    local array<int> MaxCount[NUM_ARCHETYPE_CATEGORIES];
    local array<int> MinCount[NUM_ARCHETYPE_CATEGORIES];
    //for count == 0
    local Spawner Spawner;

    if (Count > 0)
    {
        //simulate, Count times, the spawning that happens when the game starts, and log the results

        log("[SPAWNING] ** Testing "$Count$" times");

        //initialize minimums
        for (j=0; j<3; ++j)
            MinResults[j] = -1;

        for (i=0; i<Count; ++i)
        {
            log("[SPAWNING] ** Test #"$i+1);
            CurrentResults = DoSpawning(Game, True);   //testing

            for (j=0; j<NUM_ARCHETYPE_CATEGORIES; ++j)
            {
                if (CurrentResults.length <= j)
                    CurrentResults[j] = 0;

                TotalResults[j] += CurrentResults[j];

                if (CurrentResults[j] > MaxResults[j])
                {
                    MaxResults[j] = CurrentResults[j];

                    //new max... so restart count
                    MaxCount[j] = 0;
                }
                if (CurrentResults[j] == MaxResults[j])
                    MaxCount[j]++;

                if (CurrentResults[j] < MinResults[j] || MinResults[j] < 0)
                {
                    MinResults[j] = CurrentResults[j];

                    //new min... so restart count
                    MinCount[j] = 0;
                }
                if (CurrentResults[j] == MinResults[j])
                    MinCount[j]++;
            }
        }

        for (j=0; j<NUM_ARCHETYPE_CATEGORIES; ++j)
            AverageResults[j] = float(TotalResults[j]) / float(Count);

        log("[SPAWNING] Cumulative Summary ("$Count$" runs):");
        log("[SPAWNING]     Enemies:    Min="$MinResults[0]$" ("$MinCount[0]$" times), Max="$MaxResults[0]$" ("$MaxCount[0]$" times), Average="$AverageResults[0]);
        log("[SPAWNING]     Hostages:   Min="$MinResults[1]$" ("$MinCount[1]$" times), Max="$MaxResults[1]$" ("$MaxCount[1]$" times), Average="$AverageResults[1]);
        log("[SPAWNING]     Inanimates: Min="$MinResults[2]$" ("$MinCount[2]$" times), Max="$MaxResults[2]$" ("$MaxCount[2]$" times), Average="$AverageResults[2]);
    }
    else
    {
        log("[SPAWNING] ** Spawning 'TestSpawn' Archetype from each Enemy and Hostage Spawner.  Note that Spawning may fail if, for example, something is encroachig on the Spawner (like someone else who already spawned there).");

        foreach Game.AllActors(class'Spawner', Spawner)
            if (Spawner.IsA('EnemySpawner') || Spawner.IsA('HostageSpawner'))
                Spawner.SpawnArchetype('TestSpawn', false); //not testing (ie. really spawn)
    }
}

////////////////////////////////////////////////////////////////////
// Reset the class variables to their initial state
////////////////////////////////////////////////////////////////////
function ResetForMPQuickRestart( LevelInfo inLevel )
{
    local Spawner Spawner;

    Level = inLevel;

    HasSpawned = false;
    UnallocatedSpawners.Remove(0,UnallocatedSpawners.Length);
    CurrentRoster = None;

    foreach Level.AllActors(class'Spawner', Spawner)
    {
        Spawner.ResetForMPQuickRestart();
    }
}
////////////////////////////////////////////////////////////////////
