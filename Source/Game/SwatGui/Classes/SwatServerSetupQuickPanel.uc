class SwatServerSetupQuickPanel extends SwatGUIPanel
     ;

import enum EMPMode from Engine.Repo;
import enum EEntryType from SwatStartPointBase;
//copied from ServerSettings
const MAX_MAPS = 40;

var SwatServerSetupMenu SwatServerSetupMenu;

var(SWATGui) EditInline Config GUINumericEdit      MyRoundsBox;
var(SWATGui) EditInline Config GUIEditBox		   MyNameBox;
var(SWATGui) EditInline Config GUIEditBox          MyServerNameBox;
var(SWATGui) EditInline Config GUIEditBox		   MyPasswordBox;

var(SWATGui) EditInline Config GUICheckBoxButton   MyPasswordedButton;
var(SWATGui) EditInline Config GUICheckBoxButton   MyNoRespawnButton;
var(SWATGui) EditInline Config GUICheckBoxButton   MyQuickResetBox;

var(SWATGui) EditInline Config GUIComboBox         MyUseGameSpyBox;
var(SWATGui) EditInline Config GUIComboBox		   MyMapTypeBox;

var(SWATGui) EditInline Config GUIListBox          DisplayOnlyMaps;

var(SWATGui) EditInline Config GUIListBox		   SelectedMaps;
var(SWATGui) EditInline Config GUIListBox          AvailableMaps;

var(SWATGui) EditInline Config GUIButton		   MyRemoveButton;
var(SWATGui) EditInline Config GUIButton		   MyAddButton;
var(SWATGui) EditInline Config GUIButton		   MyUpButton;
var(SWATGui) EditInline Config GUIButton		   MyDownButton;
var(SWATGui) EditInline Config GUIButton           MyLoadMapsButton;

//Level information
var(SWATGui) EditInline Config GUIImage            MyLevelScreenshot;
var(SWATGui) EditInline Config GUILabel            MyIdealPlayerCount;
var(SWATGui) EditInline Config GUILabel            MyLevelAuthor;
var(SWATGui) EditInline Config GUILabel            MyLevelTitle;

// Level Filter
var(SWATGui) EditInline Config GUIComboBox			MyMapFilterBox;

var(DEBUG) int SelectedIndex;
var() private config localized string SelectedIndexColorString;

var(DEBUG) private string PreviousMap;

//level summary info
var(DEBUG) private Material NoScreenshotAvailableImage;
var(DEBUG) private config localized string IdealPlayerCountString;
var(DEBUG) private config localized string LevelAuthorString;
var(DEBUG) private config localized string LevelTitleString;

var(DEBUG) private GUIList FullMapList;

var() private config localized string LoadingMaplistString;
var() private config localized string LANString;
var() private config localized string GAMESPYString;
var() private config localized string MissionsString;
var() private config localized string QMMString;

var() private CustomScenarioCreatorData CustomScenarioCreatorData;
var protected CustomScenarioPack        CustomScenarioPack;

var() private bool bHaltMapLoading;
var() private bool bAllMissionsLoaded;
var() private array<string> AllMissionURLs;
var() private array<string> AllMissionDisplayNames;
var() private array<LevelSummary> AllMissionSummaries;

enum ServerSetupMapFilters
{
	MapFilter_All,		// All maps
	MapFilter_Original,	// SWAT 4 + TSS + SEF maps
	MapFilter_Custom,	// Custom Maps
};

var() private config localized array<String> MapFilterString;

///////////////////////////////////////////
// New feature in SEFv4: Don't load the maps all in one go, instead process one map per Tick

var private array<String> MapsToLoad;
var private int CurrentMapLoadIndex;

function LoadNextMap()
{
	local String NextMap;
	local LevelSummary Summary;

	NextMap = MapsToLoad[CurrentMapLoadIndex];

	//remove the extension
	if(Right(NextMap, 4) ~= ".s4m")
	{
		NextMap = Left(NextMap, Len(NextMap) - 4);
	}

	Summary = Controller.LoadLevelSummary(NextMap$".LevelSummary");

	if( Summary == None )
	{
	    log( "WARNING: Could not load a level summary for map '"$NextMap$".s4m'" );
	}
	else
	{
	    FullMapList.Add( NextMap, Summary, Summary.Title );
		AllMissionURLs[AllMissionURLs.Length] = NextMap;
		AllMissionDisplayNames[AllMissionDisplayNames.Length] = Summary.Title;
		AllMissionSummaries[AllMissionSummaries.Length] = Summary;
	}

	LoadAvailableMaps( EMPMode.MPM_COOP, MyMapFilterBox.List.GetExtraIntData() );
	LoadMapList( EMPMode.MPM_COOP );
}

