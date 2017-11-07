class Procedure_NoHostageIncapacitated extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDied,
                IInterested_GameEvent_PawnIncapacitated;

var config int PenaltyPerHostage;

var array<SwatHostage> IncapacitatedHostages;

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
    if (!Pawn.IsA('SwatHostage')) return; //we don't care

    if (GetGame().DebugLeadership &&
        IsInArray( Pawn, IncapacitatedHostages ) )
        log("[LEADERSHIP] "$class.name
            $" removed "$Pawn.name
            $" from its list of IncapacitatedHostages because PawnDied.");

    Remove( Pawn, IncapacitatedHostages );
}

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if (!Pawn.IsA('SwatHostage')) return;

    if( !Incapacitator.IsA('SwatPlayer') && Pawn(Incapacitator).GetActiveItem().GetSlot() != Slot_Detonator && !Incapacitator.IsA('SniperPawn') )
    {
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $"::OnPawnIncapacitated() did *not* add "$Pawn.name
                $" to its list of IncapacitatedHostages because Incapacitator was not the local player.");

        return; //we only penalize the player if they did the Incapacitating
    }

    AssertNotInArray( Pawn, IncapacitatedHostages, 'IncapacitatedHostages' );
    Add( Pawn, IncapacitatedHostages );
	TriggerPenaltyMessage(Pawn(Incapacitator));
    GetGame().CampaignStats_TrackPenaltyIssued();

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of IncapacitatedHostages because PawnIncapacitated, Incapacitator="$Incapacitator
            $". IncapacitatedHostages.length="$IncapacitatedHostages.length);
}

function string Status()
{
    return string(IncapacitatedHostages.length);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerHostage * IncapacitatedHostages.length\n"
            $"                           = "$PenaltyPerHostage$" * "$IncapacitatedHostages.length$"\n"
            $"                           = "$PenaltyPerHostage * IncapacitatedHostages.length);

    return PenaltyPerHostage * IncapacitatedHostages.length;
}
