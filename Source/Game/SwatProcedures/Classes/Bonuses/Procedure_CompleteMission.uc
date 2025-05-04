class Procedure_CompleteMission extends SwatGame.Procedure
    implements IInterested_GameEvent_MissionCompleted;

var config int Bonus;

var int CurrentValue;

function PostInitHook()
{
    Super.PostInitHook();

    //register for notifications that interest me
    GetGame().GameEvents.MissionCompleted.Register(self);
}

function OnMissionCompleted()
{
    log("[LEADERSHIP] "$class.name
        $" is setting CurrentValue = Bonus = "$Bonus
        $" because MissionCompleted.");

    CurrentValue = Bonus;
}

function int GetCurrentValue()
{
    if (GetGame().DebugLeadershipStatus)
        log("[LEADERSHIP] "$class.name
            $" is returning CurrentValue = "$CurrentValue);

    return CurrentValue;
}

function int GetPossible()
{
	return Bonus;
}
