class Procedure_PlayerUninjured extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDamaged;

var config int Bonus;

var array<SwatPawn> InjuredPlayers;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDamaged.Register(self);
}

//interface IInterested_GameEvent_PawnDamaged implementation
function OnPawnDamaged(Pawn Pawn, Actor Damager)
{
    if (!Pawn.IsA('SwatPlayer')) return;

    Add( Pawn, InjuredPlayers );

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of InjuredPlayers because it was injured."
            $" InjuredPlayers.length="$InjuredPlayers.length);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    local float Modifier;
    local int total;
    local int NumPlayers;

    NumPlayers = GetNumActors( class'SwatPlayer' );
    Modifier = float(NumPlayers-InjuredPlayers.length)/float(NumPlayers);
    total = int(float(Bonus)*Modifier);

    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" Bonus = "$Bonus$", NumPlayers = "$NumPlayers$", InjuredPlayers.length = "$InjuredPlayers.length
            $" Modifier = ( (NumPlayers-InjuredPlayers.length)/NumPlayers ) = "$Modifier
            $" ... returning CurrentValue = Bonus * Modifier = "$total );

    return total;
}

///////////////////////////////////////

function string Status()
{
    local int NumSwatPlayers;

    NumSwatPlayers = GetNumActors( class'SwatPlayer' );
    return (NumSwatPlayers - InjuredPlayers.length)
        $"/"$NumSwatPlayers;
}

///////////////////////////////////////
