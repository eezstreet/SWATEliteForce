class DoNot_LetOfficerGetInjured extends SwatGame.Objective_DoNot
    implements IInterested_GameEvent_PawnDamaged;

function Initialize()
{
    Super.Initialize();

    //register for notifications that interest me
    Game.GameEvents.PawnDamaged.Register(self);
}

function UnRegisterGameEventsHook()
{
    Game.GameEvents.PawnDamaged.UnRegister(self);
}

//IInterested_GameEvent_PawnDamaged Implementation
function OnPawnDamaged(Pawn Pawn, Actor Damager)
{
    if  (
            !Pawn.IsA('SwatOfficer')
        &&  !Pawn.IsA('SwatPlayer')
        )
        return;       //we don't care

    if (Game.DebugObjectives)
        log("[OBJECTIVES] The "$class.name
            $" Objective named "$name
            $" is setting its status to Failed because the Officer named "$Pawn.name
            $" was damaged.");

    SetStatus(ObjectiveStatus_Failed);
}
