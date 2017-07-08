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

function name PickArchetype()
{
    return class'Archetype'.static.PickArchetype(Archetypes);
}
