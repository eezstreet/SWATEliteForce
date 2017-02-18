class SwatMission extends Core.RefCount
    config(SwatMissions)
    PerObjectConfig;

//Generic info
var() config string MapName "Name of the map that corresponds with this mission";
var() Editconst string FriendlyName "Name of the mission that will be displayed in the GUI";

//the Mission Objectives
var() EditConst Editinline MissionObjectives Objectives "The objectives for this mission";

//Generic mission info
var() config localized array<string> MissionDescription "A generic description of this mission (for the mission selection screen)";
var() config Material Thumbnail "Image that will be displayed on the mission selection screen for this mission";

//Briefing info
var() config localized array<string> BriefingText "Briefing text that will be displayed for the mission";
//var() config Material BriefingImage "Image that will be displayed on the briefing screen for this mission";

//Location info
var() config localized array<string> LocationInfoText "Text that will be displayed for the mission on the LocationInfo panel";
var() config Material Floorplans "An image that will be used as floorplans for this mission";

//Hostage info
var() config localized array<string> HostageName "The name of this Hostage";
var() config localized array<string> HostageVitals "A description of this Hostages vital stats";
var() config localized array<string> HostageDescription "A description of this Hostage";
var() config array<Material> HostageImage "A picture of this Hostage, default should be -no picture available-";

//Suspect info
var() config localized array<string> SuspectName "The name of this Suspect";
var() config localized array<string> SuspectVitals "A description of this Suspects vital stats";
var() config localized array<string> SuspectDescription "A description of this Suspect";
var() config array<Material> SuspectImage "A picture of this Suspect, default should be -no picture available-";

//Entry option info
var() config localized array<string> EntryOptionTitle "The title (usually 1 word) of this entry option";
var() config localized array<string> EntryDescription "The description of this entry option";
var() config array<Material> EntryImage "A picture of this Entry Option, default should be -no picture available-";

//Timeline info
var() config localized array<int>    TimeLinePlot "The time of this entry as an int from 0 - 100";
var() config localized array<string> TimeLineTime "The time of this entry (must be unique for each entry for this mission)";
var() config localized array<string> TimeLineShortDescription "The description to be used on the timeline itself";
var() config localized array<string> TimeLineLongDescription "The description to be used in the extended timeline scroll text";

var() config Material NewEquipmentImage "The image of the new piece of equipment available for this mission";
var() config localized string NewEquipmentName "The name of the new piece of equipment available for this mission";
var() config localized string NewEquipmentDescription "The description of the new piece of equipment available for this mission";
var() config Material SecondEquipmentImage "The image of the second piece of new equipment for this mission";
var() config localized string SecondEquipmentName "The name of the second piece of new equipment for this mission";
var() config localized string SecondEquipmentDescription "The description of the second piece of new equipment for this mission";

//Level Loading info
var() config localized string LoadingText "Text that will be displayed for the mission on the Loading Screen";
var() config Material LoadingImage "An image that will be displayed for the mission on the Loading Screen";

var(DEBUG) CustomScenario CustomScenario;
var(DEBUG) bool bBriefingPlayed;
var(DEBUG) private bool bHasMetDifficultyRequirement;
var() config bool bHas911DispatchAudio;

function Initialize( string theFriendlyName, CustomScenario inCustomScenario)
{
    FriendlyName = theFriendlyName;

    Objectives = new(None, string(self.Name), 0) class'MissionObjectives';

    CustomScenario = inCustomScenario;

    if (CustomScenario != None)
        CustomScenario.MutateMissionObjectives(Objectives);
}

function bool IsMissionCompleted()
{
    local int i;
    for (i=0; i<Objectives.Objectives.length; i++)
    {
        if  (   Objectives.Objectives[i].IsA('Objective_Do')    //completion of 'Objective_Do's is required for mission success
                && Objectives.Objectives[i].IsPrimaryObjective  //only primary objectives count
                && Objectives.Objectives[i].GetStatus() != ObjectiveStatus_Completed
            )
            return false;
    }
    return true;
}

function bool IsMissionFailed()
{
    local int i;
    for (i=0; i<Objectives.Objectives.length; i++)
    {
        if  ( Objectives.Objectives[i].IsPrimaryObjective  //only primary objectives count
              && Objectives.Objectives[i].GetStatus() == ObjectiveStatus_Failed
            )
            return true;
    }
    return false;
}

function bool IsMissionTerminal()
{
    local int i;
    for (i=0; i<Objectives.Objectives.length; i++)
    {
        if  ( Objectives.Objectives[i].IsTerminal  //only terminal objectives count
              && Objectives.Objectives[i].GetStatus() == ObjectiveStatus_Failed  // and only if they are failed
            )
            return true;
    }
    return false;
}

function bool HasMetDifficultyRequirement()
{
    return bHasMetDifficultyRequirement;
}

function SetHasMetDifficultyRequirement( bool inSuccess )
{
    bHasMetDifficultyRequirement = inSuccess;
}

defaultproperties
{
}
