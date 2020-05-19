class CustomScenario_HostagesTabPanel extends CustomScenarioTabPanel;

var(SWATGui) EditInline Config GUICheckBoxButton            chk_campaign;
var(SWATGui) EditInline Config GUICheckBoxButton            chk_advanced;
var(SWATGui) EditInline Config GUIPanel                     pnl_body;
var(SWATGui) EditInline Config GUIImage                     pnl_DisabledOverlay;
var(SWATGui) EditInline Config GUIDualSelectionLists        dlist_archetypes;

var(SwatGUI) EditInline Config GUILabel                     lbl_count;
var(SwatGUI) EditInline Config GUINumericEdit               spin_count_min;
var(SwatGUI) EditInline Config GUILabel                     lbl_count_min;
var(SwatGUI) EditInline Config GUILabel                     lbl_count_max;
var(SwatGUI) EditInline Config GUINumericEdit               spin_count_max;
var(SwatGUI) EditInline Config GUILabel                     lbl_morale;
var(SwatGUI) EditInline Config GUISlider                    slide_morale_min;
var(SwatGUI) EditInline Config GUILabel                     lbl_morale_min;
var(SwatGUI) EditInline Config GUILabel                     lbl_morale_max;
var(SwatGUI) EditInline Config GUISlider                    slide_morale_max;

// Advanced settings
var(SWATGui) EditInline Config GUILabel                     RosterListLabel;
var(SwatGUI) EditInline Config GUIListBox                   RosterList;
var(SwatGUI) EditInline Config GUIEditBox                   CreateRosterName;
var(SwatGUI) EditInline Config GUIButton                    CreateRosterButton;
var(SwatGUI) EditInline Config GUIButton                    DeleteRosterButton;
var(SwatGUI) EditInline Config GUILabel                     EditRosterLabel;
var(SwatGUI) EditInline Config GUIListBox                   RosterArchetypeList;
var(SwatGUI) EditInline Config GUILabel                     ArchetypeListLabel;
var(SwatGUI) EditInline Config GUIComboBox                  RosterNewArchetypeSelection;
var(SwatGUI) EditInline Config GUIButton                    RosterAddArchetypeButton;
var(SwatGUI) EditInline Config GUIButton                    RosterDeleteArchetypeButton;
var(SwatGUI) EditInline Config GUIComboBox                  ArchetypeSelectionBox;
var(SwatGUI) EditInline Config GUILabel                     ArchetypeSelectionBoxLabel;
var(SwatGUI) EditInline Config GUISlider                    RosterArchetypeChanceSlider;
var(SwatGUI) EditInline Config GUILabel                     RosterArchetypeChanceSliderLabel;
var(SwatGUI) EditInline Config GUILabel                     RosterSpawnerGroupLabel;
var(SwatGUI) EditInline Config GUIEditBox                   RosterSpawnerGroup;
var(SwatGUI) EditInline Config GUILabel                     RosterSpawnAnywhereCheckboxLabel;
var(SwatGUI) EditInline Config GUICheckBoxButton            RosterSpawnAnywhereCheckbox;
var(SwatGUI) EditInline Config GUILabel                     RosterMinimumSpinnerLabel;
var(SwatGUI) EditInline Config GUINumericEdit               RosterMinimumSpinner;
var(SwatGUI) EditInline Config GUILabel                     RosterMaximumSpinnerLabel;
var(SwatGUI) EditInline Config GUINumericEdit               RosterMaximumSpinner;
var(SwatGUI) EditInline Config GUICheckBoxButton            CustomArchetype_OverrideMorale;
var(SwatGUI) EditInline Config GUISlider                    CustomArchetype_OverriddenMoraleMin;
var(SwatGUI) EditInline Config GUISlider                    CustomArchetype_OverriddenMoraleMax;
var(SwatGUI) EditInline Config GUICheckBoxButton            CustomArchetype_OverrideVoiceType;
var(SwatGUI) EditInline Config GUIComboBox                  CustomArchetype_OverriddenVoiceType;
var(SwatGUI) EditInline Config GUICheckBoxButton            CustomArchetype_OverrideHelmet;
var(SwatGUI) EditInline Config GUIComboBox                  CustomArchetype_OverriddenHelmet;
var(SwatGUI) EditInline Config GUILabel                     CustomArchetype_OverrideMoraleLabel;
var(SwatGUI) EditInline Config GUILabel                     CustomArchetype_OverrideVoiceTypeLabel;
var(SwatGUI) EditInline Config GUILabel                     CustomArchetype_OverrideHelmetLabel;

