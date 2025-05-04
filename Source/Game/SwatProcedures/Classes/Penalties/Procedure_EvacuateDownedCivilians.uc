class Procedure_EvacuateDownedCivilians extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnIncapacitated,
                IInterested_GameEvent_PawnDied,
                IInterested_GameEvent_ReportableReportedToTOC;

var config int PenaltyPerDownedHostage;

var array<SwatPawn> UnevacuatedDownedHostages;
var array<SwatPawn> ReportedDownedHostages;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnIncapacitated.Register(self);
    GetGame().GameEvents.PawnDied.Register(self);
    GetGame().GameEvents.ReportableReportedToTOC.Register(self);
}

function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if( !Pawn.IsA('SwatHostage') )
        return;   //we only care about officers

	if(IsInArray(Pawn, ReportedDownedHostages))
		return;

    AssertNotInArray( Pawn, UnevacuatedDownedHostages, 'UnevacuatedDownedHostages' );
    Add( Pawn, UnevacuatedDownedHostages );
}

function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if(!Pawn.IsA('SwatHostage'))
        return;

    if(IsInArray(Pawn, UnevacuatedDownedHostages))
        return;

    if(IsInArray(Pawn, ReportedDownedHostages))
        return;

    Add( Pawn, UnevacuatedDownedHostages );
}

function OnReportableReportedToTOC(IAmReportableCharacter ReportedCharacter, Pawn Reporter)
{
    if (!ReportedCharacter.IsA('SwatHostage') )
        return;   //we only care about hostages

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" removed "$ReportedCharacter.name
            $" from the list of UnevacuatedDownedHostages because ReportableReportedToTOC"
            $". UnevacuatedDownedHostages.length="$UnevacuatedDownedHostages.length);

	if(IsInArray(Pawn(ReportedCharacter), UnevacuatedDownedHostages))
	{
		Remove( SwatPawn(ReportedCharacter), UnevacuatedDownedHostages );
	}

    Add(SwatPawn(ReportedCharacter), ReportedDownedHostages);
}

function string Status()
{
    local int ReportableDownedHostages;

    ReportableDownedHostages = UnevacuatedDownedHostages.length;

    return String(ReportableDownedHostages);
}

function int GetCurrentValue()
{
    local int ReportableDownedHostages;

    ReportableDownedHostages = UnevacuatedDownedHostages.length;

    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerDownedHostage * ReportableDownedHostages\n"
            $"                           = "$PenaltyPerDownedHostage$" * "$ReportableDownedHostages$"\n"
            $"                           = "$PenaltyPerDownedHostage * ReportableDownedHostages);

    return PenaltyPerDownedHostage * ReportableDownedHostages;
}

function int GetPossible()
{
	return 0;
}