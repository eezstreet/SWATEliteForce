class Procedure_NoHostageKilled extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDied;

var config int PenaltyPerHostage;

var array<SwatHostage> KilledHostages;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDied.Register(self);
}

//interface IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (!Pawn.IsA('SwatHostage')) return;

    if( !Killer.IsA('SwatPlayer') && Pawn(Killer).GetActiveItem().GetSlot() != Slot_Detonator && !Killer.IsA('SniperPawn') )
    {
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $"::OnPawnDied() did *not* add "$Pawn.name
                $" to its list of KilledHostages because Killer was not the local player.");

        return; //we only penalize the player if they did the Killing
    }

    AssertNotInArray( Pawn, KilledHostages, 'KilledHostages' );
    Add( Pawn, KilledHostages );
    TriggerPenaltyMessage(Pawn(Killer));
    GetGame().CampaignStats_TrackPenaltyIssued();

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of KilledHostages because PawnDied, Killer="$Killer
            $". KilledHostages.length="$KilledHostages.length);
}

function string Status()
{
    return string(KilledHostages.length);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerHostage * KilledHostages.length\n"
            $"                           = "$PenaltyPerHostage$" * "$KilledHostages.length$"\n"
            $"                           = "$PenaltyPerHostage * KilledHostages.length);

    return PenaltyPerHostage * KilledHostages.length;
}
