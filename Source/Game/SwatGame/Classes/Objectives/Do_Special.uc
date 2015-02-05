class Do_Special extends Objective_Do
    implements IInterested_GameEvent_Special;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.Special.Register(self);
}

function OnSpecialGameEvent(name SpecialGameEvent)
{
    SetStatus(ObjectiveStatus_Completed);
}