function RegularMissionFrame()
{
	if(CurrentMapLoadIndex >= MapsToLoad.Length || bHaltMapLoading)
	{
		if(!bHaltMapLoading)
		{
			bAllMissionsLoaded = true;
		}
		else
		{
			AllMissionURLs.Length = 0;
			AllMissionDisplayNames.Length = 0;
			AllMissionSummaries.Length = 0;
			CurrentMapLoadIndex = 0;
		}
		bHaltMapLoading = false;
		return;
	}

	LoadNextMap();
	SetTimer(0.03);
	CurrentMapLoadIndex++;
}

function CustomMissionFrame()
{

}

event Timer()
{
	if(SwatServerSetupMenu.bQMM)
	{	// Load next QMM
		CustomMissionFrame();
	}
	else
	{	// Load next regular map
		RegularMissionFrame();
	}
}

///////////////////////////////////////////////////////////////////////////
// Initialization
///////////////////////////////////////////////////////////////////////////
function InitComponent(GUIComponent MyOwner)
{
	local int i;

    Super.InitComponent(MyOwner);

	CustomScenarioCreatorData = new class'CustomScenarioCreatorData';
    assert(CustomScenarioCreatorData != None);
    CustomScenarioCreatorData.Init(SwatGUIController(Controller).GuiConfig);

	CustomScenarioPack = new class'CustomScenarioPack';
    assert(CustomScenarioPack != None);

    FullMapList = GUIList(AddComponent("GUI.GUIList", self.Name$"_FullMapList", true ));

    LoadFullMapList();

    MyUseGameSpyBox.AddItem( LANString );
    MyUseGameSpyBox.AddItem( GAMESPYString );

	for(i = 0; i < ServerSetupMapFilters.EnumCount; i++)
	{
		MyMapFilterBox.AddItem(MapFilterString[i],,, i);
	}
	MyMapFilterBox.List.FindExtraIntData(0);

    SelectedMaps.List.OnDblClick=OnSelectedMapsDblClicked;
    SelectedMaps.OnChange=  OnSelectedMapsChanged;
    AvailableMaps.OnChange= OnAvailableMapsChanged;
    DisplayOnlyMaps.OnChange=OnAvailableMapsChanged;

    MyRemoveButton.OnClick= OnRemoveButtonClicked;
    MyAddButton.OnClick=    OnAddButtonClicked;
    MyUpButton.OnClick=     OnUpButtonClicked;
    MyDownButton.OnClick=   OnDownButtonClicked;
	MyLoadMapsButton.OnClick= OnLoadMapsButtonClicked;

	MyMapTypeBox.Clear();
	MyMapTypeBox.List.Add(QMMString, , , , true);
	MyMapTypeBox.List.Add(MissionsString, , , , false);

	MyMapTypeBox.OnChange=InternalOnChange;
    MyUseGameSpyBox.OnChange=InternalOnChange;
    MyPasswordedButton.OnChange=InternalOnChange;
	MyMapFilterBox.OnChange=InternalOnChange;

    MyNameBox.OnChange=OnNameSelectionChanged;
    MyNameBox.MaxWidth = GC.MPNameLength;
    MyNameBox.AllowedCharSet = GC.MPNameAllowableCharSet;

    MyServerNameBox.OnChange=OnNameSelectionChanged;
    MyPasswordBox.OnChange=OnNameSelectionChanged;
}

///////////////////////////////////////////////////////////////////////////
// Page Activation
///////////////////////////////////////////////////////////////////////////

event HandleParameters(string Param1, string Param2, optional int param3)
{
    LoadServerSettings( !SwatServerSetupMenu.bIsAdmin );
}

