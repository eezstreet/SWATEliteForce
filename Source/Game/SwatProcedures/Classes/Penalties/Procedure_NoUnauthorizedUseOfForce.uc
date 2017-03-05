class Procedure_NoUnauthorizedUseOfForce extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDied,
                IInterested_GameEvent_PawnIncapacitated;

var config int PenaltyPerEnemy;

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
    //note that if it was previously incapacitated, then it can't be a threat

    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    if (GetGame().DebugLeadership && IsInArray( Pawn, IncapacitatedEnemies ) )
        log("[LEADERSHIP] "$class.name
            $" removed "$Pawn.name
            $" from its list of IncapacitatedEnemies because PawnDied.");

    Remove( Pawn, IncapacitatedEnemies );
}

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return;

    if (WasAThreat)
    {
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $"::OnPawnIncapacitated() did *not* add "$Pawn.name
                $" to its list of IncapacitatedEnemies because the SwatEnemy was a threat (so the force was authorized).");

        return; //the force was authorized
    }

    if( !Incapacitator.IsA('SwatPlayer') && Pawn(Incapacitator).GetActiveItem().GetSlot() != Slot_Detonator && !Incapacitator.IsA('SniperPawn'))
    {
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $"::OnPawnDied() did *not* add "$Pawn.name
                $" to its list of KilledEnemies because Incapacitator was not the local player.");

        return; //we only penalize the player if they did the Incapacitating
    }

    AssertNotInArray( Pawn, IncapacitatedEnemies, 'IncapacitatedEnemies' );
    Add( Pawn, IncapacitatedEnemies );
    ChatMessageEvent('PenaltyIssued');
    GetGame().CampaignStats_TrackPenaltyIssued();

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of IncapacitatedEnemies because PawnIncapacitated, Incapacitator="$Incapacitator
            $". IncapacitatedEnemies.length="$IncapacitatedEnemies.length);
}

function string Status()
{
    return string(IncapacitatedEnemies.length);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerEnemy * IncapacitatedEnemies.length\n"
            $"                           = "$PenaltyPerEnemy$" * "$IncapacitatedEnemies.length$"\n"
            $"                           = "$PenaltyPerEnemy * IncapacitatedEnemies.length);

    return PenaltyPerEnemy * IncapacitatedEnemies.length;
}