var() private int SelectedRosterNum;
var() private int SelectedArchetypeNum;

var() private config localized string UsingCampaignSettingsMessage;
var() private config localized string NotUsingCampaignSettingsMessage;
var() private config localized string ModifiedHostageCountMinMessage;
var() private config localized string ModifiedHostageCountMaxMessage;
var() private config localized string ModifiedHostageMoraleMinMessage;
var() private config localized string ModifiedHostageMoraleMaxMessage;
var() private config localized string HostageArchetypeAddedMessage;
var() private config localized string HostageArchetypeRemovedMessage;

function InitComponent(GUIComponent MyOwner)
{
	local int i;
	local HostageArchetype Archetype;
	local class<Equipment> EquipmentClass;

	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;
    for(i = 0; i < Data.HostageArchetype.Length; i++)
    {
    	Archetype = new(None, string(Data.HostageArchetype[i].Archetype)) class'HostageArchetype';

    	ArchetypeSelectionBox.AddItem(Archetype.Description, , string(Data.HostageArchetype[i].Archetype));
    }

	chk_campaign.OnChange = chk_campaign_OnChange;
	chk_advanced.OnChange = chk_advanced_OnChange;

	dlist_archetypes.OnMoveAB = dlist_archetypes_OnMoveAB;
	dlist_archetypes.OnMoveBA = dlist_archetypes_OnMoveBA;

	spin_count_min.OnChange = spin_count_min_OnChange;
	spin_count_max.OnChange = spin_count_max_OnChange;
	slide_morale_min.OnChange = slide_morale_min_OnChange;
	slide_morale_max.OnChange = slide_morale_max_OnChange;

	// Advanced mode UI
	RosterMinimumSpinner.OnChange        = Roster_MinimumChanged;
    RosterMaximumSpinner.OnChange        = Roster_MaximumChanged;
    CreateRosterButton.OnClick           = Roster_AddNew;
	DeleteRosterButton.OnClick           = Roster_Delete;
	RosterList.OnChange                  = Roster_ChangedSelection;
	RosterSpawnAnywhereCheckbox.OnChange = Roster_SpawnAnywhereChanged;
	RosterArchetypeList.OnChange         = Roster_NewArchetypeSelection;
	RosterAddArchetypeButton.OnClick     = Roster_NewArchetypeAdded;
	RosterDeleteArchetypeButton.OnClick  = Roster_ArchetypeDeleted;
	ArchetypeSelectionBox.OnChange       = Roster_ArchetypeChanged;
	RosterArchetypeChanceSlider.OnChange = Roster_ArchetypeChanged;
	CustomArchetype_OverrideMorale.OnChange            = CustomArchetype_OverrideMoraleChanged;
	CustomArchetype_OverrideVoiceType.OnChange         = CustomArchetype_OverrideVoiceTypeChanged;
	CustomArchetype_OverrideHelmet.OnChange            = CustomArchetype_OverrideHelmetChanged;
	CustomArchetype_OverriddenMoraleMin.OnChange       = Roster_ArchetypeChanged;
	CustomArchetype_OverriddenMoraleMax.OnChange       = Roster_ArchetypeChanged;
	CustomArchetype_OverriddenVoiceType.OnChange       = Roster_ArchetypeChanged;
	CustomArchetype_OverriddenHelmet.OnChange          = Roster_ArchetypeChanged;
	CreateRosterName.SetText("");

	for(i = 0; i < Data.VoiceTypes.Length; i++)
    {
    	CustomArchetype_OverriddenVoiceType.AddItem(Data.VoiceTypes[i].FriendlyName,, string(Data.VoiceTypes[i].VoiceType));
    }

    for(i = 0; i < Data.Helmets.Length; i++)
    {
    	EquipmentClass = class<Equipment>(DynamicLoadObject(Data.Helmets[i], class'Class'));
    	CustomArchetype_OverriddenHelmet.AddItem(EquipmentClass.static.GetFriendlyName(),, Data.Helmets[i]);
    }

    chk_advanced_OnChange(chk_advanced);
}