///////////////////////////////////////////////////////////////////////////
// Delegate handling
///////////////////////////////////////////////////////////////////////////
function InternalOnChange(GUIComponent Sender)
{
    switch( Sender )
    {
        case MyPasswordedButton:
            MyPasswordBox.SetEnabled( MyPasswordedButton.bChecked );
            SwatServerSetupMenu.RefreshEnabled();
            break;
        case MyUseGameSpyBox:
            SwatServerSetupMenu.bUseGameSpy = (MyUseGameSpyBox.List.Get() == GAMESPYString);
		    SwatServerSetupMenu.RefreshEnabled();
            break;
		case MyMapFilterBox:
			OnMapFilterChanged( ServerSetupMapFilters(MyMapFilterBox.GetInt()) );
			break;
		case MyMapTypeBox:
			OnMapTypeChanged( MyMapTypeBox.List.GetExtraBoolData() );
			break;
    }
}

private function OnNameSelectionChanged(GUIComponent Sender)
{
    SwatServerSetupMenu.RefreshEnabled();
}

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Components enabling/disabling/resetting to defaults
///////////////////////////////////////////////////////////////////////////
function SetSubComponentsEnabled( bool bSetEnabled )
{
    SwatServerSetupMenu.StartButton.SetEnabled( bSetEnabled );
    SwatServerSetupMenu.MyQuitButton.SetEnabled( bSetEnabled );
    MyRemoveButton.SetEnabled( bSetEnabled );
    MyAddButton.SetEnabled( bSetEnabled );
    MyUpButton.SetEnabled( bSetEnabled );
    MyDownButton.SetEnabled( bSetEnabled );
    AvailableMaps.SetEnabled( bSetEnabled );
    SelectedMaps.SetEnabled( bSetEnabled );
    DisplayOnlyMaps.SetEnabled( bSetEnabled );
    MyRoundsBox.SetEnabled( bSetEnabled );
    MyServerNameBox.SetEnabled( bSetEnabled && !SwatServerSetupMenu.bInGame );
    MyPasswordBox.SetEnabled( bSetEnabled && !SwatServerSetupMenu.bInGame );
    MyPasswordedButton.SetEnabled( bSetEnabled && !SwatServerSetupMenu.bInGame );
    MyNoRespawnButton.SetEnabled( bSetEnabled );
    MyQuickResetBox.SetEnabled( bSetEnabled );
    MyUseGameSpyBox.SetEnabled( bSetEnabled && !SwatServerSetupMenu.bInGame );
    MyNameBox.SetEnabled( bSetEnabled && !SwatServerSetupMenu.bInGame );
	MyMapFilterBox.SetEnabled(bSetEnabled);
	MyMapTypeBox.SetEnabled(bSetEnabled);
	MyLoadMapsButton.SetEnabled(bSetEnabled);

    MyRemoveButton.SetVisibility( bSetEnabled );
    MyAddButton.SetVisibility( bSetEnabled );
    MyUpButton.SetVisibility( bSetEnabled );
    MyDownButton.SetVisibility( bSetEnabled );
    AvailableMaps.SetVisibility( bSetEnabled );
    SelectedMaps.SetVisibility( bSetEnabled );
    DisplayOnlyMaps.SetVisibility( !bSetEnabled );

}

function DoRefreshEnabled()
{
    MyPasswordBox.SetEnabled( MyPasswordedButton.bChecked && SwatServerSetupMenu.bIsAdmin );

    MyRemoveButton.SetEnabled( SelectedMaps.GetIndex() >= 0 && SwatServerSetupMenu.bIsAdmin );
    MyUpButton.SetEnabled( SelectedMaps.GetIndex() > 0 && SwatServerSetupMenu.bIsAdmin );
    MyDownButton.SetEnabled( SelectedMaps.GetIndex() >= 0 && SelectedMaps.GetIndex() < SelectedMaps.Num()-1 && SwatServerSetupMenu.bIsAdmin );
    MyAddButton.SetEnabled( AvailableMaps.GetIndex() >= 0 && SelectedMaps.Num() <= MAX_MAPS && SwatServerSetupMenu.bIsAdmin );
}

function DoResetDefaultsForGameMode( EMPMode NewMode )
{
    //COOP special
    if( NewMode == EMPMode.MPM_COOP || NewMode == EMPMode.MPM_COOPQMM )
    {
        MyQuickResetBox.SetChecked(false);

        MyQuickResetBox.DisableComponent();

        //default 1 rounds per map for non-coop
        MyRoundsBox.SetValue( 1 );
    }
    else
    {
        MyQuickResetBox.SetChecked(true);

        //default 5 rounds per map for non-coop
        MyRoundsBox.SetValue( 5 );
    }

    MyNoRespawnButton.SetChecked(false);
}

