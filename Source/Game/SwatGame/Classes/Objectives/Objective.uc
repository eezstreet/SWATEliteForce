class Objective extends Core.Object
    Implements IInterested_GameEvent_MissionEnded
    perObjectConfig
    config(ObjectiveSpecs);

//Note: This class would be abstract, except that the
//  CustomScenario Creator instantiates base Objectives
//  so that it can get the Description.

var config bool IsHidden;
var config bool UnhideIfFailed;

var config bool IsTerminal;
var config bool IsPrimaryObjective;
var config localized string Description;

var config float Time;
var config localized string TimerCaption;

enum ObjectiveStatus
{
    ObjectiveStatus_InProgress,
    ObjectiveStatus_Completed,
    ObjectiveStatus_Failed
};
var protected ObjectiveStatus CurrentStatus;

//when a mission ends, every objective is either
//  - automatically Completed if it was not Failed, or
//  - automatically Failed if it was not Completed.
//DefaultStatus is fixed for a class, so it is never set.
//use GetDefaultStatus() to access.
var protected ObjectiveStatus DefaultStatus;

//if CurrentStatus==InProgress after the game ends,
//  then it will be set to DefaultStatus.
//but we need to record the status when the game ended,
//  so that we can differentiate in the GUI between
//  objectives that actively changed status and
//  objectives that changed status just because the
//  game ended.
var ObjectiveStatus EndgameStatus;  //the status of the Objective when the game ended

var array<name> SpawnerGroups;

var SwatGameInfo Game;

final function InitializeObjective( SwatGameInfo GameInfo )
{
    Game = GameInfo;
    assert(Game != None);

    Initialize();
}

function Initialize()
{
    Game.GameEvents.MissionEnded.Register(self);

    //all subclasses should specify a DefaultStatus in defaultproperties
    assert(GetDefaultStatus() > ObjectiveStatus_InProgress);

    if( Time > 0 && !IsHidden )
    {
        StartTimer();
        //Hidden Timed Objectives don't start counting-down until they're unhidden
    }
}

function ObjectiveStatus GetStatus()
{
    return CurrentStatus;
}

function protected SetStatus(ObjectiveStatus newStatus)
{
    //TMC fix 142: Assert from failing mission twice
    /*
    assertWithDescription(CurrentStatus == ObjectiveStatus_InProgress,
        "[tcohen] The mission objective of class "$class.name
        $" named "$name
        $" was set to status "$ObjectiveStatusToString(newStatus)
        $".  But it was already set to status "$ObjectiveStatusToString(CurrentStatus)
        $".  An Objective should only change from InProgress.");
    */
    if(newStatus == CurrentStatus) {
      return;
    }
    CurrentStatus = newStatus;

    switch newStatus
    {
        case ObjectiveStatus_Completed:
              log("Objective "$self$" was completed");
              Game.OnMissionObjectiveCompleted(self);
              if (Time > 0)
                  StopTimer();
            break;

        case ObjectiveStatus_Failed:
            log("Objective "$self$" was failed");
            Game.OnMissionObjectiveFailed(self);
            if (Time > 0)
                StopTimer();

            //unhide the objective if it was failed and
            //   should be shown on the mission debriefing
            if( UnhideIfFailed )
                IsHidden = false;

            break;

        case ObjectiveStatus_InProgress:
            assertWithDescription(CurrentStatus == ObjectiveStatus_InProgress,
                "[tcohen] The mission objective of class "$class.name
                $" named "$name
                $" was set to status InProgress.  An Objective status should never be set to InProgress (they all start-out that way!).");
    }
}

//DefaultStatus is fixed for a class, and should never be set
//  (except in defaultproperties).
function ObjectiveStatus GetDefaultStatus()
{
    return default.DefaultStatus;
}

function string GetStatusString()
{
    return ObjectiveStatusToString(CurrentStatus);
}

private function string ObjectiveStatusToString(ObjectiveStatus Status)
{
    switch Status
    {
        case ObjectiveStatus_InProgress:
            return "In Progress";

        case ObjectiveStatus_Completed:
            return "Completed";

        case ObjectiveStatus_Failed:
            return "Failed";

        default:
            assert(false);  //unexpected ObjectiveStatus
    }
}

function OnMissionEnded()
{
    if( CurrentStatus == ObjectiveStatus_InProgress )
    {
        if (Game.DebugObjectives)
            log("[OBJECTIVES] OnMissionEnded(), "$name
                $" is going to its default status: "$GetEnum(ObjectiveStatus, DefaultStatus));

        CurrentStatus = DefaultStatus;
    }
    // for proper GC, ensure the timer delegate gets reset and the reference to the game is cleared
    if (Time > 0)
        StopTimer();

    UnRegisterGameEventsHook();
    Game.GameEvents.MissionEnded.UnRegister(self);
    Game=None;
}

// Allows subclasses to unregister from the game events they've registered with
function UnRegisterGameEventsHook();

function SetVisibility(bool Visible)
{
    local name EffectEvent;

    if (Visible != IsHidden) return;

    if (IsHidden && Visible)    //being unhidden
    {
        Game.Broadcast(Game, "", 'ObjectiveShown');

        if (Time > 0)           //has a time limit
            StartTimer();
    }

    IsHidden = !Visible;

    if (Visible)
        EffectEvent = 'ObjectiveShown';
    else
        EffectEvent = 'ObjectiveHidden';

    Game.TriggerEffectEvent(
            EffectEvent,
            ,                   //Actor Other
            ,                   //Material TargetMaterial
            ,                   //vector HitLocation
            ,                   //rotator HitNormal
            ,                   //bool PlayOnOther
            ,                   //bool QueryOnly
            ,                   //IEffectObserver Observer
            name);              //name ReferenceTag
}

function OnTimeExpired()
{
    SetStatus(ObjectiveStatus_Failed);
}

function StartTimer()
{
    Game.SetTimedMissionObjective(Self);
}

function StopTimer()
{
    Game.ClearTimedMissionObjective();
}

function bool HasSpawnerGroup(Name SpawnerGroup)
{
	local int i;

	for (i = 0; i < SpawnerGroups.Length; ++i)
		if (SpawnerGroups[i] == SpawnerGroup)
			return true;

	return false;
}

defaultproperties
{
    IsPrimaryObjective=true
}
