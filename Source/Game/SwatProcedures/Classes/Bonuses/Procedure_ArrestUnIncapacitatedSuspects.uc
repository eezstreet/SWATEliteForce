class Procedure_ArrestUnIncapacitatedSuspects extends Procedure_ArrestSuspects
    implements  IInterested_GameEvent_PawnArrested,
                IInterested_GameEvent_PawnIncapacitated;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnArrested.Register(self);
}

//interface IInterested_GameEvent_PawnArrested implementation
function OnPawnArrested( Pawn Pawn, Pawn Arrester )
{
    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    //stick it in the correct arrests array
    if (!IsInArray(Pawn, IncapacitatedEnemies))
    {
        Add(Pawn, NeutralizedEnemies);
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $" added "$Pawn.name
                $" to its list of NeutralizedEnemies because PawnArrested (and was not previously Incapacitated)."
                $" NeutralizedEnemies.length="$NeutralizedEnemies.length);
    }
}

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    Super.OnPawnIncapacitated( Pawn, Incapacitator, WasAThreat );

    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    Remove(Pawn, NeutralizedEnemies);
    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" removed "$Pawn.name
            $" from its list of NeutralizedEnemies because PawnDied."
            $" NeutralizedEnemies.length="$NeutralizedEnemies.length);
}

function int AdditionalBonus()
{
    if( TotalEnemies == 0 )
        return TotalBonus;
        
    return Super.AdditionalBonus();
}
