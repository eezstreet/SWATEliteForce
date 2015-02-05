class DoNot_LetTimerExpire extends SwatGame.Objective_DoNot
    Implements IInterested_GameEvent_MissionFailed;

function Initialize()
{
    Super.Initialize();

    Game.GameEvents.MissionFailed.Register(self);

    assertWithDescription(Time > 0,
        "[tcohen] DoNot_LetTimerExpire::Initialize() Time=0");
}

//special case: you shouldn't complete this objective if you fail the mission
function OnMissionFailed()
{
    CurrentStatus = ObjectiveStatus_Failed;
}

