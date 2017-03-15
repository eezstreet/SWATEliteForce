class SwatCampaignCoopMapPanel extends SwatGUIPanel
    Config(SwatGui);

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;
import enum EEntryType from SwatGame.SwatStartPointBase;

var(SWATGui) private EditInline config GUIListBox MyMapsList;
var(SWATGui) private EditInline config GUIComboBox MyDifficultyBox;
var(SWATGui) private EditInline config GUIComboBox MyEntryBox;
var(SWATGui) private EditInline config GUILabel MyRequirementLabel;
var(SWATGui) private EditInline config GUIButton MySetMapButton;
var(SWATGui) private EditInline config GUIButton MyClearMapButton;

var() localized config string PrimaryEntranceLabel;
var() localized config string SecondaryEntranceLabel;
var() localized config string DifficultyLabelString;

var() private string CurrentMap;
var() private eDifficultyLevel CurrentDifficulty;
var() private eEntryType CurrentEntry;

var config array<Name> ExtraMissionName "Name used for this mission (extra missions)";
var config array<String> ExtraFriendlyName "Friendly name used for this mission (extra missions)";


////////////////////////////////////////////////////////////////////////////////
//
//

private function SetMap()
{
  local SwatGameReplicationInfo SGRI;

  SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );

  SGRI.NextMap = CurrentMap;
  GC.SetDesiredEntryPoint(CurrentEntry);
  GC.CurrentDifficulty = CurrentDifficulty;
}

private function ClearMap()
{
  local SwatGameReplicationInfo SGRI;

  SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );

  SGRI.NextMap = "";
}

private function MapChanged()
{
  CurrentMap = MyMapsList.List.Get();
}

private function DifficultyChanged()
{
  CurrentDifficulty = eDifficultyLevel(MyDifficultyBox.GetIndex());
  MyRequirementLabel.SetCaption( FormatTextString( DifficultyLabelString, GC.DifficultyScoreRequirement[int(CurrentDifficulty)] ) );
}

private function EntryChanged()
{
  CurrentEntry = eEntryType(MyEntryBox.GetIndex());
}

////////////////////////////////////////////////////////////////////////////////
//
// Delegates

function CommonOnClick(GUIComponent Sender)
{
  switch(Sender)
  {
    case MySetMapButton:
      SetMap();
      break;
    case MyClearMapButton:
      ClearMap();
      break;
  }
}

function CommonOnChange(GUIComponent Sender)
{
  switch(Sender)
  {
    case MyMapsList:
      MapChanged();
      break;
    case MyDifficultyBox:
      DifficultyChanged();
      break;
    case MyEntryBox:
      EntryChanged();
      break;
  }
}

////////////////////////////////////////////////////////////////////////////////
//
// Initialization code

private function BuildCampaignMissionList()
{
  local SwatGameReplicationInfo SGRI;
  local int i;
  local int CampaignPath;
  local int CampaignAvailableIndex;
  local ServerSettings Settings;

  Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
  CampaignPath = Settings.ArrestRoundTimeDeduction & 65535;
  CampaignAvailableIndex = (Settings.ArrestRoundTimeDeduction & -65536) >> 16;

  SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );
  CurrentMap = SGRI.NextMap;

  MyMapsList.Clear();

  if(CampaignPath == 0)
  {
    for(i = 0; i < GC.MissionName.Length; i++)
    {
      if( i <= CampaignAvailableIndex ) {
        MyMapsList.List.Add(string(GC.MissionName[i]),,GC.FriendlyName[i],i,,true);
      }
    }
  }
  else if(CampaignPath == 1)
  {
    for(i = 0; i < ExtraMissionName.Length; i++)
    {
      if( i <= CampaignAvailableIndex ) {
        MyMapsList.List.Add(
          string(ExtraMissionName[i]),,
          ExtraFriendlyName[i],
          i,,
          true);
      }
    }
  }
  else
  {
    // assert or something?
  }
}

private function InitialSelections()
{
  // Set the selected map to SGRI.NextMap
  if(CurrentMap != "")
  {
    MyMapsList.List.Find(CurrentMap);
  }

  // Set the current Difficulty
  MyDifficultyBox.SetIndex(GC.CurrentDifficulty);

  // Set the current entry
  MyEntryBox.SetIndex(GC.GetDesiredEntryPoint());
}

private function CheckButtonsEnabled()
{
  if(GC.SwatGameState != GAMESTATE_PostGame)
  {
    MySetMapButton.DisableComponent();
    MyClearMapButton.DisableComponent();
  }
  else
  {
    MySetMapButton.EnableComponent();
    MyClearMapButton.EnableComponent();
  }
}

function InitComponent(GUIComponent MyOwner)
{
  local int i;

  Super.InitComponent(MyOwner);

  MySetMapButton.OnClick=CommonOnClick;
  MyClearMapButton.OnClick=CommonOnClick;

  MyDifficultyBox.OnChange=CommonOnChange;
  MyMapsList.OnChange=CommonOnChange;

  for(i = 0; i < eDifficultyLevel.EnumCount; i++)
  {
    MyDifficultyBox.AddItem(GC.DifficultyString[i]);
  }

  MyEntryBox.AddItem(PrimaryEntranceLabel);
  MyEntryBox.AddItem(SecondaryEntranceLabel);
}

private function InternalOnActivate()
{
  BuildCampaignMissionList();
  CheckButtonsEnabled();
  InitialSelections();
}

defaultproperties
{
  OnActivate=InternalOnActivate

  PrimaryEntranceLabel="Primary"
  SecondaryEntranceLabel="Secondary"
  DifficultyLabelString="Score of [b]%1[\\b] required to advance."
}
