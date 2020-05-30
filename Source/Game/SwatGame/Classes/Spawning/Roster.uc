class Roster extends Core.Object
    editinlinenew
    hideCategories(Object)
    collapsecategories
    dependsOn(SwatGUIConfig)
    abstract;

var class<Archetype> ArchetypeClass;

import enum eDifficultyLevel from SwatGUIConfig;

var (Roster) IntegerRange Count;
var (Roster) editinline array<Archetype.ChanceArchetypePair> Archetypes;    //named for clarity in the Editor
var (Roster) name SpawnerGroup;
var (Roster) editinline array<eDifficultyLevel> DisallowedDifficulties "A list of difficulties which won't spawn this roster";
var (Roster) bool SpawnAnywhere "If true, this spawner will spawn from any spawner, regardless of SpawnerGroup";

struct CustomScenarioDataForArchetype
{
	var bool bOverrideMorale;
	var bool bOverridePrimaryWeapon;
	var bool bOverrideBackupWeapon;
	var bool bOverrideHelmet;
	var float OverrideMinMorale;
	var float OverrideMaxMorale;
	var string OverridePrimaryWeapon;
	var string OverrideBackupWeapon;
	var string OverrideHelmet;
};

var array<CustomScenarioDataForArchetype> CustomData;

function int MutateSpawnCount(int SpawnCount, SwatGUIConfig GC)
{
	// Meant to be overridden in child classes
	return SpawnCount;
}

function Actor PickAndSpawnArchetype(Spawner Spawner, CustomScenario CustomScenario, bool bTesting, optional int RosterNumber)
{
	local name Archetype;
	local Actor Spawned;

	Archetype = class'Archetype'.static.PickArchetype(Archetypes);
	Spawned = Spawner.SpawnArchetype(Archetype, bTesting, CustomScenario);

	return Spawned;
}
