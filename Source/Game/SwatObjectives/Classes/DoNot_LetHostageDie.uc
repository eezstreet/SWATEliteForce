class DoNot_LetHostageDie extends SwatGame.Objective_DoNot
    implements IInterested_GameEvent_PawnDied;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.PawnDied.Register(self);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.PawnDied.UnRegister(self);
}

//IInterested_GameEvent_PawnDied Implementation
function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    local SwatHostage Hostage;

    if  (!Pawn.IsA('SwatHostage')) return; //we don't care

    Hostage = SwatHostage(Pawn);
    if(Hostage.IsDOA()) return; // It's a DOA, it doesn't count towards the objective

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" is setting its status to Failed because the Hostage named "$Pawn.name
            $" died.");

    SetStatus(ObjectiveStatus_Failed);
}
