class Procedure_NoCiviliansInjured extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnDamaged,
                IInterested_GameEvent_MissionCompleted;

var config int Bonus;

var bool AnyoneDamaged;
var bool MissionCompleted;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnDamaged.Register(self);
    GetGame().GameEvents.MissionCompleted.Register(self);
}

function OnPawnDamaged(Pawn Pawn, Actor Damager)
{
    if (!Pawn.IsA('SwatHostage')) return;

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" is setting AnyoneDamaged=true because PawnDamaged, Pawn="$Pawn.name$", Damager="$Damager.name$".");

    AnyoneDamaged = true;
}

function OnMissionCompleted()
{
    MissionCompleted = true;
}

function int GetCurrentValue()
{
    if (MissionCompleted && !AnyoneDamaged)
    {
        if (GetGame().DebugLeadershipStatus)
            log("[LEADERSHIP] "$class.name
                $" is returning CurrentValue = Bonus = "$Bonus
                $" because MissionCompleted && !AnyoneDamaged.");

        return Bonus;
    }
    else
    {
        if (GetGame().DebugLeadershipStatus)
            log("[LEADERSHIP] "$class.name
                $" is returning CurrentValue = 0"
                $" because MissionCompleted="$MissionCompleted$", AnyoneDamaged="$AnyoneDamaged);

        return 0;
    }
}

function int GetPossible()
{
	return Bonus;
}
