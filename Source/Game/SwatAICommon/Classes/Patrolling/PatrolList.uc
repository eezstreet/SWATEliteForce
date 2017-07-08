///////////////////////////////////////////////////////////////////////////////
// PatrolList.uc - PatrolList class
// This list constitutes a patrol, and each EnemySpawner will be given a Patrol List
// so that designers can edit patrols

class PatrolList extends Core.Object
    native
    editinlinenew;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
//  Patrol List variables
struct native PatrolEntry
{
    var() name          PatrolPointName;
    var() range         IdleTime;
    var() int           IdleChance;
	var() name			IdleCategory;
    var   PatrolPoint   PatrolPoint;
};

var() editinline array<PatrolEntry> PatrolEntries;

// debugging variables
var array<vector>		PatrolPathLocations;

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function PatrolEntry GetPatrolEntry(int PatrolEntryIndex)
{
    assert(PatrolEntryIndex >= 0);
    assert(PatrolEntryIndex < PatrolEntries.Length);

    return PatrolEntries[PatrolEntryIndex];
}

function int GetNumPatrolEntries()
{
    return PatrolEntries.Length;
}