class Automatic_DoNot_Die extends Objective_DoNot
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
    local SwatPlayer Player;

    if (!Pawn.IsA('SwatPlayer')) return;  //we don't care

    //if any players are still alive, objective was not failed (for COOP mainly)
    foreach Game.AllActors(class 'SwatPlayer', Player)
    {
        if( Player.IsAlive() )
            return;
    }

    SetStatus(ObjectiveStatus_Failed);
}