function ServerPoll(CoopQMMReplicationInfo CoopQMMRI)
{
	local int i;

	CoopQMMRI.CampaignHostagesChecked = chk_campaign.bChecked;

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_HOSTAGES; ++i)
		CoopQMMRI.AvailableHostages[i] = "";

	for (i = 0; i < dlist_archetypes.ListBoxA.ItemCount(); ++i)
	{
		assert(i < class'CoopQMMReplicationInfo'.const.MAX_HOSTAGES);
		CoopQMMRI.AvailableHostages[i] = dlist_archetypes.ListBoxA.List.GetExtraAtIndex(i);
	}

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_HOSTAGES; ++i)
		CoopQMMRI.SelectedHostages[i] = "";

	for (i = 0; i < dlist_archetypes.ListBoxB.ItemCount(); ++i)
	{
		assert(i < class'CoopQMMReplicationInfo'.const.MAX_HOSTAGES);
		CoopQMMRI.SelectedHostages[i] = dlist_archetypes.ListBoxB.List.GetExtraAtIndex(i);
	}

	CoopQMMRI.HostageCountMin = spin_count_min.MinValue;
	CoopQMMRI.HostageCountMax = spin_count_max.MaxValue;
	CoopQMMRI.HostageCountMinValue = spin_count_min.Value;
	CoopQMMRI.HostageCountMaxValue = spin_count_max.Value;

	CoopQMMRI.HostageMoraleMin = slide_morale_min.Value;
	CoopQMMRI.HostageMoraleMax = slide_morale_max.Value;
}

function ClientPoll(CoopQMMReplicationInfo CoopQMMRI)
{
	local int i;

	chk_campaign.SetChecked(CoopQMMRI.CampaignHostagesChecked);

	dlist_archetypes.ListBoxA.List.Clear();
    dlist_archetypes.ListBoxB.List.Clear();

	dlist_archetypes.ListBoxA.List.DisplayItem = LIST_ELEM_Item;
	dlist_archetypes.ListBoxB.List.DisplayItem = LIST_ELEM_Item;

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_HOSTAGES; ++i)
	{
		if (CoopQMMRI.AvailableHostages[i] == "")
			break;

		dlist_archetypes.ListBoxA.List.Add(CoopQMMRI.AvailableHostages[i]);
	}

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_HOSTAGES; ++i)
	{
		if (CoopQMMRI.SelectedHostages[i] == "")
			break;

		dlist_archetypes.ListBoxB.List.Add(CoopQMMRI.SelectedHostages[i]);
	}

	spin_count_min.SetMinValue(CoopQMMRI.HostageCountMin);
	spin_count_min.SetMaxValue(CoopQMMRI.HostageCountMax);
	spin_count_min.SetValue(CoopQMMRI.HostageCountMinValue);
	spin_count_max.SetMinValue(CoopQMMRI.HostageCountMin);
	spin_count_max.SetMaxValue(CoopQMMRI.HostageCountMax);
	spin_count_max.SetValue(CoopQMMRI.HostageCountMaxValue);

	slide_morale_min.SetValue(CoopQMMRI.HostageMoraleMin);
	slide_morale_max.SetValue(CoopQMMRI.HostageMoraleMax);
}

event Activate()
{
    Super.Activate();

    SetPanelActive();
}

private function SetPanelActive()
{
    pnl_body.SetActive( !chk_campaign.bChecked );
    pnl_DisabledOverlay.SetVisibility( chk_campaign.bChecked );
    chk_advanced.SetEnabled(!chk_campaign.bChecked);
}

function chk_campaign_OnChange(GUIComponent Sender)
{
    SetPanelActive();

	if (CustomScenarioPage.IsClient())
		return;

	if (chk_campaign.bChecked)
		CustomScenarioPage.SendChangeMessage(UsingCampaignSettingsMessage);
	else
		CustomScenarioPage.SendChangeMessage(NotUsingCampaignSettingsMessage);
}

