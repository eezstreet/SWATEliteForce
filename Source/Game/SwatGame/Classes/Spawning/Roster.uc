class Roster extends Core.Object
    editinlinenew
    hideCategories(Object)
    collapsecategories
    abstract;

var class<Archetype> ArchetypeClass;

var (Roster) IntegerRange Count;
var (Roster) editinline array<Archetype.ChanceArchetypePair> Archetypes;    //named for clarity in the Editor 
var (Roster) name SpawnerGroup;

function name PickArchetype()
{
    return class'Archetype'.static.PickArchetype(Archetypes);
}
