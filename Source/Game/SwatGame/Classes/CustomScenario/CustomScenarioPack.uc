class CustomScenarioPack extends Core.Object
    config(_DynamicallyDetermined_)     //this is a dummy value - instances never use the default config file
    perObjectConfig;                    //we specify a section name in calls to Save/ResetConfig()

/*
 *	SWAT: Elite Force Scenario Pack Versions
 *
 *	Version 0: Vanilla game custom scenario packs
 *	Version 1: Elite Force custom scenario packs (base)
 */
const LatestPackVersion = 1;
var config localized int PackVersion;

// Added in version 0
var config localized array<string> ScenarioStrings;

// Added in version 1
var config bool UseProgression;
var config bool UseGearUnlocks;
var config array<class<Actor> > FirstEquipmentUnlocks;
var config array<class<Actor> > SecondEquipmentUnlocks;
var config array<class<Actor> > DisabledEquipment;

function Reset(
        string PackName,
        string Path)
{
    ScenarioStrings.Remove(0, ScenarioStrings.length);  //because ResetConfig() doesn't do anything if the section (not to mention the file) isn't found
    ResetConfig("Pack_Catalog", Path $ PackName);
}

//loads custom scenario data into the supplied CustomScenario
function LoadCustomScenarioInPlace(
        CustomScenario Scenario,
        string ScenarioString,
        string PackName,
        string Path)
{
    local string Section;
    local int Index;

    Reset(PackName, Path);

    Index = GetScenarioIndex(ScenarioString);

    if (Index >= ScenarioStrings.length)
    {
        assertWithDescription(false,
            "[tcohen] CustomScenarioPack::LoadCustomScenarioInPlace() The Scenario named "$ScenarioString
            $" was not found in the Pack with PackName = " $PackName$ " at Path = "$Path
            $".");
        return;
    }

    ScenarioStrings[Index] = ScenarioString;

    Section = "Scenario_"$ComputeMD5Checksum(ScenarioString);

    Scenario.ResetConfig(Section, Path$PackName);

    Scenario.ScenarioName = ScenarioString;
    Scenario.PackName = PackName;
}

function SaveCustomScenario(
        CustomScenario Scenario,
        string ScenarioString,
        string PackName,
        string Path)
{
    local string Section;
    local int Index;

    Reset(PackName, Path);

    Index = GetScenarioIndex(ScenarioString);

    ScenarioStrings[Index] = ScenarioString;

	log("Saving Custom Scenario: "$Path$PackName);
    SaveConfig("Pack_Catalog", Path$PackName);
    Section = "Scenario_"$ComputeMD5Checksum(ScenarioString);
    Scenario.SaveConfig(Section, Path$PackName);
}

function SavePack(string Path, string PackName)
{
	log(self$"...SavePack("$Path$", "$PackName$")");
	SaveConfig("Pack_Catalog", Path$PackName);
}

function DeleteCustomScenario(
        string ScenarioString,
        string PackName,
        string Path)
{
    local int Index;

    Reset(PackName, Path);

    Index = GetScenarioIndex(ScenarioString);

    if (Index >= ScenarioStrings.length)
    {
        assertWithDescription(false,
            "[tcohen] CustomScenarioPack::DeleteCustomScenario() The Scenario named "$ScenarioString
            $" was not found in the Pack at "$Path$PackName
            $".");
        return;
    }

    ScenarioStrings.Remove(Index, 1);

    SaveConfig("Pack_Catalog", Path$PackName);

    //This will leave an orphaned section in the Pack for the deleted Scenario.
    //I don't think that this can be easily avoided, and
    //  it won't hurt anything anyway.
}

//returns the index of ScenarioString if found,
//  otherwise returns the number of Scenarios in the Pack.
private function int GetScenarioIndex(string ScenarioString)
{
    local int i;

    for (i=0; i<ScenarioStrings.length; ++i)
        if (ScenarioStrings[i] == ScenarioString)
            break;

    return i;
}

function int GetScenarioCount()
{
    return ScenarioStrings.Length;
}

function bool HasScenario(string ScenarioString)
{
    local int i;

    for (i=0; i<ScenarioStrings.length; ++i)
        if (ScenarioStrings[i] == ScenarioString)
            return true;

    return false;
}
