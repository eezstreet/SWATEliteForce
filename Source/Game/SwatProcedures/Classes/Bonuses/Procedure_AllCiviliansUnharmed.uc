class Procedure_AllCiviliansUnharmed extends SwatGame.Procedure
  implements  IInterested_GameEvent_PawnDamaged;

var config int Bonus;

var array<SwatPawn> InjuredCivilians;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDamaged.Register(self);
}

//interface IInterested_GameEvent_PawnDamaged implementation
function OnPawnDamaged(Pawn Pawn, Actor Damager)
{
    if (!Pawn.IsA('SwatHostage')) return;

    Add( Pawn, InjuredCivilians );

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" added "$Pawn.name
            $" to its list of InjuredCivilians because it was injured."
            $" InjuredPlayers.length="$InjuredCivilians.length);
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    local float Modifier;
    local int total;
    local int NumPlayers;

    NumPlayers = GetNumActors( class'SwatHostage' );
	if(NumPlayers == 0)
	{	// If no civilians spawn on the map, then it's impossible to secure the bonus based on the logic below.
		// In this situation we should always award the bonus.
		return Bonus;
	}

    Modifier = float(NumPlayers-InjuredCivilians.length)/float(NumPlayers);
    total = int(float(Bonus)*Modifier);

    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" Bonus = "$Bonus$", NumHostages = "$NumPlayers$", InjuredCivilians.length = "$InjuredCivilians.length
            $" Modifier = ( (NumHostages-InjuredCivilians.length)/NumHostages ) = "$Modifier
            $" ... returning CurrentValue = Bonus * Modifier = "$total );

    return total;
}

///////////////////////////////////////

function string Status()
{
    local int NumHostages;

    NumHostages = GetNumActors( class'SwatHostage' );
    return (NumHostages - InjuredCivilians.length)
        $"/"$NumHostages;
}

///////////////////////////////////////