///////////////////////////////////////////////////////////////////////////
// Load Settings
///////////////////////////////////////////////////////////////////////////
function LoadServerSettings( optional bool ReadOnly )
{
    local ServerSettings Settings;

    //
    // choose the correct settings:
    //    non-admin (read-only):  Current settings
    //    admin:                  Pending settings
    //
    if( ReadOnly )
        Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
    else
        Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);

    //
    // Select the current map
    //
    SetSelectedMapsIndex( Settings.MapIndex );
    PreviousMap = SelectedMaps.List.GetItemAtIndex(SelectedIndex);

    //
    // if non-admin: Load the map list to the DisplayOnlyMaps list box
    //
    if( ReadOnly )
    {
        DisplayOnlyMaps.SetIndex( Settings.MapIndex );
        UpdateSelectedIndexColoring( DisplayOnlyMaps );
        DisplayLevelSummary( LevelSummary( DisplayOnlyMaps.List.GetObject() ) );
    }

    //
    // Load the rest of the settings
    //
    MyRoundsBox.SetValue(Settings.NumRounds, true);
    MyPasswordedButton.bForceUpdate = true;
    MyNoRespawnButton.SetChecked( Settings.bNoRespawn );
    MyQuickResetBox.SetChecked( Settings.bQuickRoundReset );
	MyMapTypeBox.List.FindExtraBoolData(Settings.bIsQMM);

    //
    // Update the general server information/player name
    //
    MyServerNameBox.SetText(Settings.ServerName);
    MyPasswordBox.SetText(Settings.Password);
    MyPasswordedButton.SetChecked( Settings.bPassworded );
    SwatServerSetupMenu.bUseGameSpy = !Settings.bLAN;
    if( SwatServerSetupMenu.bUseGameSpy )
        MyUseGameSpyBox.Find( GAMESPYString );
    else
        MyUseGameSpyBox.Find( LANString );

    MyNameBox.SetText(GC.MPName);
}

///////////////////////////////////////////////////////////////////////////
// Save Settings
///////////////////////////////////////////////////////////////////////////
function SaveServerSettings()
{
    local int i;
    local ServerSettings Settings;

    //
    // Save to the pending server settings
    //
    Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);

    //
    // Save all maps
    //
	Settings.bIsQMM = MyMapTypeBox.List.GetExtraBoolData();
    SwatPlayerController(PlayerOwner()).ServerClearMaps( Settings );

    for( i = 0; i < SelectedMaps.Num(); i++ )
    {
		if(Settings.bIsQMM)
		{	// Flipped for QMM purposes
			log("Adding map to list: "$SelectedMaps.List.GetExtraAt(i));
			SwatPlayerController(PlayerOwner()).ServerAddMap( Settings,
				StripHTMLColors(SelectedMaps.List.GetExtraAt(i)),
				PackPlusExtension(SelectedMaps.List.GetAt(i)) );
		}
		else
		{
			SwatPlayerController(PlayerOwner()).ServerAddMap( Settings, SelectedMaps.List.GetAt(i) );
		}
    }

    //
    // Set the ServerSettings as Dirty if any of the following major changes have been made:
    //
    //  - The GameMode
    //  - LAN / Internet
    //  - Selected Map
    //
    if( Settings.bLAN != !SwatServerSetupMenu.bUseGameSpy ||
        PreviousMap != SelectedMaps.List.GetItemAtIndex(SelectedIndex) )
    {
        SwatPlayerController(PlayerOwner()).ServerSetDirty( Settings );
    }



    //
    // Update admin server information
    //
    SwatPlayerController(PlayerOwner()).ServerSetAdminSettings( Settings,
                                MyServerNameBox.GetText(),
                                MyPasswordBox.GetText(),
                                MyPasswordedButton.bChecked,
                                !SwatServerSetupMenu.bUseGameSpy );


    SwatPlayerController(PlayerOwner()).SetName( MyNameBox.GetText() );
}

///////////////////////////////////////////////////////////////////////////
// MapFilter change
///////////////////////////////////////////////////////////////////////////
function OnMapFilterChanged( ServerSetupMapFilters NewFilter )
{
	// Just load the available maps
	LoadAvailableMaps(EMPMode.MPM_COOP, NewFilter);
}

