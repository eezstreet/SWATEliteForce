class Procedure_NoOfficerIncapacitated extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnIncapacitated,
                IInterested_GameEvent_PawnDied;

var config int PenaltyPerOfficer;

var array<SwatOfficer> IncapacitatedOfficers;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnIncapacitated.Register(self);
    GetGame().GameEvents.PawnDied.Register(self);
}

//interface IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (!Pawn.IsA('SwatPlayer')) return;

    OnOfficerIncapacitated( Pawn, Killer );
}

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if (!Pawn.IsA('SwatOfficer')) return;

    OnOfficerIncapacitated( Pawn, Incapacitator );
}

function OnOfficerIncapacitated(Pawn Pawn, Actor Incapacitator)
{
    if( !Incapacitator.IsA('SwatPlayer') )
    {
        if (GetGame().DebugLeadership)
            log("[LEADERSHIP] "$class.name
                $"::OnOfficerIncapacitated() did *not* add "$Pawn.name
                $" to its list of IncapacitatedOfficers because Incapacitator was not the local player.");

        return; //we only penalize the player if they did the Incapacitating
    }

    AssertNotInArray( Pawn, IncapacitatedOfficers, 'IncapacitatedOfficers' );
    Add( Pawn, IncapacitatedOfficers );

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of IncapacitatedOfficers because PawnIncapacitated, Incapacitator="$Incapacitator
            $". IncapacitatedOfficers.length="$IncapacitatedOfficers.length);
}

function string Status()
{
    return string(IncapacitatedOfficers.length);
}

function int GetCurrentValue()
{
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerOfficer * IncapacitatedOfficers.length\n"
            $"                           = "$PenaltyPerOfficer$" * "$IncapacitatedOfficers.length$"\n"
            $"                           = "$PenaltyPerOfficer * IncapacitatedOfficers.length);

    return PenaltyPerOfficer * IncapacitatedOfficers.length;
}

