class Procedure_NoOfficersDown extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnIncapacitated,
                IInterested_GameEvent_PawnDied;

var config int Bonus;

var array<SwatPawn> DownedOfficers;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnIncapacitated.Register(self);
    GetGame().GameEvents.PawnDied.Register(self);
}

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if( !Pawn.IsA('SwatOfficer') )
        return;   //we only care about officers

    GetGame().CheckForCampaignDeath(Pawn);

    AssertNotInArray( Pawn, DownedOfficers, 'DownedOfficers' );
    Add( Pawn, DownedOfficers );
}

//interface IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if( !Pawn.IsA('SwatPlayer') )
        return;   //we only care about players

    GetGame().CheckForCampaignDeath(Pawn);

    AssertNotInArray( Pawn, DownedOfficers, 'DownedOfficers' );
    Add( Pawn, DownedOfficers );
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    local float Modifier;
    local int total;
    local int NumOfficers;

    NumOfficers = GetNumOfficers();
    Modifier = float(NumOfficers-DownedOfficers.length)/float(NumOfficers);
    total = int(float(Bonus)*Modifier);

    return total;
}

function int GetNumOfficers()
{
    return GetNumActors( class'SwatPlayer' ) + GetNumActors( class'SwatOfficer' );
}

///////////////////////////////////////

function string Status()
{
    local int NumOfficers;
    NumOfficers = GetNumOfficers();

    return (NumOfficers - DownedOfficers.length)
        $"/"$( GetNumActors( class'SwatPlayer' ) + GetNumActors( class'SwatOfficer' ) );
}

///////////////////////////////////////
