class SwatCampaignCoopSettingsPanel extends SwatGUIPanel;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;
import enum eSwatGameRole from SwatGame.SwatGuiConfig;

var(SWATGui) EditInline Config GUILabel MyCampaignNameLabel;

// Server Settings Panel
var(SWATGui) EditInline Config GUICheckBoxButton MyPasswordedButton;
var(SWATGui) EditInline Config GUIEditBox MyNameBox;
var(SWATGui) EditInline Config GUIEditBox MyPasswordBox;
var(SWATGui) EditInline Config GUINumericEdit MyMaxPlayersSpinner;
var(SWATGui) EditInline Config GUIComboBox MyDifficultyComboBox;
var(SWATGui) EditInline Config GUIComboBox MyEntryComboBox;
var(SWATGui) EditInline Config GUILabel MyDifficultySuccessLabel;
var(SWATGui) EditInline Config GUIComboBox MyPublishModeBox;
var(SWATGui) EditInline Config GUIScrollTextBox MyEntryDescription;

// Server Info Panel
var(SWATGui) EditInline Config GUILabel MyServerNameLabel;
var(SWATGui) EditInline Config GUILabel MyMapNameLabel;
var(SWATGui) EditInline Config GUILabel MyDifficultyNameLabel;
var(SWATGui) EditInline Config GUIListBox MyUnlockedEquipmentBox;
var(SWATGui) EditInline Config GUICheckBoxButton MyVotingEnabledBox;
var(SWATGui) EditInline Config GUICheckBoxButton MyEnableKillsBox;

var protected localized config string PrimaryEntranceLabel;
var protected localized config string SecondaryEntranceLabel;
var protected localized config string DifficultyString;
var protected localized config string DifficultyLabelString;
var() private config localized string LANString;
var() private config localized string GAMESPYString;

function InitComponent(GUIComponent MyOwner)
{
    local int i;

    Super.InitComponent(MyOwner);

    for(i = 0; i < eDifficultyLevel.EnumCount; i++)
    {
        MyDifficultyComboBox.AddItem(GC.DifficultyString[i]);
    }

    MyPublishModeBox.AddItem(LANString);
    MyPublishModeBox.AddItem(GAMESPYString);

    MyNameBox.MaxWidth = GC.MPNameLength;
    MyNameBox.AllowedCharSet = GC.MPNameAllowableCharSet;

    MyEntryComboBox.OnChange=ComboBoxOnChange;
    MyDifficultyComboBox.OnChange=ComboBoxOnChange;
    MyPasswordedButton.OnChange=GenericOnChange;
    MyMaxPlayersSpinner.OnChange=GenericOnChange;
    MyVotingEnabledBox.OnChange=GenericOnChange;
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

    switch(Element)
    {
        case MyDifficultyComboBox:
            GC.CurrentDifficulty = eDifficultyLevel(Element.GetIndex());
            MyDifficultyNameLabel.SetCaption(DifficultyString $ GC.DifficultyString[Element.GetIndex()]);
            MyDifficultySuccessLabel.SetCaption( FormatTextString( DifficultyLabelString, GC.DifficultyScoreRequirement[int(GC.CurrentDifficulty)] ) );
            break;

        case MyEntryComboBox:
            GC.SetDesiredEntryPoint(EEntryType(Element.GetIndex()));
            MyEntryDescription.SetContent(GC.CurrentMission.EntryDescription[Element.GetIndex()]);
            break;
    }
}

function InternalOnActivate()
{
    local ServerSettings Settings;
    local int i;

    Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

    MyPasswordedButton.SetChecked(Settings.bPassworded);
    MyPasswordBox.SetText(Settings.Password);
    MyDifficultyComboBox.SetIndex(GC.CurrentDifficulty);
    MyEntryComboBox.SetIndex(GC.GetDesiredEntryPoint());
    MyMapNameLabel.SetCaption(GC.CurrentMission.FriendlyName);
    MyCampaignNameLabel.SetCaption(SwatGUIController(Controller).GetCampaign().StringName);
    MyVotingEnabledBox.SetChecked(Settings.bAllowReferendums);

    if(Settings.bLAN)
    {
      MyPublishModeBox.SetIndex(0);
    }
    else
    {
      MyPublishModeBox.SetIndex(1);
    }

    MyMaxPlayersSpinner.SetValue(Settings.MaxPlayers, true);
    MyNameBox.SetText(GC.MPName);

    MyEntryComboBox.Clear();
    for(i = 0; i < GC.CurrentMission.EntryOptionTitle.Length; i++)
    {
        if(i == 0)
        {
            MyEntryComboBox.AddItem(GC.CurrentMission.EntryOptionTitle[i] $ " (Primary)");
        }
        else
        {
            MyEntryComboBox.AddItem(GC.CurrentMission.EntryOptionTitle[i] $ " (Secondary)");
        }
    }

	if(GC.SwatGameRole == eSwatGameRole.GAMEROLE_SP_Custom)
	{
		PopulateCustomUnlocks();
	}
	else
	{
		PopulateCampaignUnlocks();
	}
}

////////////////////////////////////////////////////////////////////////////////
//
//

// Called when using a QMM campaign
function PopulateCustomUnlocks()
{
	local Campaign theCampaign;
	local int i;
	local class<Equipment> Item;
	local CustomScenarioPack thePack;

	// Clear it first
	MyUnlockedEquipmentBox.List.Clear();

	theCampaign = SwatGuiController(Controller).GetCampaign();
	thePack = GC.GetCustomScenarioPack();

	if(thePack == None || !thePack.UseGearUnlocks)
	{	// Either no pack is loaded or the pack doesn't use unlocks
		return;
	}

	// First unlocks
	for(i = 0; i < theCampaign.GetAvailableIndex() + 1 && i < thePack.FirstEquipmentUnlocks.Length; i++)
	{
		Item = class<Equipment>(thePack.FirstEquipmentUnlocks[i]);
		if(Item == None)
		{
			continue;
		}
		MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
	}

	// Second unlocks
	for(i = 0; i < theCampaign.GetAvailableIndex() + 1 && i < thePack.SecondEquipmentUnlocks.Length; i++)
	{
		Item = class<Equipment>(thePack.SecondEquipmentUnlocks[i]);
		if(Item == None)
		{
			continue;
		}
		MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
	}

	MyUnlockedEquipmentBox.List.Sort();
}

// Called when using a non-QMM campaign
function PopulateCampaignUnlocks()
{
    local Campaign theCampaign;
    local int i;
    local class<ICanBeSelectedInTheGUI> Item;

    // Clear it first
    MyUnlockedEquipmentBox.List.Clear();

    theCampaign = SwatGUIController(Controller).GetCampaign();

    if(theCampaign.CampaignPath != 0)
    {
        return;
    }

    for(i = 0; i < theCampaign.GetAvailableIndex() + 1; i++)
    {
        Item = class<ICanBeSelectedInTheGUI>(class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment[i]);
        if(Item == None)
        {
            continue;
        }
        MyUnlockedEquipmentBox.List.Add(Item.static.GetFriendlyName());
    }

    for(i = class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length;
	 	i < class'SwatGame.SwatVanillaCareerPath'.default.Missions.Length + theCampaign.GetAvailableIndex() + 1;
		i++)
    {
        Item = class<ICanBeSelectedInTheGUI>(class'SwatGame.SwatVanillaCareerPath'.default.UnlockedEquipment[i]);
        if(Item == None)
        {
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

    LANString="LAN"
    GAMESPYString="Internet"
}