function chk_advanced_OnChange(GUIComponent Sender)
{
	local CustomScenario Scenario;

	// Checked: We hide all of the basic options and present the advanced ones.
	pnl_body.SetVisibility(!chk_advanced.bChecked);
	pnl_DisabledOverlay.SetVisibility(!chk_advanced.bChecked);
	dlist_archetypes.SetVisibility(!chk_advanced.bChecked);

	lbl_count.SetVisibility(!chk_advanced.bChecked);
	spin_count_min.SetVisibility(!chk_advanced.bChecked);
	lbl_count_min.SetVisibility(!chk_advanced.bChecked);
	lbl_count_max.SetVisibility(!chk_advanced.bChecked);
	spin_count_max.SetVisibility(!chk_advanced.bChecked);
	lbl_morale.SetVisibility(!chk_advanced.bChecked);
	slide_morale_min.SetVisibility(!chk_advanced.bChecked);
	lbl_morale_min.SetVisibility(!chk_advanced.bChecked);
	lbl_morale_max.SetVisibility(!chk_advanced.bChecked);
	slide_morale_max.SetVisibility(!chk_advanced.bChecked);

	// Advanced settings
	RosterListLabel.SetVisibility(chk_advanced.bChecked);
	RosterList.SetVisibility(chk_advanced.bChecked);
	CreateRosterName.SetVisibility(chk_advanced.bChecked);
	CreateRosterButton.SetVisibility(chk_advanced.bChecked);
	DeleteRosterButton.SetVisibility(chk_advanced.bChecked);
	EditRosterLabel.SetVisibility(chk_advanced.bChecked);
	RosterArchetypeList.SetVisibility(chk_advanced.bChecked);
	ArchetypeListLabel.SetVisibility(chk_advanced.bChecked);
	RosterNewArchetypeSelection.SetVisibility(chk_advanced.bChecked);
	RosterAddArchetypeButton.SetVisibility(chk_advanced.bChecked);
	RosterDeleteArchetypeButton.SetVisibility(chk_advanced.bChecked);
	ArchetypeSelectionBox.SetVisibility(chk_advanced.bChecked);
	ArchetypeSelectionBoxLabel.SetVisibility(chk_advanced.bChecked);
	RosterArchetypeChanceSlider.SetVisibility(chk_advanced.bChecked);
	RosterArchetypeChanceSliderLabel.SetVisibility(chk_advanced.bChecked);
	RosterSpawnerGroupLabel.SetVisibility(chk_advanced.bChecked);
	RosterSpawnerGroup.SetVisibility(chk_advanced.bChecked);
	RosterSpawnAnywhereCheckboxLabel.SetVisibility(chk_advanced.bChecked);
	RosterSpawnAnywhereCheckbox.SetVisibility(chk_advanced.bChecked);
	RosterMinimumSpinnerLabel.SetVisibility(chk_advanced.bChecked);
	RosterMinimumSpinner.SetVisibility(chk_advanced.bChecked);
	RosterMaximumSpinnerLabel.SetVisibility(chk_advanced.bChecked);
	RosterMaximumSpinner.SetVisibility(chk_advanced.bChecked);

	CustomArchetype_OverrideMorale.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverriddenMoraleMin.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverriddenMoraleMax.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideVoiceType.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverriddenVoiceType.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideHelmet.SetVisibility(/*chk_advanced.bChecked*/ false);
	CustomArchetype_OverriddenHelmet.SetVisibility(/*chk_advanced.bChecked*/ false);
	CustomArchetype_OverrideMoraleLabel.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideVoiceTypeLabel.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideHelmetLabel.SetVisibility(/*chk_advanced.bChecked*/ false);


	pnl_DisabledOverlay.SetVisibility( chk_campaign.bChecked );

	Scenario = CustomScenarioPage.GetCustomScenario();
	Scenario.UseAdvancedHostageRosters = chk_advanced.bChecked;
}

function spin_count_min_OnChange(GUIComponent Sender)
{
    if (spin_count_max.Value < spin_count_min.Value)
        spin_count_max.SetValue(spin_count_min.Value);

	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(ModifiedHostageCountMinMessage @ spin_count_min.MyEditBox.GetText());
}

function spin_count_max_OnChange(GUIComponent Sender)
{
    if (spin_count_min.Value > spin_count_max.Value)
        spin_count_min.SetValue(spin_count_max.Value);

	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(ModifiedHostageCountMaxMessage @ spin_count_max.MyEditBox.GetText());
}

function slide_morale_min_OnChange(GUIComponent Sender)
{
    if( slide_morale_max.Value < slide_morale_min.Value )
        slide_morale_max.SetValue(slide_morale_min.Value);

	if (CustomScenarioPage.IsClient() || slide_morale_max.MenuState == MSAT_Pressed)
		return;

	if (slide_morale_min.MenuState != MSAT_Pressed)
		CustomScenarioPage.SendChangeMessage(ModifiedHostageMoraleMinMessage @ slide_morale_min.Value);
}

function slide_morale_max_OnChange(GUIComponent Sender)
{
    if( slide_morale_min.Value > slide_morale_max.Value )
        slide_morale_min.SetValue(slide_morale_max.Value);

	if (CustomScenarioPage.IsClient() || slide_morale_min.MenuState == MSAT_Pressed)
		return;

	if (slide_morale_max.MenuState != MSAT_Pressed)
		CustomScenarioPage.SendChangeMessage(ModifiedHostageMoraleMaxMessage @ slide_morale_max.Value);
}

function dlist_archetypes_OnMoveAB(GUIComponent Sender, GUIListElem Element)
{
	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(HostageArchetypeAddedMessage @ Element.ExtraStrData);
}

function dlist_archetypes_OnMoveBA(GUIComponent Sender, GUIListElem Element)
{
	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(HostageArchetypeRemovedMessage @ Element.ExtraStrData);
}

