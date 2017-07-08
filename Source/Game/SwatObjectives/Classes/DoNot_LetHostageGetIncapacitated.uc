class DoNot_LetHostageGetIncapacitated extends SwatGame.Objective_DoNot
    implements IInterested_GameEvent_PawnIncapacitated;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.PawnIncapacitated.Register(self);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.PawnIncapacitated.UnRegister(self);
}

//IInterested_GameEvent_PawnIncapacitated Implementation
function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{
    if  (!Pawn.IsA('SwatHostage')) return; //we don't care

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" is setting its status to Failed because the Hostage named "$Pawn.name
            $" was incapacitated.");

    SetStatus(ObjectiveStatus_Failed);
}
