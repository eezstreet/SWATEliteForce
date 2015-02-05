class Procedure_NoSuspectsIncapacitated extends SwatGame.Procedure
    implements  IInterested_GameEvent_PawnIncapacitated,
                IInterested_GameEvent_MissionCompleted;

var config int Bonus;

var bool AnyoneIncapacitated;
var bool MissionCompleted;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.PawnIncapacitated.Register(self);
    GetGame().GameEvents.MissionCompleted.Register(self);
}

//interface IInterested_GameEvent_PawnIncapacitated implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if (!Pawn.IsA('SwatEnemy')) return; //we don't care

    if (GetGame().DebugLeadership)
        log("[LEADERSHIP] "$class.name
            $" is setting AnyoneIncapacitated=true because PawnIncapacitated, Pawn="$Pawn.Name$", Incapacitator="$Incapacitator$".");

    AnyoneIncapacitated = true;
}

//interface IInterested_GameEvent_MissionCompleted implementation
function OnMissionCompleted()
{
    MissionCompleted = true;
}

//interface IProcedure implementation
function int GetCurrentValue()
{
    if (MissionCompleted && !AnyoneIncapacitated)
    {
        if (GetGame().DebugLeadershipStatus)
            log("[LEADERSHIP] "$class.name
                $" is returning CurrentValue = Bonus = "$Bonus
                $" because MissionCompleted && !AnyoneIncapacitated.");

        return Bonus;
    }
    else
    {
        if (GetGame().DebugLeadershipStatus)
            log("[LEADERSHIP] "$class.name
                $" is returning CurrentValue = 0"
                $" because MissionCompleted="$MissionCompleted$", AnyoneIncapacitated="$AnyoneIncapacitated);

        return 0;
    }
}
