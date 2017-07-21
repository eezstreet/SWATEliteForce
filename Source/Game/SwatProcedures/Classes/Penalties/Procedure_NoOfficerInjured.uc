class Procedure_NoOfficerInjured extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDamaged;

var config int PenaltyPerOfficer;

var array<SwatOfficer> InjuredOfficers;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDamaged.Register(self);
}

function OnPawnDamaged(Pawn Pawn, Actor Damager)
{
    if( !Pawn.IsA('SwatOfficer') && !Pawn.IsA('SwatPlayer') ) return;

    // For coop, we want to allow this penalty, but only if the damager is from another player.
    // Self-damage should not affect this penalty.
    if( Pawn.IsA('SwatPlayer') && Pawn == Damager) return;

    if( !Damager.IsA('SwatPlayer') )
    {
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $"::OnPawnDamaged() did *not* add "$Pawn.name
                $" to its list of InjuredOfficers because Damager was not the local player.");

        return; //we only penalize the player if they did the Injuring
    }

    Add( Pawn, InjuredOfficers );
    ChatMessageEvent('PenaltyIssued');
    GetGame().CampaignStats_TrackPenaltyIssued();

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of InjuredOfficers because PawnDamaged, Damager="$Damager
            $". InjuredOfficers.length="$InjuredOfficers.length);
}

function string Status()
{
    return string(InjuredOfficers.length);
}

function int GetCurrentValue()
{
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerOfficer * InjuredOfficers.length\n"
            $"                           = "$PenaltyPerOfficer$" * "$InjuredOfficers.length$"\n"
            $"                           = "$PenaltyPerOfficer * InjuredOfficers.length);

    return PenaltyPerOfficer * InjuredOfficers.length;
}