function Roster_AddNew(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster NewRoster;
	local int i;
	local string NewName;

	if(CreateRosterName.GetText() == "")
	{
		return;
	}

	Scenario = CustomScenarioPage.GetCustomScenario();
	NewName = CreateRosterName.GetText();

	// If there's already a roster with this name, don't add it
	for(i = 0; i < Scenario.AdvancedHostageRosters.Length; i++)
	{
		if(Scenario.AdvancedHostageRosters[i].DisplayName == NewName)
		{
			return;
		}
	}
	
	NewRoster.DisplayName = NewName;
	NewRoster.Minimum = 1;
	NewRoster.Maximum = 3;
	RosterMinimumSpinner.SetValue(1);
	RosterMaximumSpinner.SetValue(3);
	NewRoster.SpawnAnywhere = true;
	RosterSpawnAnywhereCheckbox.bChecked = true;
	Scenario.AdvancedHostageRosters[Scenario.AdvancedHostageRosters.Length] = NewRoster;

	RosterList.List.Add(NewRoster.DisplayName);
	RosterList.SetEnabled(true);
	CreateRosterName.SetText("");
}

function Roster_Delete(GUIComponent Sender)
{
	local CustomScenario Scenario;

	Scenario = CustomScenarioPage.GetCustomScenario();
	Scenario.AdvancedHostageRosters.Remove(RosterList.List.Index, 1);
	RosterList.List.Remove(RosterList.List.Index);
	if(RosterList.List.ItemCount == 0)
	{
		OnAdvancedRosterListEmptied();
	}
}

function Roster_ChangedSelection(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local int i;
	local CustomScenario.QMMRoster NewRoster;

	DeleteRosterButton.EnableComponent();
	RosterAddArchetypeButton.EnableComponent();
	RosterDeleteArchetypeButton.EnableComponent();
	RosterMinimumSpinner.EnableComponent();
	RosterMaximumSpinner.EnableComponent();

	Scenario = CustomScenarioPage.GetCustomScenario();
	NewRoster = Scenario.AdvancedHostageRosters[RosterList.List.Index];

	RosterSpawnAnywhereCheckbox.EnableComponent();
	RosterSpawnAnywhereCheckbox.SetChecked(NewRoster.SpawnAnywhere);
	RosterSpawnerGroup.SetEnabled(!NewRoster.SpawnAnywhere);
	RosterSpawnerGroup.SetText(NewRoster.SpawnGroup);

	// Populate list of archetypes with roster info
	RosterArchetypeList.List.Clear();
	for(i = 0; i < NewRoster.Archetypes.Length; i++)
	{
		RosterArchetypeList.List.Add(string(NewRoster.Archetypes[i].BaseArchetype));
	}

	if(RosterArchetypeList.List.ItemCount > 0)
	{
		for(i = 0; i < ArchetypeSelectionBox.List.ItemCount; i++)
		{
			if(ArchetypeSelectionBox.List.GetExtraAt(i) == string(NewRoster.Archetypes[RosterArchetypeList.List.Index].BaseArchetype))
			{
				ArchetypeSelectionBox.SetIndex(i);
				break;
			}
		}
	}
	

	// Delete button is disabled if no archetypes are present
	RosterDeleteArchetypeButton.SetEnabled(NewRoster.Archetypes.Length != 0);

	RosterMinimumSpinner.SetValue(NewRoster.Minimum);
	RosterMaximumSpinner.SetValue(NewRoster.Maximum);
}

function Roster_NewArchetypeSelection(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster CurrentRoster;
	local int i;
	
	ArchetypeSelectionBox.EnableComponent();
	RosterArchetypeChanceSlider.EnableComponent();

	// Set archetype selection box to be the archetype that was selected
	Scenario = CustomScenarioPage.GetCustomScenario();
	CurrentRoster = Scenario.AdvancedHostageRosters[RosterList.List.Index];
	RosterArchetypeChanceSlider.SetValue(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].Chance);

	for(i = 0; i < ArchetypeSelectionBox.List.ItemCount; i++)
	{
		if(ArchetypeSelectionBox.List.GetExtraAtIndex(i) == string(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].BaseArchetype))
		{
			ArchetypeSelectionBox.SetIndex(i);
			break;
		}
	}

	CustomArchetype_OverrideMorale.SetChecked(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].bOverrideMorale);
	CustomArchetype_OverriddenMoraleMin.SetValue(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].OverrideMinMorale);
	CustomArchetype_OverriddenMoraleMax.SetValue(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].OverrideMaxMorale);
	CustomArchetype_OverrideVoiceType.SetChecked(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].bOverrideVoiceType);
	for(i = 0; i < CustomArchetype_OverriddenVoiceType.List.ItemCount; i++)
	{
		if(CustomArchetype_OverriddenVoiceType.List.GetExtraAt(i) == string(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].OverrideVoiceType))
		{
			CustomArchetype_OverriddenVoiceType.SetIndex(i);
			break;
		}
	}
	CustomArchetype_OverrideHelmet.SetChecked(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].bOverrideHelmet);

	for(i = 0; i < CustomArchetype_OverriddenHelmet.List.ItemCount; i++)
	{
		if(CustomArchetype_OverriddenHelmet.List.GetExtraAt(i) == CurrentRoster.Archetypes[RosterArchetypeList.List.Index].OverrideHelmet)
		{
			CustomArchetype_OverriddenHelmet.SetIndex(i);
			break;
		}
	}
}

