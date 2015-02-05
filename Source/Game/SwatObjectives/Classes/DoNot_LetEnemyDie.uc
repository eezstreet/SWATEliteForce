class DoNot_LetEnemyDie extends SwatGame.Objective_DoNot
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
    if  (!Pawn.IsA('SwatEnemy')) return; //we don't care

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" is setting its status to Failed because the Enemy named "$Pawn.name
            $" died.");

    SetStatus(ObjectiveStatus_Failed);
}
