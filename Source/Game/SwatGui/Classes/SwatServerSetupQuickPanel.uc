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

var(SWATGui) EditInline Config GUIComboBox         MyGameTypeBox;
var(SWATGui) EditInline Config GUIComboBox         MyUseGameSpyBox;

var(SWATGui) EditInline Config GUIListBox          DisplayOnlyMaps;

var(SWATGui) EditInline Config GUIListBox		   SelectedMaps;
var(SWATGui) EditInline Config GUIListBox          AvailableMaps;

var(SWATGui) EditInline Config GUIButton		   MyRemoveButton;
var(SWATGui) EditInline Config GUIButton		   MyAddButton;
var(SWATGui) EditInline Config GUIButton		   MyUpButton;
var(SWATGui) EditInline Config GUIButton		   MyDownButton;

//Level information
var(SWATGui) EditInline Config GUIImage            MyLevelScreenshot;
var(SWATGui) EditInline Config GUILabel            MyIdealPlayerCount;
var(SWATGui) EditInline Config GUILabel            MyLevelAuthor;
var(SWATGui) EditInline Config GUILabel            MyLevelTitle;

var(DEBUG) int SelectedIndex;
var() private config localized string SelectedIndexColorString;

var(DEBUG) private string PreviousMap;

//level summary info
var(DEBUG) private Material NoScreenshotAvailableImage;
var(DEBUG) private config localized string IdealPlayerCountString;
var(DEBUG) private config localized string LevelAuthorString;
var(DEBUG) private config localized string LevelTitleString;

var(DEBUG) private bool bUpdatingMapLists;

var(DEBUG) private GUIList FullMapList;

var() private config localized string LoadingMaplistString;
var() private config localized string LANString;
var() private config localized string GAMESPYString;

///////////////////////////////////////////
// New feature in SEFv4: Don't load the maps all in one go, instead process one map per Tick

var private array<String> MapsToLoad;
var private int CurrentMapLoadIndex;

function LoadNextMap() {
  local String NextMap;
  local LevelSummary Summary;

  NextMap = MapsToLoad[CurrentMapLoadIndex];

  //remove the extension
  if(Right(NextMap, 4) ~= ".s4m")
    NextMap = Left(NextMap, Len(NextMap) - 4);

  Summary = Controller.LoadLevelSummary(NextMap$".LevelSummary");

  if( Summary == None )
  {
      log( "WARNING: Could not load a level summary for map '"$NextMap$".s4m'" );
  }
  else
  {
      FullMapList.Add( NextMap, Summary, Summary.Title );
  }

  LoadAvailableMaps( SwatServerSetupMenu.CurGameType );
  LoadMapList( SwatServerSetupMenu.CurGameType );
}

event Timer() {
  // Don't update the map list if it's not a valid gametype
  if(MyGameTypeBox.List.GetExtraIntData() != EMPMode.MPM_COOP && MyGameTypeBox.List.GetExtraIntData() != EMPMode.MPM_COOPQMM) {
    bUpdatingMapLists = false;
    return;
  }

  if(CurrentMapLoadIndex >= MapsToLoad.Length) {
    bUpdatingMapLists = false;
    return;
  }

  LoadNextMap();
  SetTimer(0.03);
  CurrentMapLoadIndex++;
}