///////////////////////////////////////////////////////////////////////////
// Load Maps button
///////////////////////////////////////////////////////////////////////////
function OnLoadMapsButtonClicked( GUIComponent Sender )
{
	local int i;
	local string PackFileName;

	//DisplayLevelSummary( LevelSummary( AvailableMaps.List.GetObject() ) );
	AvailableMaps.Clear();
	SelectedMaps.Clear();

	if(SwatServerSetupMenu.bQMM)
	{
		foreach FileMatchingPattern("*."$CustomScenarioCreatorData.PackExtension, PackFileName)
		{
			CustomScenarioPack.Reset(PackFileName, CustomScenarioCreatorData.ScenariosPath);
			PackFileName = PackMinusExtension(PackFileName);

			// Add each one from the pack
			for(i = 0; i < CustomScenarioPack.ScenarioStrings.Length; i++)
			{
				AvailableMaps.List.Add(PackFileName, , CustomScenarioPack.ScenarioStrings[i]);
			}
		}
	}
	else if(bAllMissionsLoaded)
	{	// We loaded all of the missions previously. No need to load them again.
		assert(AllMissionURLs.Length == AllMissionDisplayNames.Length);
		assert(AllMissionSummaries.Length == AllMissionURLs.Length);

		for(i = 0; i < AllMissionURLs.Length; i++)
		{
			AvailableMaps.List.Add(AllMissionURLs[i], AllMissionSummaries[i], AllMissionDisplayNames[i]);
		}
	}
	else
	{	// Start loading them!
		SetTimer(0.03);
	}
}

///////////////////////////////////////////////////////////////////////////
//	Populating with the current list of maps
///////////////////////////////////////////////////////////////////////////
function PopulateNormalMaps()
{
	local ServerSettings Settings;
	local LevelSummary Summary;
	local int i;

	Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);

	// Clear out map list
	SelectedMaps.List.Clear();

	// Iterate through the list of maps
	for(i = 0; i < Settings.NumMaps; i++)
	{
		if(Settings.Maps[i] != "")
		{
			Summary = Controller.LoadLevelSummary(Settings.Maps[i]$".LevelSummary");
			SelectedMaps.List.Add(Settings.Maps[i], Summary, Summary.Title);
		}
	}
}

function PopulateQMMMaps()
{
	local ServerSettings Settings;
	local int i;
	local string PackName;

	Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);

	// Clear out map list
	SelectedMaps.List.Clear();

	// Iterate through the list of maps
	for(i = 0; i < Settings.NumMaps; i++)
	{
		if(Settings.QMMScenarioQueue[i] != "" && Settings.QMMPackQueue[i] != "")
		{
			PackName = PackMinusExtension(Settings.QMMPackQueue[i]);
			SelectedMaps.List.Add(PackName, , Settings.QMMScenarioQueue[i]);
		}
	}
}

///////////////////////////////////////////////////////////////////////////
//	Map Type box
///////////////////////////////////////////////////////////////////////////
function OnMapTypeChanged(bool bQMM)
{
	bHaltMapLoading = true;

	AvailableMaps.List.Clear();

	SwatServerSetupMenu.bQMM = bQMM;

	if(bQMM)
	{
		MyMapFilterBox.DisableComponent();
		PopulateQMMMaps();
	}
	else
	{
		MyMapFilterBox.EnableComponent();
		PopulateNormalMaps();
	}
}

///////////////////////////////////////////////////////////////////////////
// GameMode Updates
///////////////////////////////////////////////////////////////////////////
function OnGameModeChanged( EMPMode NewMode )
{
    log( self$"::OnGameModeChanged( "$GetEnum(EMPMode,NewMode)$" )" );

    //load the available map list
    LoadAvailableMaps( NewMode, 0 );

    //load the Map rotation for the new game mode
    LoadMapList( NewMode );

    SetSubComponentsEnabled( SwatServerSetupMenu.bIsAdmin );
    SwatServerSetupMenu.ResetDefaultsForGameMode( NewMode );

    SwatServerSetupMenu.RefreshEnabled();

    DisplayLevelSummary( LevelSummary( AvailableMaps.List.GetObject() ) );

    SetTimer(0.03);
}

///////////////////////////////////////////////////////////////////////////
// Maplist Management
///////////////////////////////////////////////////////////////////////////

/*
 * Returns true if this map is an RMX map
 */