function Roster_NewArchetypeAdded(GUIComponent Sender)
{
	// Just add a new archetype to the list, nothing fancy
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster CurrentRoster;
	local CustomScenario.ArchetypeData ArchetypeData;

	ArchetypeSelectionBox.EnableComponent();
	RosterArchetypeChanceSlider.EnableComponent();
	RosterDeleteArchetypeButton.EnableComponent();

	Scenario = CustomScenarioPage.GetCustomScenario();
	CurrentRoster = Scenario.AdvancedHostageRosters[RosterList.List.Index];
	ArchetypeData.Chance = 0.5;
	ArchetypeData.bOverrideVoiceType = false;
	ArchetypeData.bOverrideMorale = false;
	ArchetypeData.bOverrideHelmet = false;
	ArchetypeData.BaseArchetype = name(ArchetypeSelectionBox.List.GetExtraAtIndex(0));

	RosterArchetypeChanceSlider.SetValue(0.5);
	ArchetypeSelectionBox.SetIndex(0);

	CurrentRoster.Archetypes[CurrentRoster.Archetypes.Length] = ArchetypeData;
	RosterArchetypeList.List.Add("("$ArchetypeSelectionBox.List.Get()$", Chance="$ArchetypeData.Chance$")");

	//Scenario.AdvancedEnemyRosters[Scenario.AdvancedEnemyRosters.Length] = CurrentRoster;
}

function Roster_ArchetypeDeleted(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster CurrentRoster;

	Scenario = CustomScenarioPage.GetCustomScenario();
	CurrentRoster = Scenario.AdvancedHostageRosters[RosterList.List.Index];

	CurrentRoster.Archetypes.Remove(RosterArchetypeList.List.Index, 1);
	RosterArchetypeList.List.Remove(RosterArchetypeList.List.Index);

	if(CurrentRoster.Archetypes.Length == 0)
	{
		RosterDeleteArchetypeButton.DisableComponent();
		ArchetypeSelectionBox.DisableComponent();
		RosterArchetypeChanceSlider.DisableComponent();
	}

	Scenario.AdvancedHostageRosters[RosterList.List.Index] = CurrentRoster;
}

function Roster_ArchetypeChanged(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster CurrentRoster;
	local CustomScenario.ArchetypeData ArchetypeData;
	local string ChanceAsString;

	Scenario = CustomScenarioPage.GetCustomScenario();
	CurrentRoster = Scenario.AdvancedHostageRosters[RosterList.List.Index];
	ArchetypeData = CurrentRoster.Archetypes[RosterArchetypeList.List.Index];
	ArchetypeData.BaseArchetype = name(ArchetypeSelectionBox.List.GetExtra());
	ArchetypeData.Chance = RosterArchetypeChanceSlider.GetValue();
	ArchetypeData.bOverrideVoiceType = CustomArchetype_OverrideVoiceType.bChecked;
	ArchetypeData.OverrideVoiceType = name(CustomArchetype_OverriddenVoiceType.List.GetExtra());
	ArchetypeData.bOverrideMorale = CustomArchetype_OverrideMorale.bChecked;
	ArchetypeData.OverrideMinMorale = CustomArchetype_OverriddenMoraleMin.GetValue();
	ArchetypeData.OverrideMaxMorale = CustomArchetype_OverriddenMoraleMax.GetValue();
	ArchetypeData.bOverrideHelmet = CustomArchetype_OverrideHelmet.bChecked;
	//ArchetypeData.OverrideHelmet
	ChanceAsString = ""$ArchetypeData.Chance$"";
	RosterArchetypeList.List.SetItemAtIndex(RosterArchetypeList.List.Index, "("$ArchetypeSelectionBox.List.Get()$", Chance="$ChanceAsString$")");

	if(RosterArchetypeList.List.Index >= 0 && RosterList.List.Index >= 0)
	{	// These can sometimes be negative = mega crash!!
		CurrentRoster.Archetypes[RosterArchetypeList.List.Index] = ArchetypeData;
		Scenario.AdvancedHostageRosters[RosterList.List.Index] = CurrentRoster;
	}
	
}

