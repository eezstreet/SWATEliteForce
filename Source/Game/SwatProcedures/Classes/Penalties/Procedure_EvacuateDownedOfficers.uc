class Procedure_EvacuateDownedOfficers extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnIncapacitated,
                IInterested_GameEvent_PawnDied,
                IInterested_GameEvent_ReportableReportedToTOC;

var config int PenaltyPerDownedOfficer;

var array<SwatPawn> UnevacuatedDownedOfficers;

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
    if( !Pawn.IsA('SwatOfficer') ) 
        return;   //we only care about officers

    AssertNotInArray( Pawn, UnevacuatedDownedOfficers, 'UnevacuatedDownedOfficers' );
    Add( Pawn, UnevacuatedDownedOfficers );
}

function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if( !Pawn.IsA('SwatPlayer') ) 
        return;   //we only care about players

    AssertNotInArray( Pawn, UnevacuatedDownedOfficers, 'UnevacuatedDownedOfficers' );
    Add( Pawn, UnevacuatedDownedOfficers );
}

function OnReportableReportedToTOC(IAmReportableCharacter ReportedCharacter, Pawn Reporter)
{
    if (!ReportedCharacter.IsA('SwatOfficer') &&
        !ReportedCharacter.IsA('SwatPlayer') ) 
        return;   //we only care about officers

    AssertWithDescription( IsInArray( SwatPawn(ReportedCharacter), UnevacuatedDownedOfficers ), 
        "[LEADERSHIP] "$class.name
        $" Character "$ReportedCharacter.name
        $" was reported to TOC but was not in the UnevacuatedDownedOfficers array" );

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" removed "$ReportedCharacter.name
            $" from the list of UnevacuatedDownedOfficers because ReportableReportedToTOC"
            $". UnevacuatedDownedOfficers.length="$UnevacuatedDownedOfficers.length);
    
    Remove( SwatPawn(ReportedCharacter), UnevacuatedDownedOfficers );
}

function bool AnyPlayersAlive()
{
    local SwatPlayer Player;
    
    foreach GetGame().AllActors(class 'SwatPlayer', Player)
    {
        if( Player.IsAlive() )
            return true;
    }
    
    return false;
}

function string Status()
{
    local int ReportableDownedOfficers;
    
    ReportableDownedOfficers = UnevacuatedDownedOfficers.length;
    
    //if a player died and nobody is left alive to report him, that player doesn't count towards the penalty total
    if( !AnyPlayersAlive() )
        ReportableDownedOfficers--;

    return String(ReportableDownedOfficers);
}

function int GetCurrentValue()
{
    local int ReportableDownedOfficers;
    
    ReportableDownedOfficers = UnevacuatedDownedOfficers.length;
    
    //if a player died and nobody is left alive to report him, that player doesn't count towards the penalty total
    if( !AnyPlayersAlive() )
        ReportableDownedOfficers--;
        
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = PenaltyPerDownedOfficer * ReportableDownedOfficers\n"
            $"                           = "$PenaltyPerDownedOfficer$" * "$ReportableDownedOfficers$"\n"
            $"                           = "$PenaltyPerDownedOfficer * ReportableDownedOfficers);

    return PenaltyPerDownedOfficer * ReportableDownedOfficers;
}
