class SwatCampaignCoopSettingsPanel extends SwatGUIPanel;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;

var(SWATGui) EditInline Config GUILabel MyCampaignNameLabel;

// Server Settings Panel
var(SWATGui) EditInline Config GUICheckBoxButton MyPasswordedButton;
var(SWATGui) EditInline Config GUIEditBox MyNameBox;
var(SWATGui) EditInline Config GUIEditBox MyPasswordBox;
var(SWATGui) EditInline Config GUINumericEdit MyMaxPlayersSpinner;
var(SWATGui) EditInline Config GUIComboBox MyDifficultyComboBox;
var(SWATGui) EditInline Config GUIComboBox MyEntryComboBox;
var(SWATGui) EditInline Config GUILabel MyDifficultySuccessLabel;

// Server Info Panel
var(SWATGui) EditInline Config GUILabel MyServerNameLabel;
var(SWATGui) EditInline Config GUILabel MyMapNameLabel;
var(SWATGui) EditInline Config GUILabel MyDifficultyNameLabel;
var(SWATGui) EditInline Config GUIListBox MyUnlockedEquipmentBox;

var protected localized config string PrimaryEntranceLabel;
var protected localized config string SecondaryEntranceLabel;
var protected localized config string DifficultyString;
var protected localized config string DifficultyLabelString;

function InitComponent(GUIComponent MyOwner)
{
  local int i;

  Super.InitComponent(MyOwner);

  for(i = 0; i < eDifficultyLevel.EnumCount; i++)
  {
    MyDifficultyComboBox.AddItem(GC.DifficultyString[i]);
  }

  MyEntryComboBox.AddItem(PrimaryEntranceLabel);
  MyEntryComboBox.AddItem(SecondaryEntranceLabel);

  MyNameBox.MaxWidth = GC.MPNameLength;
  MyNameBox.AllowedCharSet = GC.MPNameAllowableCharSet;

  MyEntryComboBox.OnChange=ComboBoxOnChange;
  MyDifficultyComboBox.OnChange=ComboBoxOnChange;
  MyPasswordedButton.OnChange=GenericOnChange;
  MyMaxPlayersSpinner.OnChange=GenericOnChange;
}

function GenericOnChange(GUIComponent Sender)
{
  switch(Sender)
  {
    case MyPasswordedButton:
      MyPasswordBox.SetEnabled(MyPasswordedButton.bChecked);
      break;
  }
}

function ComboBoxOnChange(GUIComponent Sender)
{
  local GUIComboBox Element;

  Element = GUIComboBox(Sender);

  switch(Element) {
    case MyDifficultyComboBox:
      GC.CurrentDifficulty = eDifficultyLevel(Element.GetIndex());
      MyDifficultyNameLabel.SetCaption(DifficultyString $ GC.DifficultyString[Element.GetIndex()]);
      MyDifficultySuccessLabel.SetCaption( FormatTextString( DifficultyLabelString, GC.DifficultyScoreRequirement[int(GC.CurrentDifficulty)] ) );
      break;
    case MyEntryComboBox:
      GC.SetDesiredEntryPoint(EEntryType(Element.GetIndex()));
      break;
  }
}

function InternalOnActivate()
{
  local ServerSettings Settings;

  Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

  MyPasswordedButton.SetChecked(Settings.bPassworded);
  MyPasswordBox.SetText(Settings.Password);
  MyDifficultyComboBox.SetIndex(GC.CurrentDifficulty);
  MyEntryComboBox.SetIndex(GC.GetDesiredEntryPoint());
  MyMapNameLabel.SetCaption(GC.CurrentMission.FriendlyName);
  MyCampaignNameLabel.SetCaption(SwatGUIController(Controller).GetCampaign().StringName);

  MyMaxPlayersSpinner.SetValue(Settings.MaxPlayers, true);
  MyNameBox.SetText(GC.MPName);

  PopulateCampaignUnlocks();
}

////////////////////////////////////////////////////////////////////////////////
//
//

function PopulateCampaignUnlocks()
{
  local Campaign theCampaign;
  local int i;
  local class<ICanBeSelectedInTheGUI> Item;

  // Clear it first
  MyUnlockedEquipmentBox.List.Clear();

  theCampaign = SwatGUIController(Controller).GetCampaign();

  if(theCampaign.CampaignPath != 0) {
    return;
  }

  for(i = 0; i < theCampaign.GetAvailableIndex() + 1; i++) {
    Item = class<ICanBeSelectedInTheGUI>(GC.MissionEquipment[i]);
    if(Item == None) {
      continue;
    }
    MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
  }
  for(i = GC.MissionName.Length; i < GC.MissionName.Length + theCampaign.GetAvailableIndex() + 1; i++) {
    Item = class<ICanBeSelectedInTheGUI>(GC.MissionEquipment[i]);
    if(Item == None) {
      continue;
    }
    MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
  }

  MyUnlockedEquipmentBox.List.Sort();
}

defaultproperties
{
  OnActivate=InternalOnActivate

  PrimaryEntranceLabel="Primary"
  SecondaryEntranceLabel="Secondary"
  DifficultyString="Difficulty: "
  DifficultyLabelString="Score of [b]%1[\\b] required to advance."
}
