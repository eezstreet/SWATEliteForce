interface ISpawningManager;

function array<int> DoSpawning(Actor Game, optional bool bTesting);
function DoMPSpawning(Actor Game, coerce string MPRosterClassNames,optional bool bTesting);
function bool IsSpawningFromRosters();
function SpawnerAllocated(Actor Spawner);
function bool IsMissionObjective(name SpawnerGroup);
function TestSpawn(Actor Game, int Count);

// This function required to reset spawning managers to their initial state for quick restart purposes
function ResetForMPQuickRestart( LevelInfo inLevel );
