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
var(SWATGui) private EditInline config GUIScrollTextBox MyEntryDescription;

var() localized config string PrimaryEntranceLabel;
var() localized config string SecondaryEntranceLabel;
var() localized config string DifficultyLabelString;

var() private string CurrentMap;
var() private eDifficultyLevel CurrentDifficulty;
var() private eEntryType CurrentEntry;


////////////////////////////////////////////////////////////////////////////////
//
//

private function SetMap()
{
  local SwatGameReplicationInfo SGRI;

  SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );

  SGRI.NextMap = CurrentMap;
  GC.SetDesiredEntryPoint(eEntryType(MyEntryBox.GetIndex()));
  GC.CurrentDifficulty = CurrentDifficulty;
  GC.SaveConfig();

  log(self$": SetMap(): SGRI.NextMap = "$CurrentMap$", GC.DesiredEntryPoint = "$CurrentEntry$", GC.CurrentDifficulty = "$CurrentDifficulty$"");
}

private function ClearMap()
{
  local SwatGameReplicationInfo SGRI;

  SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );

  SGRI.NextMap = "";
}

private function MapChanged()
{
  local SwatMission MissionInfo;
  local int i;

  CurrentMap = MyMapsList.List.Get();
  MissionInfo = new(None, CurrentMap) class'SwatGame.SwatMission';

  MyEntryBox.Clear();
  for(i = 0; i < MissionInfo.EntryOptionTitle.Length; i++)
  {
    if(i == 0)
    {
      MyEntryBox.AddItem(MissionInfo.EntryOptionTitle[i] $ " (Primary)");
    }
    else
    {
      MyEntryBox.AddItem(MissionInfo.EntryOptionTitle[i] $ " (Secondary)");
    }
    MyEntryDescription.SetContent(MissionInfo.EntryDescription[i]);
  }
}

private function DifficultyChanged()
{
  CurrentDifficulty = eDifficultyLevel(MyDifficultyBox.GetIndex());
  MyRequirementLabel.SetCaption( FormatTextString( DifficultyLabelString, GC.DifficultyScoreRequirement[int(CurrentDifficulty)] ) );
}

private function EntryChanged(int ChangedTo)
{
  local SwatMission MissionInfo;

  MissionInfo = new(None, CurrentMap) class'SwatGame.SwatMission';

  MyEntryDescription.SetContent(MissionInfo.EntryDescription[ChangedTo]);
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
      EntryChanged(MyEntryBox.GetIndex());
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
  CampaignPath = Settings.CampaignCOOP & 65535;
  CampaignAvailableIndex = (Settings.CampaignCOOP & -65536) >> 16;

  SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );
  CurrentMap = SGRI.NextMap;

  MyMapsList.Clear();

  if(CampaignPath == 0)
  {
    for(i = 0; i < class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length; i++)
    {
      if( i <= CampaignAvailableIndex ) {
        MyMapsList.List.Add(string(class'SwatGame.SwatVanillaCareerPath'.default.Missions[i]),,
			class'SwatGame.SwatVanillaCareerPath'.default.MissionFriendlyNames[i],i,,true);
      }
    }
  }
  else if(CampaignPath == 1)
  {
    for(i = 0; i < class'SwatGame.SwatSEFCareerPath'.default.Missions.Length; i++)
    {
      if( i <= CampaignAvailableIndex ) {
        MyMapsList.List.Add(
			string(class'SwatGame.SwatSEFCareerPath'.default.Missions[i]),,
			class'SwatGame.SwatSEFCareerPath'.default.MissionFriendlyNames[i],
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
  MyEntryBox.OnChange=CommonOnChange;

  for(i = 0; i < eDifficultyLevel.EnumCount; i++)
  {
    MyDifficultyBox.AddItem(GC.DifficultyString[i]);
  }
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
