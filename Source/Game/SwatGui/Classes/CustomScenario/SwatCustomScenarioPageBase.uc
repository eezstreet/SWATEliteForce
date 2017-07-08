class SwatCustomScenarioPageBase extends SwatGUIPage;

var CustomScenarioCreatorData           CustomScenarioCreatorData;
var protected CustomScenarioPack        CustomScenarioPack;
var array<string>                       ScenarioPacks;

function InitComponent(GUIComponent MyOwner)
{
    //initialize Custom Scenario Creator

    CustomScenarioCreatorData = new class'CustomScenarioCreatorData';
    assert(CustomScenarioCreatorData != None);
    CustomScenarioCreatorData.Init(SwatGUIController(Controller).GuiConfig);

    CustomScenarioPack = new class'CustomScenarioPack';
    assert(CustomScenarioPack != None);

	Super.InitComponent(MyOwner);
}

// Pack Management
function SetCustomScenarioPack(string Pack)
{
    CustomScenarioPack.Reset(
            PackPlusExtension(Pack), 
            CustomScenarioCreatorData.ScenariosPath);
}

function CustomScenarioPack GetPack()
{
    return CustomScenarioPack;
}

function RefreshCustomScenarioPackList()
{
    local string PackFilename;

    ScenarioPacks.Remove(0, ScenarioPacks.length);

    foreach FileMatchingPattern(
            "*."$CustomScenarioCreatorData.PackExtension,
            PackFilename)
    {
        ScenarioPacks[ScenarioPacks.length] = PackMinusExtension(PackFilename);
    }
}

//Pass PackIterator=-1 to begin iteration.
//Repeated calls to NextCustomScenarioPack() will return each contained ScenarioPack.
//NextCustomScenarioPack maintains PackIterator, which will be set to -1 when
//  contained ScenarioPacks are exhausted.
//Proper usage looks like:
//  Iterator = -1;
//  do {
//      SomeItem = Next(Iterator);
//      if (Iterator >= 0)
//          Use(SomeItem);
//  } until (Iterator < 0);
function string NextCustomScenarioPack(out int PackIterator)
{
    local int Index;

    assert(PackIterator < ScenarioPacks.length);

    Index = PackIterator + 1;   //PackIterator -1 should return index 0, and so on

    if (Index < ScenarioPacks.length)
    {
//log("TMC SwatGUIConfig::NextCustomScenarioPack() ScenarioPacks.length="$ScenarioPacks.length$", PackIterator="$PackIterator$", incrementing PackIterator, returning index "$Index$"="$ScenarioPacks[Index]);
        PackIterator++;
        return ScenarioPacks[Index];
    }
    else
    {
//log("TMC SwatGUIConfig::NextCustomScenarioPack() ScenarioPacks.length="$ScenarioPacks.length$", PackIterator="$PackIterator$", setting PackIterator=-1, returning empty.");
        PackIterator = -1;
        return "";
    }
}

//returns a PackName with an extension
function string PackPlusExtension(string PackName)
{
    local string extension;

    extension = "." $ CustomScenarioCreatorData.PackExtension;

    if (Right(PackName, Len(extension)) == extension)
        return PackName;    //PackName already has extension
    else
        return PackName $ extension;
}

//returns a PackName without an extension
function string PackMinusExtension(string PackName)
{
    local string extension;

    extension = "." $ CustomScenarioCreatorData.PackExtension;

    if (Right(PackName, Len(extension)) != extension)
        return PackName;    //PackName already doesn't have an extension
    else
        return Left(PackName, Len(PackName) - Len(extension));
}
