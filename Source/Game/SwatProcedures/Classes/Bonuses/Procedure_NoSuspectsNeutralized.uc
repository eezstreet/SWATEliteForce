class Procedure_NoSuspectsNeutralized extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDied;
    
var config int Bonus;

var bool AnyoneNeutralized;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDied.Register(self);
}

//interface IInterested_GameEvent_PawnDied implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" is setting AnyoneNeutralized=true because PawnDied, Pawn="$Pawn.Name$", Killer="$Killer$".");

    AnyoneNeutralized = true;
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    if (!AnyoneNeutralized)
    {
        if (GetGame().DebugLeadershipStatus)
            log("[LEADERSHIP] "$class.name
                $" is returning CurrentValue = Bonus = "$Bonus
                $" because !AnyoneNeutralized.");

        return Bonus;
    }
    else
    {
        if (GetGame().DebugLeadershipStatus)
            log("[LEADERSHIP] "$class.name
                $" is returning CurrentValue = 0"
                $" because AnyoneNeutralized="$AnyoneNeutralized);

        return 0;
    }
}

function int GetPossible()
{
	return Bonus;
}