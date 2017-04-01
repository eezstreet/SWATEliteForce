class MissionObjectives extends Core.Object
    config(MissionObjectives)
    perObjectConfig;

import enum ObjectiveStatus from Objective;

var() Editinline editconst private config array<name> ObjectiveName;
var() Editinline editconst private config array<string> ObjectiveClass;

var() Editinline editconst array<Objective> Objectives;

var() Editinline editconst SwatGameInfo Game;

overloaded function Construct()
{
    local class<Objective> CurrentClass;
    local int i;

    log(self$": MissionObjectives::Construct()");

    AssertWithDescription(ObjectiveName.length == ObjectiveClass.length,
        "[tcohen] The list of "$class.name
        $" for the level ["$name
        $"] has a different number of ObjectiveNames and ObjectiveClasses."
        $"  There should be one ObjectiveClass for every ObjectiveName and vice-versa.");

    AddObjective(class'Automatic_DoNot_Die', 'Automatic_DoNot_Die');

    for (i=0; i<ObjectiveClass.length; ++i)
    {
        CurrentClass = class<Objective>(DynamicLoadObject(ObjectiveClass[i], class'Class'));

        AssertWithDescription(CurrentClass != None,
            "[tcohen] ObjectiveClass number "$i+1
            $" in the "$class.name
            $" for level ["$name
            $"], specified as "$ObjectiveClass[i]
            $", is not a valid Objective class.");

        AddObjective(CurrentClass, ObjectiveName[i]);
    }
}

function Initialize( SwatGameInfo GameInfo )
{
    local int i;

    Game = GameInfo;
    assert(Game != None);

    log(self$": MissionObjectives.Initialize()");
    log("Objectives.Length ="$Objectives.Length);

    for (i=0; i<Objectives.length; ++i)
        Objectives[i].InitializeObjective( Game );
}

function Objective AddObjective(class<Objective> CurrentClass, name CurrentName)
{
    local Objective CurrentObjective;

    log(self$": MissionObjectives.AddObjective()");

    CurrentObjective = new(None, string(CurrentName), 0) CurrentClass();
    assert(CurrentObjective != None);
    assert(CurrentObjective.IsA(CurrentClass.name));  //TMC test Karl's bugfix for constructors from dynamic types

    Objectives[Objectives.length] = CurrentObjective;

    //if (Game.DebugObjectives)
    //    log("[OBJECTIVES] Objective "$CurrentObjective.name$" ("$CurrentObjective.Description$") added");

    return CurrentObjective;
}

//target-based objectives should call this to add their SpawnerGroup to our list
function AddMissionObjectiveSpawnerGroup(Objective MissionObjective, name SpawnerGroup)
{
    log("[OBJECTIVES] Adding Mission Objective SpawnerGroup: SpawnerGroup "$SpawnerGroup$" for MissionObjective "$MissionObjective.name);

	MissionObjective.SpawnerGroups[MissionObjective.SpawnerGroups.length] = SpawnerGroup;
}

function bool AnyVisibleObjectivesInProgress()
{
    local int i;

    for( i = 0; i < Objectives.Length; i++ )
    {
        if( !Objectives[i].IsHidden &&
            Objectives[i].GetStatus() == ObjectiveStatus_InProgress )
            return true;
    }

    return false;
}