function bool IsRMXMap(String LevelName)
{
	return InStr(LevelName, "RMX") != -1 || InStr(LevelName, "rmx") != -1 || InStr(LevelName, "COOP") != -1;
}

/*
 * Returns true if this map is a Hardcore map
 */
function bool IsHardcoreMap(String LevelName)
{
	return InStr(LevelName, "Hardcore") != -1 || InStr(LevelName, "hardcore") != -1;
}

/*
 * Returns true if this map (based on the author and level name) is allowed to be shown, based on the map filter.
 */
function bool MapAllowed(String AuthorName, String LevelName, int NewFilter)
{
	if(NewFilter == ServerSetupMapFilters.MapFilter_Custom)
	{
		if(IsRMXMap(LevelName) || IsHardcoreMap(LevelName))
		{
			return true;
		}
		else if(AuthorName ~= "Irrational Games" || AuthorName ~= "Irrational Games, LLC" || AuthorName ~= "SEF Team")
		{
			return false;
		}
		return true;
	}
	else if(NewFilter == ServerSetupMapFilters.MapFilter_Original)
	{
		if(IsRMXMap(LevelName) || IsHardcoreMap(LevelName))
		{
			return false;
		}
		else if(AuthorName ~= "Irrational Games" || AuthorName ~= "Irrational Games, LLC" || AuthorName ~= "SEF Team")
		{
			return true;
		}
		return false;
	}
	else
	{
		return true;
	}
}

function LoadAvailableMaps( EMPMode NewMode, int NewFilter )
{
    local int i, j;
    local LevelSummary Summary;

    AvailableMaps.Clear();

    for( i = 0; i < FullMapList.ItemCount; i++ )
    {
        Summary = LevelSummary( FullMapList.GetObjectAtIndex(i) );

        for( j = 0; j < Summary.SupportedModes.Length; j++ )
        {
            if( Summary.SupportedModes[j] == NewMode &&
				MapAllowed(Summary.Author, Summary.Title, NewFilter))
            {
                AvailableMaps.List.AddElement( FullMapList.GetAtIndex(i) );
                break;
            }
        }
    }

    AvailableMaps.List.Sort();

    if(CurrentMapLoadIndex >= MapsToLoad.Length)
	{
		MyMapFilterBox.EnableComponent();
    }
}

/*
 * Populates the list of selected maps
 */
function LoadMapList( EMPMode NewMode )
{
    local int i, j;

    SelectedMaps.Clear();

    for( i = 0; i < GC.MapList[NewMode].NumMaps; i++ )
    {
        AvailableMaps.List.Find( GC.MapList[NewMode].Maps[i] );
        j = AvailableMaps.GetIndex();

        if( j < 0 )
            continue;

        SelectedMaps.List.AddElement( AvailableMaps.List.GetAtIndex(j) );
    }

    SetSelectedMapsIndex( 0 );
}

/*
 * Get a list of map files (.s4m) and put them in MapsToLoad
 */
function LoadFullMapList()
{
	local string FileName;

    FullMapList.Clear();

    foreach FileMatchingPattern( "*.s4m", FileName )
    {
        //skip autoplay files (auto generated by UnrealEd)
        if( InStr( FileName, "autosave" ) != -1 )
            continue;

        MapsToLoad[MapsToLoad.Length] = FileName;
    }
}

///////////////////////////////////////////////////////////////////////////
// MapList delegate handling
///////////////////////////////////////////////////////////////////////////
function OnAddButtonClicked( GUIComponent Sender )
{
    if( AvailableMaps.GetIndex() < 0 )
        return;

    SelectedMaps.List.AddElement( AvailableMaps.List.GetElement() );
}

function OnRemoveButtonClicked( GUIComponent Sender )
{
    local int index;

    index = SelectedMaps.GetIndex();

    if( index < 0 )
        return;

    SelectedMaps.List.Remove( index );

    if( SelectedIndex > index )
        SelectedIndex--;
    else if( SelectedIndex == index )
        SetSelectedMapsIndex( 0 );
}

function OnUpButtonClicked( GUIComponent Sender )
{
    local int index;

    index = SelectedMaps.GetIndex();

    if( index <= 0 )
        return;

    SelectedMaps.List.SwapIndices( index, index-1 );
    SelectedMaps.SetIndex( index-1 );

    if( SelectedIndex == index )
        SelectedIndex--;
    else if( SelectedIndex == index-1 )
        SelectedIndex++;
}

