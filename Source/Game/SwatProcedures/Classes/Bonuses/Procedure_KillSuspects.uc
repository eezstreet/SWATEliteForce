class Procedure_KillSuspects extends Procedure_NeutralizeSuspects
    implements  IInterested_GameEvent_PawnDied,
                IInterested_GameEvent_PawnArrested,
                IInterested_GameEvent_PawnIncapacitated;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDied.Register(self);
    GetGame().GameEvents.PawnArrested.Register(self);
    GetGame().GameEvents.PawnIncapacitated.Register(self);
}

//interface IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    Add(Pawn, NeutralizedEnemies);
    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of NeutralizedEnemies because PawnDied."
            $" NeutralizedEnemies.length="$NeutralizedEnemies.length);
}

//interface IInterested_GameEvent_PawnArrested implementation
function OnPawnArrested( Pawn Pawn, Pawn Arrester )
{
    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    //if it was just arrested, then it shouldn't have been already killed
    AssertNotInArray(Pawn, NeutralizedEnemies, 'KilledEnemies');
}

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return;

    //if it was just incapacitated, then it shouldn't have been already killed
    AssertNotInArray(Pawn, NeutralizedEnemies, 'KilledEnemies');
}

