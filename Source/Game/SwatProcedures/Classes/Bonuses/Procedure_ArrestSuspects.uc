class Procedure_ArrestSuspects extends Procedure_NeutralizeSuspects
    implements  IInterested_GameEvent_PawnDied,
                IInterested_GameEvent_PawnIncapacitated
    abstract;

var array<SwatEnemy> IncapacitatedEnemies;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDied.Register(self);
    GetGame().GameEvents.PawnIncapacitated.Register(self);
}

//interface IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    Remove(Pawn, IncapacitatedEnemies);
    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" removed "$Pawn.name
            $" from its list of IncapacitatedEnemies because PawnDied."
            $" IncapacitatedEnemies.length="$IncapacitatedEnemies.length);

    Remove(Pawn, NeutralizedEnemies);
    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" removed "$Pawn.name
            $" from its list of NeutralizedEnemies because PawnDied."
            $" NeutralizedEnemies.length="$NeutralizedEnemies.length);
}

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return;

    Add(Pawn, IncapacitatedEnemies);
    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of IncapacitatedEnemies because PawnIncapacitated."
            $" IncapacitatedEnemies.length="$IncapacitatedEnemies.length);
}