function OnDownButtonClicked( GUIComponent Sender )
{
    local int index;

    index = SelectedMaps.GetIndex();

    if( index < 0 || index >= SelectedMaps.Num()-1 )
        return;

    SelectedMaps.List.SwapIndices( index, index+1 );
    SelectedMaps.SetIndex( index+1 );

    if( SelectedIndex == index )
        SelectedIndex++;
    else if( SelectedIndex == index+1 )
        SelectedIndex--;
}

function LevelSummary GetSummaryFromQMMData(string PackName, string ScenarioName)
{
	local CustomScenario Scenario;
	local LevelSummary Summary;

	if(PackName == "" || ScenarioName == "")
	{	// lol "heh"
		return Summary;
	}

	// Load the scenario from the pack
	Scenario = new class'CustomScenario';
	assert(Scenario != None);

	ScenarioName=StripHTMLColors(ScenarioName); // stupid, a color code gets injected in here when adding a new map

	CustomScenarioPack.Reset(PackPlusExtension(PackName), CustomScenarioCreatorData.ScenariosPath);
	log("--GetSummaryFromQMMData("$PackName$","$ScenarioName$")");
	log("--CustomScenarioPack = "$CustomScenarioPack);
	assert(CustomScenarioPack.HasScenario(ScenarioName));

	CustomScenarioPack.LoadCustomScenarioInPlace(
		Scenario,
		ScenarioName,
		PackPlusExtension(PackName),
		CustomScenarioCreatorData.ScenariosPath
		);

	// Suss out what it is that we need to pull the summary from.
	// For non-custom maps, it's from the LevelLabel.
	// For custom maps, it's from the CustomMapURL
	if(Scenario.IsCustomMap)
	{
		Summary = Controller.LoadLevelSummary(Scenario.CustomMapURL$".LevelSummary");
	}
	else
	{
		Summary = Controller.LoadLevelSummary(string(Scenario.LevelLabel)$".LevelSummary");
	}

	return Summary;
}

function string GetMapURLFromQMM(string PackName, string ScenarioName)
{
	local CustomScenario Scenario;
	local string URL;

	if(PackName == "" || ScenarioName == "")
	{	// lol "heh"
		return "";
	}

	// Load the scenario from the pack
	Scenario = new class'CustomScenario';
	assert(Scenario != None);

	ScenarioName=StripHTMLColors(ScenarioName); // stupid, a color code gets injected in here when adding a new map

	CustomScenarioPack.Reset(PackPlusExtension(PackName), CustomScenarioCreatorData.ScenariosPath);
	assert(CustomScenarioPack.HasScenario(ScenarioName));

	CustomScenarioPack.LoadCustomScenarioInPlace(
		Scenario,
		ScenarioName,
		PackPlusExtension(PackName),
		CustomScenarioCreatorData.ScenariosPath
		);

	GC.SetCustomScenarioPackData(CustomScenarioPack, PackPlusExtension(PackName), CustomScenarioCreatorData.ScenariosPath);
	GC.SetCurrentMission(Scenario.LevelLabel, ScenarioName, Scenario);
	ServerSettings(PlayerOwner().Level.PendingServerSettings).SetQMMSettings(
		Scenario,
		CustomScenarioPack,
		false,
		0
		);

	if(Scenario.IsCustomMap)
	{
		URL = Scenario.CustomMapURL;
	}
	else
	{
		URL = string(Scenario.LevelLabel);
	}

	return URL;
}

function OnAvailableMapsChanged( GUIComponent Sender )
{
	local LevelSummary Summary;

	if(SwatServerSetupMenu.bQMM)
	{	// Pull from the pack (Data) and the scenario string (ExtraStrData)
		Summary = GetSummaryFromQMMData(AvailableMaps.List.Get(), AvailableMaps.List.GetExtra());
	}
	else
	{
		Summary = LevelSummary( AvailableMaps.List.GetObject() );
	}

	DisplayLevelSummary( Summary );

    SwatServerSetupMenu.RefreshEnabled();
}

