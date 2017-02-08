class CustomScenarioCreatorData extends Core.Object
    config(CustomScenarioCreator);

var config string                       ScenariosPath;  //the relative path, from the executable directory, to the directory containing ScenarioPacks
var config string                       PackExtension;   //filename extension for ScenarioPack files.

var config array<name>                  AvailableObjective;
var config array<string>                AvailableObjectiveClass;

var config array<string>				PredefinedRedOneLoadOut;
var config array<string>				PredefinedRedTwoLoadOut;
var config array<string>				PredefinedBlueOneLoadOut;
var config array<string>				PredefinedBlueTwoLoadOut;

struct ArchetypePresentation
{
    var config name                     Archetype;
    var config bool                     ByDefault;  //should this Archetype be "selected" by default
};
var config array<ArchetypePresentation> HostageArchetype;
var config array<ArchetypePresentation> EnemyArchetype;

var config array<name>                  PrimaryWeaponCategory;
var config localized array<string>      PrimaryWeaponCategoryDescription;
var config array<name>                  BackupWeaponCategory;
var config localized array<string>      BackupWeaponCategoryDescription;

struct WeaponPresentation
{
    var config name                     Category;
    var config string                   Weapon;     //the path name of the weapon class, ripe for DLO'ing
};
var config array<WeaponPresentation>    PrimaryWeapon;
var config array<WeaponPresentation>    BackupWeapon;

var config localized string             AnyString;      //the localized word "Any"
var config localized string             AnyLoadoutString;      //the localized words "Any Loadout"
var config localized string             NoneString;     //the localized word "None"
var config localized string             CopyOfString;   //the localized words "Copy of"
var config localized string             NewScenarioString;   //the localized words "New Scenario"
var config localized string             DefaultPackString;   //the localized word "Default"
var config localized string             UnavailableString;  //the localized string "[ Unavailable ]"
var config localized string             LowString;  //the localized word "Low"
var config localized string             MediumString;  //the localized word "Medium"
var config localized string             HighString;  //the localized word "High"
var config localized string             EasyString;  //the localized word "Easy"
var config localized string             NormalString;  //the localized word "Normal"
var config localized string             HardString;  //the localized word "Hard"
var config localized string             EliteString;  //the localized word "Elite"
var config localized string             NumberOfHostagesString; //The localized words "Number of hostages"
var config localized string             NumberOfEnemiesString;  //The localized words "Number of enemies"
var config localized string             CommaIncludingString;   //The localized string ", including"
var config localized string             CampaignObjectivesString;   //The localized localized words "Campaign Objectives" for the end of a sentence
var config array<name>                ExtraMissions;

var config float                        DefaultTimeLimit;

var private SwatGUIConfig               GC;
var private bool                        bCurrentMissionDirty;

var array<CustomScenarioCreatorMissionSpecificData> MissionData;
var private int ExtraMissionsStart;

function bool IsCurrentMisisonDirty()
{
    return bCurrentMissionDirty;
}

function SetCurrentMissionDirty()
{
    bCurrentMissionDirty = true;
}

function ClearCurrentMissionDirty()
{
    bCurrentMissionDirty = false;
}


function Init(SwatGUIConfig inGC)
{
    local int i;

    GC = inGC;
    assert(GC != None);

    for (i=0; i<GC.CompleteMissionList.length; ++i)
    {
        MissionData[i] = new (None, string(GC.CompleteMissionList[i])) class'CustomScenarioCreatorMissionSpecificData';
        assert(MissionData[i] != None);
    }

    ExtraMissionsStart = MissionData.Length;
    for(i = 0; i < ExtraMissions.Length; i++) {
      MissionData[ExtraMissionsStart + i] = new(None, string(ExtraMissions[i])) class'CustomScenarioCreatorMissionSpecificData';
    }
}

//TMC TODO optimize this by using a hashmap
function CustomScenarioCreatorMissionSpecificData GetMissionData_Slow(name inMission)
{
    local int i;

    for (i=0; i<GC.CompleteMissionList.length; ++i)
    {
        if (GC.CompleteMissionList[i] == inMission)
        {
            assert(MissionData.length > i);     //it should have been initialized in construct()
            return MissionData[i];
        }
    }

    // Extra Missions
    for(i = 0; i < ExtraMissions.Length; i++) {
      if(ExtraMissions[i] == inMission) {
        return MissionData[ExtraMissionsStart + i];
      }
    }

    assertWithDescription(false,
        "[tcohen] CustomScenarioCreatorData::GetMissionData_Slow() the specified Mission named "$inMission
        $" was not found.");
}
