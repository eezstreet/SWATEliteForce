class Procedure_ArrestIncapacitatedSuspects extends Procedure_ArrestSuspects
    implements  IInterested_GameEvent_PawnIncapacitated;

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    Super.OnPawnIncapacitated( Pawn, Incapacitator, WasAThreat );

    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    Add(Pawn, NeutralizedEnemies);

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of NeutralizedEnemies because PawnIncapacitated."
            $" NeutralizedEnemies.length="$IncapacitatedEnemies.length);
}
