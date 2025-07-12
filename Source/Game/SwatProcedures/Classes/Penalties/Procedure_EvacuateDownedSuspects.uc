class Procedure_EvacuateDownedSuspects extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnIncapacitated,
                IInterested_GameEvent_PawnDied,
                IInterested_GameEvent_PawnArrested,
                IInterested_GameEvent_ReportableReportedToTOC;

var config int PenaltyPerDownedSuspect;

var array<SwatPawn> UnevacuatedDownedSuspects;
var array<SwatPawn> ReportedDownedSuspects;
var array<SwatPawn> ArrestedSuspects;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnIncapacitated.Register(self);
    GetGame().GameEvents.PawnDied.Register(self);
    GetGame().GameEvents.PawnArrested.Register(self);
    GetGame().GameEvents.ReportableReportedToTOC.Register(self);
}

//IInterested_GameEvent_PawnArrested Implementation
function OnPawnArrested( Pawn Pawn, Pawn Arrester )
{
    if (!Pawn.IsA('SwatEnemy')) return;   //we don't care

    Add( Pawn, ArrestedSuspects );
}

function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if( !Pawn.IsA('SwatEnemy') )
        return;   //we only care about Suspects

	if(IsInArray(Pawn, ReportedDownedSuspects) || IsInArray(Pawn, ArrestedSuspects))
	{
		return;
	}

    AssertNotInArray( Pawn, UnevacuatedDownedSuspects, 'UnevacuatedDownedSuspects' );
    Add( Pawn, UnevacuatedDownedSuspects );
}

function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if( !Pawn.IsA('SwatEnemy') )
        return;

    if(IsInArray(Pawn, UnevacuatedDownedSuspects))
        return;

    if(IsInArray(Pawn, ReportedDownedSuspects))
        return;

    if (IsInArray(Pawn, ArrestedSuspects))
        return;

    Add( Pawn, UnevacuatedDownedSuspects );
}

function OnReportableReportedToTOC(IAmReportableCharacter ReportedCharacter, Pawn Reporter)
{
    if (!ReportedCharacter.IsA('SwatEnemy') )
        return;   //we only care about enemies

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" removed "$ReportedCharacter.name
            $" from the list of UnevacuatedDownedSuspects because ReportableReportedToTOC"
            $". UnevacuatedDownedSuspects.length="$UnevacuatedDownedSuspects.length);

	if(IsInArray(Pawn(ReportedCharacter), UnevacuatedDownedSuspects))
	{
		Remove( SwatPawn(ReportedCharacter), UnevacuatedDownedSuspects );
	}

    Add( SwatPawn(ReportedCharacter), ReportedDownedSuspects);
}

function string Status()
{
    local int ReportableDownedSuspects;

    ReportableDownedSuspects = UnevacuatedDownedSuspects.length;

    return String(ReportableDownedSuspects);
}

function int GetCurrentValue()
{
    local int ReportableDownedSuspects;

    ReportableDownedSuspects = UnevacuatedDownedSuspects.length;

    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerDownedSuspect * ReportableDownedSuspects\n"
            $"                           = "$PenaltyPerDownedSuspect$" * "$ReportableDownedSuspects$"\n"
            $"                           = "$PenaltyPerDownedSuspect * ReportableDownedSuspects);

    return PenaltyPerDownedSuspect * ReportableDownedSuspects;
}

function int GetPossible()
{
	return 0;
}