///////////////////////////////////////////////////////////////////////////
// Initialization
///////////////////////////////////////////////////////////////////////////
function InitComponent(GUIComponent MyOwner)
{
    Super.InitComponent(MyOwner);

    FullMapList = GUIList(AddComponent("GUI.GUIList", self.Name$"_FullMapList", true ));

    LoadFullMapList();

    MyUseGameSpyBox.AddItem( LANString );
    MyUseGameSpyBox.AddItem( GAMESPYString );

    //set the available missions for the list box
    /*for(i = 0; i < EMPMode.EnumCount; i++) {
      MyGameTypeBox.AddItem(GC.GetGameModeName(EMPMode(i)));
    }*/
	  MyGameTypeBox.AddItem(GC.GetGameModeName(MPM_COOP),,, EMPMode.MPM_COOP);
	  MyGameTypeBox.AddItem(GC.GetGameModeName(MPM_COOPQMM),,, EMPMode.MPM_COOPQMM);

    MyGameTypeBox.List.FindExtraIntData(EMPMode.MPM_COOP);

    SelectedMaps.List.OnDblClick=OnSelectedMapsDblClicked;
    SelectedMaps.OnChange=  OnSelectedMapsChanged;
    AvailableMaps.OnChange= OnAvailableMapsChanged;
    DisplayOnlyMaps.OnChange=OnAvailableMapsChanged;

    MyRemoveButton.OnClick= OnRemoveButtonClicked;
    MyAddButton.OnClick=    OnAddButtonClicked;
    MyUpButton.OnClick=     OnUpButtonClicked;
    MyDownButton.OnClick=   OnDownButtonClicked;

    MyGameTypeBox.OnChange=InternalOnChange;
    MyUseGameSpyBox.OnChange=InternalOnChange;
    MyPasswordedButton.OnChange=InternalOnChange;

    MyNameBox.OnChange=OnNameSelectionChanged;
    MyNameBox.MaxWidth = GC.MPNameLength;
    MyNameBox.AllowedCharSet = GC.MPNameAllowableCharSet;

    MyServerNameBox.OnChange=OnNameSelectionChanged;
    MyPasswordBox.OnChange=OnNameSelectionChanged;

    SetTimer(0.03);
    bUpdatingMapLists = true;
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
        case MyGameTypeBox:
            OnGameModeChanged( EMPMode(MyGameTypeBox.GetInt()) );
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
    MyGameTypeBox.SetEnabled( bSetEnabled );
    MyNameBox.SetEnabled( bSetEnabled && !SwatServerSetupMenu.bInGame );

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
    // update the game type, (also loads the available maps)
    //
    MyGameTypeBox.SetIndex(Settings.GameType);

    //
    // Load the selected maps from the ServerSettings
    //
    LoadServerMapList( SelectedMaps, Settings );

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
        LoadServerMapList( DisplayOnlyMaps, Settings );

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
    SwatPlayerController(PlayerOwner()).ServerClearMaps( Settings );
    for( i = 0; i < SelectedMaps.Num(); i++ )
    {
        SwatPlayerController(PlayerOwner()).ServerAddMap( Settings, SelectedMaps.List.GetItemAtindex( i ) );
    }

    //
    // Set the ServerSettings as Dirty if any of the following major changes have been made:
    //
    //  - The GameMode
    //  - LAN / Internet
    //  - Selected Map
    //
    if( Settings.GameType != SwatServerSetupMenu.CurGameType ||
        Settings.bLAN != !SwatServerSetupMenu.bUseGameSpy ||
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
// GameMode Updates
///////////////////////////////////////////////////////////////////////////
function OnGameModeChanged( EMPMode NewMode )
{
    log( self$"::OnGameModeChanged( "$GetEnum(EMPMode,NewMode)$" )" );

    SwatServerSetupMenu.CurGameType = NewMode;

    //load the available map list
    LoadAvailableMaps( NewMode );

    //load the Map rotation for the new game mode
    LoadMapList( NewMode );

    SetSubComponentsEnabled( SwatServerSetupMenu.bIsAdmin );
    SwatServerSetupMenu.ResetDefaultsForGameMode( NewMode );

    SwatServerSetupMenu.RefreshEnabled();

    DisplayLevelSummary( LevelSummary( AvailableMaps.List.GetObject() ) );

    SetTimer(0.03);
    bUpdatingMapLists = true;
}

///////////////////////////////////////////////////////////////////////////
// Maplist Management
///////////////////////////////////////////////////////////////////////////
function LoadAvailableMaps( EMPMode NewMode )
{
    local int i, j;
    local LevelSummary Summary;

    bUpdatingMapLists = true;

    AvailableMaps.Clear();

    for( i = 0; i < FullMapList.ItemCount; i++ )
    {
        Summary = LevelSummary( FullMapList.GetObjectAtIndex(i) );

        for( j = 0; j < Summary.SupportedModes.Length; j++ )
        {
            if( Summary.SupportedModes[j] == NewMode )
            {
                AvailableMaps.List.AddElement( FullMapList.GetAtIndex(i) );
                break;
            }
        }
    }

    AvailableMaps.List.Sort();

    if(CurrentMapLoadIndex >= MapsToLoad.Length) {
      bUpdatingMapLists = false;
    }
}

function LoadMapList( EMPMode NewMode )
{
    local int i, j;

    bUpdatingMapLists = true;

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

    if(CurrentMapLoadIndex >= MapsToLoad.Length) {
      bUpdatingMapLists = false;
    }
}

function LoadServerMapList( GUIListBox MapListBox, ServerSettings Settings )
{
    local int i, j;

    bUpdatingMapLists = true;

    MapListBox.Clear();

    for( i = 0; i < Settings.NumMaps; i++ )
    {
        AvailableMaps.List.Find( Settings.Maps[i] );
        j = AvailableMaps.GetIndex();

        if( j < 0 )
            continue;

        MapListBox.List.AddElement( AvailableMaps.List.GetAtIndex(j) );
    }

    if(CurrentMapLoadIndex >= MapsToLoad.Length) {
      bUpdatingMapLists = false;
    }
}


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

function OnAvailableMapsChanged( GUIComponent Sender )
{
    if( bUpdatingMapLists )
        return;

    DisplayLevelSummary( LevelSummary( AvailableMaps.List.GetObject() ) );

    SwatServerSetupMenu.RefreshEnabled();
}

function OnSelectedMapsChanged( GUIComponent Sender )
{
    if( bUpdatingMapLists )
        return;

    MapListOnChange( SwatServerSetupMenu.CurGameType );

    if( SelectedMaps.Num() <= 1 )
        SetSelectedMapsIndex( 0 );

    DisplayLevelSummary( LevelSummary( SelectedMaps.List.GetObject() ) );

    SwatServerSetupMenu.RefreshEnabled();
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

    SelectedIndexColorString="[c=00ff00]"

	LoadingMaplistString="Searching for available maps..."
 }