function Roster_MinimumChanged(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster Roster;

	if(RosterMinimumSpinner.Value > RosterMaximumSpinner.Value)
	{
		RosterMaximumSpinner.SetValue(RosterMinimumSpinner.Value);
	}

	Scenario = CustomScenarioPage.GetCustomScenario();
	Roster = Scenario.AdvancedHostageRosters[RosterList.List.Index];

	Roster.Minimum = RosterMinimumSpinner.Value;
	Roster.Maximum = RosterMaximumSpinner.Value;

	Scenario.AdvancedHostageRosters[RosterList.List.Index] = Roster;
}

function Roster_MaximumChanged(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster Roster;

	if(RosterMinimumSpinner.Value > RosterMaximumSpinner.Value)
	{
		RosterMinimumSpinner.SetValue(RosterMaximumSpinner.Value);
	}

	Scenario = CustomScenarioPage.GetCustomScenario();
	Roster = Scenario.AdvancedHostageRosters[RosterList.List.Index];

	Roster.Maximum = RosterMaximumSpinner.Value;
	Roster.Minimum = RosterMinimumSpinner.Value;

	Scenario.AdvancedHostageRosters[RosterList.List.Index] = Roster;
}

function Roster_SpawnAnywhereChanged(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster Roster;

	RosterSpawnerGroup.SetEnabled(!RosterSpawnAnywhereCheckbox.bChecked);

	Scenario = CustomScenarioPage.GetCustomScenario();
	Roster = Scenario.AdvancedHostageRosters[RosterList.List.Index];

	Roster.SpawnAnywhere = RosterSpawnAnywhereCheckbox.bChecked;
	Scenario.AdvancedHostageRosters[RosterList.List.Index] = Roster;
}

function CustomArchetype_OverrideMoraleChanged(GUIComponent Sender)
{
	CustomArchetype_OverriddenMoraleMin.SetEnabled(CustomArchetype_OverrideMorale.bChecked);
	CustomArchetype_OverriddenMoraleMax.SetEnabled(CustomArchetype_OverrideMorale.bChecked);
}

function CustomArchetype_OverrideVoiceTypeChanged(GUIComponent Sender)
{
	CustomArchetype_OverriddenVoiceType.SetEnabled(CustomArchetype_OverrideVoiceType.bChecked);
}

function CustomArchetype_OverrideHelmetChanged(GUIComponent Sender)
{
	CustomArchetype_OverriddenHelmet.SetEnabled(CustomArchetype_OverrideHelmet.bChecked);
}

function InternalOnActivate()
{
	if(CustomScenarioPage.UsingCustomMap)
	{
		chk_campaign.SetChecked(false);
		chk_campaign.DisableComponent();
	}
	else
	{
		chk_campaign.EnableComponent();
	}

	chk_advanced_OnChange(chk_advanced);
}

function OnAdvancedRosterListEmptied()
{
	DeleteRosterButton.DisableComponent();
    RosterAddArchetypeButton.DisableComponent();
    RosterDeleteArchetypeButton.DisableComponent();
    RosterList.DisableComponent();
    RosterSpawnAnywhereCheckbox.DisableComponent();
    RosterSpawnerGroup.DisableComponent();
    RosterMinimumSpinner.DisableComponent();
    RosterMaximumSpinner.DisableComponent();
}

// CustomScenarioTabPanel overrides