function OnSelectedMapsChanged( GUIComponent Sender )
{
	local LevelSummary Summary;

    MapListOnChange( EMPMode.MPM_COOP );

    if( SelectedMaps.Num() <= 1 )
        SetSelectedMapsIndex( 0 );

	if(SwatServerSetupMenu.bQMM)
	{	// Pull from the pack (Data) and the scenario string (ExtraStrData)
		Summary = GetSummaryFromQMMData(SelectedMaps.List.Get(), SelectedMaps.List.GetExtra());
	}
	else
	{
		Summary = LevelSummary( SelectedMaps.List.GetObject() );
	}

	DisplayLevelSummary(Summary);

    SwatServerSetupMenu.RefreshEnabled();
}

function BootUpSelectedMap()
{
	local String URL;

	if(SwatServerSetupMenu.bQMM)
	{	// Painful.. we need to get the map URL from the custom scenario data
		URL = GetMapURLFromQMM(SelectedMaps.List.GetAt(SelectedIndex), SelectedMaps.List.GetExtraAt(SelectedIndex));
	}
	else
	{
		URL = SelectedMaps.List.GetItemAtIndex(SelectedIndex);
	}


    URL = URL $ "?Name=" $ MyNameBox.GetText() $ "?listen";

    if (MyPasswordedButton.bChecked)
    {
        URL = URL$"?GamePassword="$MyPasswordBox.GetText();
    }

    SwatGUIController(Controller).LoadLevel(URL);
}

function MapListOnChange( EMPMode NewMode )
{
    local int i;

    GC.MapList[NewMode].ClearMaps();

    for( i = 0; i < SelectedMaps.Num(); i++ )
    {
        GC.MapList[NewMode].AddMap( SelectedMaps.List.GetItemAtIndex(i) );
    }

    GC.MapList[NewMode].SaveConfig();
}

function OnSelectedMapsDblClicked( GUIComponent Sender )
{
    SetSelectedMapsIndex( SelectedMaps.GetIndex() );
}

function SetSelectedMapsIndex( int newSelectedIndex )
{
    SelectedIndex = newSelectedIndex;

    UpdateSelectedIndexColoring( SelectedMaps );
}

function UpdateSelectedIndexColoring( GUIListBox MapListBox )
{
    local int i;
    local string CurrentDisplayString;

    for( i = 0; i < MapListBox.Num(); i++ )
    {
        CurrentDisplayString = MapListBox.List.GetExtraAtIndex( i );

        if( Left( CurrentDisplayString, /*SelectedIndexColorString.Len()*/ 10 ) == SelectedIndexColorString )
        {
            MapListBox.List.SetExtraAtIndex( i, Mid( CurrentDisplayString, /*SelectedIndexColorString.Len()*/ 10 ) );
        }
    }

    if( MapListBox.Num() <= SelectedIndex )
        return;

    CurrentDisplayString = MapListBox.List.GetExtraAtIndex( SelectedIndex );

    if( InStr( CurrentDisplayString, SelectedIndexColorString ) == -1 )
    {
        MapListBox.List.SetExtraAtIndex( SelectedIndex, SelectedIndexColorString$CurrentDisplayString );
    }
}


///////////////////////////////////////////////////////////////////////////
// Display a level summary
///////////////////////////////////////////////////////////////////////////
function DisplayLevelSummary( LevelSummary Summary )
{
    if( Summary == None )
        return;

    if( Summary.Screenshot == None )
        MyLevelScreenshot.Image = NoScreenshotAvailableImage;
    else
        MyLevelScreenshot.Image = Summary.Screenshot;
    MyIdealPlayerCount.SetCaption( FormatTextString( IdealPlayerCountString, Summary.IdealPlayerCountMin, Summary.IdealPlayerCountMax ) );
    MyLevelAuthor.SetCaption( FormatTextString( LevelAuthorString, Summary.Author ) );
    MyLevelTitle.SetCaption( FormatTextString( LevelTitleString, Summary.Title ) );
}

//////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

defaultproperties
{
	OnActivate=InternalOnActivate

	LANString="LAN"
	GAMESPYString="Internet"

    LevelTitleString="Map: %1"
    LevelAuthorString="Author: %1"
    IdealPlayerCountString="Recommended Players: %1 - %2"

	MapFilterString[0]="All Maps"
	MapFilterString[1]="Stock Maps"
	MapFilterString[2]="Custom Maps"

	MissionsString="Missions"
	QMMString="Quick Missions"

    SelectedIndexColorString="[c=00ff00]"

	LoadingMaplistString="Searching for available maps..."
 }