function PopulateFieldsFromScenario(bool NewScenario)
{
    local CustomScenario Scenario;
    local HostageArchetype Archetype;
    local CustomScenario.ArchetypeData ArchetypeData;
    local int i,j;

    RosterList.List.Clear();

    Scenario = CustomScenarioPage.GetCustomScenario();

	if(Scenario.IsCustomMap)
	{
		chk_campaign.SetChecked(false);
		chk_campaign.DisableComponent();
	}
    else
	{
		chk_campaign.SetChecked(Scenario.UseCampaignHostageSettings, true);
		chk_campaign.EnableComponent();
	}

    spin_count_min.SetValue(Scenario.HostageCountRangeCow.Min, true);
    spin_count_max.SetValue(Scenario.HostageCountRangeCow.Max, true);

    slide_morale_min.SetValue(Scenario.HostageMorale.Min);
    slide_morale_max.SetValue(Scenario.HostageMorale.Max);

    dlist_archetypes.ListBoxA.Clear();
    dlist_archetypes.ListBoxB.Clear();

    chk_advanced.bChecked = Scenario.UseAdvancedHostageRosters;

    CreateRosterButton.EnableComponent();
    if(NewScenario || Scenario.AdvancedHostageRosters.Length == 0)
    {
    	OnAdvancedRosterListEmptied();
    }
    else
    {
    	// Add entries to the roster
    	DeleteRosterButton.EnableComponent();

    	for(i = 0; i < Scenario.AdvancedHostageRosters.Length; i++)
    	{
    		RosterList.List.Add(Scenario.AdvancedHostageRosters[i].DisplayName);
    	}
    }

    //fill archetypes
    for (i=0; i<Data.HostageArchetype.length; ++i)
    {
        Archetype = new(None, string(Data.HostageArchetype[i].Archetype)) class'HostageArchetype';
        //NOTE! We're not calling Archetype.Initialize() because we won't actually use this Archetype
        //  for anything except reading its config data.

        if (NewScenario)
        {
            //when populating a new scenario,
            //  add an archetype to the "Selected" list iff it is ByDefault

            if (Data.HostageArchetype[i].ByDefault)
                //add to List A: Selected Archetypes
                dlist_archetypes.ListBoxB.List.Add(
                        string(Data.HostageArchetype[i].Archetype),
                        ,
                        Archetype.Description);
            else
                //add to List B: Available Archetypes
                dlist_archetypes.ListBoxA.List.Add(
                        string(Data.HostageArchetype[i].Archetype),
                        ,
                        Archetype.Description);
        }
        else    //!NewScenario
        {
            //when populating an existing scenario,
            //  add an archetype to the "Selected" list iff it is selected in the Scenario

            for (j=0; j<Scenario.HostageArchetypes.length; ++j)
            {
                if (Scenario.HostageArchetypes[j] == Data.HostageArchetype[i].Archetype)
                {
                    //add to List A: Selected Archetypes
                    dlist_archetypes.ListBoxB.List.Add(
                            string(Data.HostageArchetype[i].Archetype),
                            ,
                            Archetype.Description);
                    break;
                }
            }
            if (j == Scenario.HostageArchetypes.length)  //the Archetype was not found in the Scenario
                //add to List B: Available Archetypes
                dlist_archetypes.ListBoxA.List.Add(
                        string(Data.HostageArchetype[i].Archetype),
                        ,
                        Archetype.Description);
        }
    }

    dlist_archetypes.ListBoxA.SetIndex(0);
    dlist_archetypes.ListBoxB.SetIndex(0);

    //TMC TODO Set count_min/max captions from mission specific spawning data (iff Scenario.UseCampaignObjectives)
}

function GatherScenarioFromFields()
{
    local CustomScenario Scenario;
    local int i;

    Scenario = CustomScenarioPage.GetCustomScenario();

	if(Scenario.IsCustomMap)
	{
		Scenario.UseCampaignHostageSettings = false;
	}
    else
	{
		Scenario.UseCampaignHostageSettings = chk_campaign.bChecked;
	}

    Scenario.HostageCountRangeCow.Min = spin_count_min.Value;
    Scenario.HostageCountRangeCow.Max = spin_count_max.Value;

    Scenario.HostageMorale.Min = slide_morale_min.Value;
    Scenario.HostageMorale.Max = slide_morale_max.Value;

    //add archetypes
    Scenario.HostageArchetypes.Remove(0, Scenario.HostageArchetypes.length);
    for (i=0; i<dlist_archetypes.ListBoxB.List.Elements.length; ++i)
        Scenario.HostageArchetypes[Scenario.HostageArchetypes.length] = name(dlist_archetypes.ListBoxB.List.GetItemAtIndex(i));
}

defaultproperties
{
	OnActivate=InternalOnActivate
	UsingCampaignSettingsMessage="Using campaign settings"
	NotUsingCampaignSettingsMessage="Not using campaign settings"
	ModifiedHostageCountMinMessage="Minimum hostage count modified:"
	ModifiedHostageCountMaxMessage="Maximum hostage count modified:"
	ModifiedHostageMoraleMinMessage="Minimum hostage morale modified:"
	ModifiedHostageMoraleMaxMessage="Maximum hostage morale modified:"
	HostageArchetypeAddedMessage="Hostage archetype added:"
	HostageArchetypeRemovedMessage="Hostage archetype removed:"
}
