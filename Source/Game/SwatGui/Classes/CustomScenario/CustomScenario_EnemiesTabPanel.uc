class CustomScenario_EnemiesTabPanel extends CustomScenarioTabPanel;

var(SWATGui) EditInline Config GUICheckBoxButton            chk_campaign;
var(SWATGui) EditInline Config GUICheckBoxButton            chk_advanced;
var(SWATGui) EditInline Config GUIPanel                     pnl_body;
var(SWATGui) EditInline Config GUIImage                     pnl_DisabledOverlay;
var(SWATGui) EditInline Config GUIDualSelectionLists        dlist_archetypes;

var(SWATGui) EditInline Config GUIComboBox                  cbo_primary_type;
var(SWATGui) EditInline Config GUIComboBox                  cbo_primary_specific;
var(SWATGui) EditInline Config GUIComboBox                  cbo_backup_type;
var(SWATGui) EditInline Config GUIComboBox                  cbo_backup_specific;

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
var(SwatGUI) EditInline Config GUIComboBox                  cbo_skill;
var(SwatGUI) EditInline Config GUILabel                     lbl_skill;

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
var(SwatGUI) EditInline Config GUICheckBoxButton            CustomArchetype_OverridePrimaryWeapon;
var(SwatGUI) EditInline Config GUICheckBoxButton            CustomArchetype_OverrideBackupWeapon;
var(SwatGUI) EditInline Config GUICheckBoxButton            CustomArchetype_OverrideHelmet;
var(SwatGUI) EditInline Config GUIComboBox                  CustomArchetype_OverriddenPrimaryWeapon;
var(SwatGUI) EditInline Config GUIComboBox                  CustomArchetype_OverriddenBackupWeapon;
var(SwatGUI) EditInline Config GUIComboBox                  CustomArchetype_OverriddenHelmet;
var(SwatGUI) EditInline Config GUILabel                     CustomArchetype_OverrideMoraleLabel;
var(SwatGUI) EditInline Config GUILabel                     CustomArchetype_OverrideVoiceTypeLabel;
var(SwatGUI) EditInline Config GUILabel                     CustomArchetype_OverridePrimaryWeaponLabel;
var(SwatGUI) EditInline Config GUILabel                     CustomArchetype_OverrideBackupWeaponLabel;
var(SwatGUI) EditInline Config GUILabel                     CustomArchetype_OverrideHelmetLabel;

var() private int SelectedRosterNum;
var() private int SelectedArchetypeNum;

var() private config localized string UsingCampaignSettingsMessage;
var() private config localized string NotUsingCampaignSettingsMessage;
var() private config localized string ModifiedEnemyCountMinMessage;
var() private config localized string ModifiedEnemyCountMaxMessage;
var() private config localized string ModifiedEnemyMoraleMinMessage;
var() private config localized string ModifiedEnemyMoraleMaxMessage;
var() private config localized string EnemyArchetypeAddedMessage;
var() private config localized string EnemyArchetypeRemovedMessage;
var() private config localized string EnemySkillChangedMessage;
var() private config localized string EnemyPrimaryWeaponTypeChangedMessage;
var() private config localized string EnemyBackupWeaponTypeChangedMessage;
var() private config localized string EnemyPrimaryWeaponSpecificChangedMessage;
var() private config localized string EnemyBackupWeaponSpecificChangedMessage;

function InitComponent(GUIComponent MyOwner)
{
    local int i;
    local EnemyArchetype Archetype;
    local class<FiredWeapon> WeaponClass;
    local class<Equipment> EquipmentClass;

	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;

    ArchetypeSelectionBox.Clear();
    for(i = 0; i < Data.EnemyArchetype.Length; i++)
    {
    	Archetype = new(None, string(Data.EnemyArchetype[i].Archetype)) class'EnemyArchetype';

    	ArchetypeSelectionBox.AddItem(Archetype.Description, , string(Data.EnemyArchetype[i].Archetype));
    }

    chk_campaign.OnChange                = chk_campaign_OnChange;
    chk_advanced.OnChange                = chk_advanced_OnChange;

	dlist_archetypes.OnMoveAB			 = dlist_archetypes_OnMoveAB;
	dlist_archetypes.OnMoveBA			 = dlist_archetypes_OnMoveBA;

    cbo_primary_type.OnChange            = cbo_primary_type_OnChange;
    cbo_backup_type.OnChange             = cbo_backup_type_OnChange;

    spin_count_min.OnChange              = spin_count_min_OnChange;
    spin_count_max.OnChange              = spin_count_max_OnChange;
    slide_morale_min.OnChange            = slide_morale_min_OnChange;
    slide_morale_max.OnChange            = slide_morale_max_OnChange;
    RosterMinimumSpinner.OnChange        = Roster_MinimumChanged;
    RosterMaximumSpinner.OnChange        = Roster_MaximumChanged;

	cbo_skill.OnChange					 = cbo_skill_OnChange;

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
	CustomArchetype_OverridePrimaryWeapon.OnChange     = CustomArchetype_OverridePrimaryWeaponChanged;
	CustomArchetype_OverrideBackupWeapon.OnChange      = CustomArchetype_OverrideBackupWeaponChanged;
	CustomArchetype_OverrideHelmet.OnChange            = CustomArchetype_OverrideHelmetChanged;
	CustomArchetype_OverriddenMoraleMin.OnChange       = Roster_ArchetypeChanged;
	CustomArchetype_OverriddenMoraleMax.OnChange       = Roster_ArchetypeChanged;
	CustomArchetype_OverriddenVoiceType.OnChange       = Roster_ArchetypeChanged;
	CustomArchetype_OverriddenPrimaryWeapon.OnChange   = Roster_ArchetypeChanged;
	CustomArchetype_OverriddenBackupWeapon.OnChange    = Roster_ArchetypeChanged;
	CustomArchetype_OverriddenHelmet.OnChange          = Roster_ArchetypeChanged;
	CreateRosterName.SetText("");

    //fill skills
    cbo_skill.AddItem("Any",, Data.AnyString);
    cbo_skill.AddItem("Low",, Data.LowString);
    cbo_skill.AddItem("Medium",, Data.MediumString);
    cbo_skill.AddItem("High",, Data.HighString);

    //fill weapon types
    cbo_primary_type.AddItem("Any",, Data.AnyString);  //the localized word "Any"
    cbo_Backup_type.AddItem("Any",, Data.AnyString);   //the localized word "Any"
    cbo_primary_type.AddItem("None",, Data.NoneString);  //the localized word "None"
    cbo_Backup_type.AddItem("None",, Data.NoneString);   //the localized word "None"
    for (i=0; i<Data.PrimaryWeaponCategory.length; ++i)
        cbo_primary_type.AddItem(
                string(Data.PrimaryWeaponCategory[i]),
                ,
                Data.PrimaryWeaponCategoryDescription[i]);
    for (i=0; i<Data.BackupWeaponCategory.length; ++i)
        cbo_backup_type.AddItem(
                string(Data.BackupWeaponCategory[i]),
                ,
                Data.BackupWeaponCategoryDescription[i]);

    // Iterate through all of the categories for primary and backup weapons, and add those to the overridden backup and primary weapon comboboxes
    CustomArchetype_OverriddenPrimaryWeapon.Clear();
    CustomArchetype_OverriddenBackupWeapon.Clear();
    for(i = 0; i < Data.PrimaryWeapon.Length; i++)
    {
    	WeaponClass = class<FiredWeapon>(DynamicLoadObject(Data.PrimaryWeapon[i].Weapon, class'Class'));
    	CustomArchetype_OverriddenPrimaryWeapon.AddItem(WeaponClass.default.FriendlyName,, Data.PrimaryWeapon[i].Weapon);
    }

    for(i = 0; i < Data.BackupWeapon.Length; i++)
    {
    	WeaponClass = class<FiredWeapon>(DynamicLoadObject(Data.BackupWeapon[i].Weapon, class'Class'));
    	CustomArchetype_OverriddenBackupWeapon.AddItem(WeaponClass.default.FriendlyName,, Data.BackupWeapon[i].Weapon);
    }

    for(i = 0; i < Data.VoiceTypes.Length; i++)
    {
    	CustomArchetype_OverriddenVoiceType.AddItem(Data.VoiceTypes[i].FriendlyName,, string(Data.VoiceTypes[i].VoiceType));
    }

    for(i = 0; i < Data.Helmets.Length; i++)
    {
    	EquipmentClass = class<Equipment>(DynamicLoadObject(Data.Helmets[i], class'Class'));
    	CustomArchetype_OverriddenHelmet.AddItem(EquipmentClass.static.GetFriendlyName(),, Data.Helmets[i]);
    }

    CustomArchetype_OverriddenPrimaryWeapon.AddItem(Data.AnyString,, "Any");
    CustomArchetype_OverriddenPrimaryWeapon.AddItem(Data.NoneString,, "None");
    CustomArchetype_OverriddenBackupWeapon.AddItem(Data.AnyString,, "Any");
    CustomArchetype_OverriddenBackupWeapon.AddItem(Data.NoneString,, "None");

	cbo_primary_specific.OnChange           = cbo_primary_specific_OnChange;
	cbo_backup_specific.OnChange            = cbo_Backup_specific_OnChange;

    //specifics are disabled until type changes
    cbo_primary_specific.AddItem("Any",, Data.AnyString);
    cbo_primary_specific.SetEnabled(false);
    cbo_backup_specific.AddItem("Any",, Data.AnyString);
    cbo_backup_specific.SetEnabled(false);

    chk_advanced_OnChange(chk_advanced);
}

function ServerPoll(CoopQMMReplicationInfo CoopQMMRI)
{
	local int i;

	CoopQMMRI.CampaignEnemiesChecked = chk_campaign.bChecked;

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_ENEMIES; ++i)
		CoopQMMRI.AvailableEnemies[i] = "";

	for (i = 0; i < dlist_archetypes.ListBoxA.ItemCount(); ++i)
	{
		assert(i < class'CoopQMMReplicationInfo'.const.MAX_ENEMIES);
		CoopQMMRI.AvailableEnemies[i] = dlist_archetypes.ListBoxA.List.GetExtraAtIndex(i);
	}

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_ENEMIES; ++i)
		CoopQMMRI.SelectedEnemies[i] = "";

	for (i = 0; i < dlist_archetypes.ListBoxB.ItemCount(); ++i)
	{
		assert(i < class'CoopQMMReplicationInfo'.const.MAX_ENEMIES);
		CoopQMMRI.SelectedEnemies[i] = dlist_archetypes.ListBoxB.List.GetExtraAtIndex(i);
	}

	CoopQMMRI.EnemyCountMin = spin_count_min.MinValue;
	CoopQMMRI.EnemyCountMax = spin_count_max.MaxValue;
	CoopQMMRI.EnemyCountMinValue = spin_count_min.Value;
	CoopQMMRI.EnemyCountMaxValue = spin_count_max.Value;

	CoopQMMRI.EnemySkill = cbo_skill.GetText();

	CoopQMMRI.EnemyMoraleMin = slide_morale_min.Value;
	CoopQMMRI.EnemyMoraleMax = slide_morale_max.Value;

	CoopQMMRI.PrimaryWeaponType = cbo_primary_type.GetText();
	CoopQMMRI.PrimaryWeaponSpecific = cbo_primary_specific.GetText();
	CoopQMMRI.SecondaryWeaponType = cbo_backup_type.GetText();
	CoopQMMRI.SecondaryWeaponSpecific = cbo_backup_specific.GetText();

	CoopQMMRI.PrimaryWeaponSpecificEnabled = (cbo_primary_specific.MenuState != MSAT_Disabled);
	CoopQMMRI.SecondaryWeaponSpecificEnabled = (cbo_backup_specific.MenuState != MSAT_Disabled);
}

function ClientPoll(CoopQMMReplicationInfo CoopQMMRI)
{
	local int i;

	chk_campaign.SetChecked(CoopQMMRI.CampaignEnemiesChecked);

	dlist_archetypes.ListBoxA.List.Clear();
    dlist_archetypes.ListBoxB.List.Clear();

	dlist_archetypes.ListBoxA.List.DisplayItem = LIST_ELEM_Item;
	dlist_archetypes.ListBoxB.List.DisplayItem = LIST_ELEM_Item;

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_ENEMIES; ++i)
	{
		if (CoopQMMRI.AvailableEnemies[i] == "")
			break;

		dlist_archetypes.ListBoxA.List.Add(CoopQMMRI.AvailableEnemies[i]);
	}

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_ENEMIES; ++i)
	{
		if (CoopQMMRI.SelectedEnemies[i] == "")
			break;

		dlist_archetypes.ListBoxB.List.Add(CoopQMMRI.SelectedEnemies[i]);
	}

	spin_count_min.SetMinValue(CoopQMMRI.EnemyCountMin);
	spin_count_min.SetMaxValue(CoopQMMRI.EnemyCountMax);
	spin_count_min.SetValue(CoopQMMRI.EnemyCountMinValue);
	spin_count_max.SetMinValue(CoopQMMRI.EnemyCountMin);
	spin_count_max.SetMaxValue(CoopQMMRI.EnemyCountMax);
	spin_count_max.SetValue(CoopQMMRI.EnemyCountMaxValue);

	cbo_skill.SetText(CoopQMMRI.EnemySkill);

	slide_morale_min.SetValue(CoopQMMRI.EnemyMoraleMin);
	slide_morale_max.SetValue(CoopQMMRI.EnemyMoraleMax);

	cbo_primary_type.SetText(CoopQMMRI.PrimaryWeaponType);
	cbo_primary_specific.SetText(CoopQMMRI.PrimaryWeaponSpecific);
	cbo_backup_type.SetText(CoopQMMRI.SecondaryWeaponType);
	cbo_backup_specific.SetText(CoopQMMRI.SecondaryWeaponSpecific);

	if (CoopQMMRI.PrimaryWeaponSpecificEnabled)
		cbo_primary_specific.EnableComponent();
	else
		cbo_primary_specific.DisableComponent();

	if (CoopQMMRI.SecondaryWeaponSpecificEnabled)
		cbo_backup_specific.EnableComponent();
	else
		cbo_backup_specific.DisableComponent();
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

	cbo_primary_type.SetVisibility(!chk_advanced.bChecked);
	cbo_primary_specific.SetVisibility(!chk_advanced.bChecked);
	cbo_backup_type.SetVisibility(!chk_advanced.bChecked);
	cbo_backup_specific.SetVisibility(!chk_advanced.bChecked);

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
	cbo_skill.SetVisibility(!chk_advanced.bChecked);
	lbl_skill.SetVisibility(!chk_advanced.bChecked);

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
	CustomArchetype_OverridePrimaryWeapon.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideBackupWeapon.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideHelmet.SetVisibility(/*chk_advanced.bChecked*/ false);
	CustomArchetype_OverriddenPrimaryWeapon.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverriddenBackupWeapon.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverriddenHelmet.SetVisibility(/*chk_advanced.bChecked*/ false);
	CustomArchetype_OverrideMoraleLabel.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideVoiceTypeLabel.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverridePrimaryWeaponLabel.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideBackupWeaponLabel.SetVisibility(chk_advanced.bChecked);
	CustomArchetype_OverrideHelmetLabel.SetVisibility(/*chk_advanced.bChecked*/ false);


	pnl_DisabledOverlay.SetVisibility( chk_campaign.bChecked );

	Scenario = CustomScenarioPage.GetCustomScenario();
	Scenario.UseAdvancedEnemyRosters = chk_advanced.bChecked;
}

function cbo_primary_type_OnChange(GUIComponent Sender)
{
    local int i;
    local name SelectedType;
    local class<FiredWeapon> WeaponClass;

	if (CustomScenarioPage.IsServer())
		CustomScenarioPage.SendChangeMessage(EnemyPrimaryWeaponTypeChangedMessage @ cbo_primary_type.GetText());

    SelectedType = name(cbo_primary_type.List.Get());

    switch (SelectedType)
    {
    case 'Any':
		cbo_primary_specific.SetEnabled(false);
		cbo_primary_specific.Clear();
        cbo_primary_specific.AddItem("Any",, Data.AnyString);
        break;

    case 'None':
		cbo_primary_specific.SetEnabled(false);
		cbo_primary_specific.Clear();
        cbo_primary_specific.AddItem("None",, Data.NoneString);
        break;

    default:
		cbo_primary_specific.SetEnabled(false);
		cbo_primary_specific.Clear();

        //TMC TODO prevent None-None weapon selections. Why?
        cbo_primary_specific.AddItem("Any",, Data.AnyString);

        //anything else, populate the "specific" list with specific weapons
        for (i=0; i<Data.PrimaryWeapon.length; ++i)
        {
            if (Data.PrimaryWeapon[i].Category == SelectedType)
            {
                WeaponClass = class<FiredWeapon>(DynamicLoadObject(Data.PrimaryWeapon[i].Weapon, class'Class'));
                assertWithDescription(WeaponClass != None,
                    "[tcohen] CustomScenario_EnemiesTabPanel::cbo_primary_type_OnChange() "
                    $"While populating specific weapon choices for primary weapon type "$SelectedType
                    $", found that PrimaryWeapon["$i
                    $"].Weapon, specified as "$Data.PrimaryWeapon[i].Weapon
                    $" could not be DLO'd.");

                cbo_primary_specific.AddItem(Data.PrimaryWeapon[i].Weapon,, WeaponClass.default.FriendlyName);
            }
        }
        cbo_primary_specific.SetEnabled(true);
		cbo_primary_specific.SetIndex(0);
    }
}

function cbo_backup_type_OnChange(GUIComponent Sender)
{
    local int i;
    local name SelectedType;
    local class<FiredWeapon> WeaponClass;

	if (CustomScenarioPage.IsServer())
		CustomScenarioPage.SendChangeMessage(EnemyBackupWeaponTypeChangedMessage @ cbo_backup_type.GetText());

    SelectedType = name(cbo_backup_type.List.Get());

    switch (SelectedType)
    {
    case 'Any':
		cbo_backup_specific.SetEnabled(false);
		cbo_backup_specific.Clear();
        cbo_backup_specific.AddItem("Any",, Data.AnyString);
        break;

    case 'None':
		cbo_backup_specific.SetEnabled(false);
		cbo_backup_specific.Clear();
        cbo_backup_specific.AddItem("None",, Data.NoneString);
        break;

    default:
		cbo_backup_specific.SetEnabled(false);
		cbo_backup_specific.Clear();

        cbo_backup_specific.AddItem("Any",, Data.AnyString);

        //anything else, populate the "specific" list with specific weapons
        for (i=0; i<Data.BackupWeapon.length; ++i)
        {
            if (Data.BackupWeapon[i].Category == SelectedType)
            {
                WeaponClass = class<FiredWeapon>(DynamicLoadObject(Data.BackupWeapon[i].Weapon, class'Class'));
                assertWithDescription(WeaponClass != None,
                    "[tcohen] CustomScenario_EnemiesTabPanel::cbo_backup_type_OnChange() "
                    $"While populating specific weapon choices for backup weapon type "$SelectedType
                    $", found that BackupWeapon["$i
                    $"].Weapon, specified as "$Data.BackupWeapon[i].Weapon
                    $" could not be DLO'd.");

                cbo_backup_specific.AddItem(Data.BackupWeapon[i].Weapon,, WeaponClass.default.FriendlyName);
            }
        }
        cbo_backup_specific.SetEnabled(true);
		cbo_backup_specific.SetIndex(0);
    }
}

function spin_count_min_OnChange(GUIComponent Sender)
{
    if (spin_count_max.Value < spin_count_min.Value)
        spin_count_max.SetValue(spin_count_min.Value);

	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(ModifiedEnemyCountMinMessage @ spin_count_min.MyEditBox.GetText());
}

function spin_count_max_OnChange(GUIComponent Sender)
{
    if (spin_count_min.Value > spin_count_max.Value)
        spin_count_min.SetValue(spin_count_max.Value);

	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(ModifiedEnemyCountMaxMessage @ spin_count_max.MyEditBox.GetText());
}

function slide_morale_min_OnChange(GUIComponent Sender)
{
    if( slide_morale_max.Value < slide_morale_min.Value )
        slide_morale_max.SetValue(slide_morale_min.Value);

	if (CustomScenarioPage.IsClient() || slide_morale_max.MenuState == MSAT_Pressed)
		return;

	if (slide_morale_min.MenuState != MSAT_Pressed)
		CustomScenarioPage.SendChangeMessage(ModifiedEnemyMoraleMinMessage @ slide_morale_min.Value);
}

function slide_morale_max_OnChange(GUIComponent Sender)
{
    if( slide_morale_min.Value > slide_morale_max.Value )
        slide_morale_min.SetValue(slide_morale_max.Value);

	if (CustomScenarioPage.IsClient() || slide_morale_min.MenuState == MSAT_Pressed)
		return;

	if (slide_morale_max.MenuState != MSAT_Pressed)
		CustomScenarioPage.SendChangeMessage(ModifiedEnemyMoraleMaxMessage @ slide_morale_max.Value);
}

function cbo_skill_OnChange(GUIComponent Sender)
{
	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(EnemySkillChangedMessage @ cbo_skill.GetText());
}

function cbo_primary_specific_OnChange(GUIComponent Sender)
{
	if (CustomScenarioPage.IsClient())
		return;

	if (cbo_primary_specific.MenuState != MSAT_Disabled)
		CustomScenarioPage.SendChangeMessage(EnemyPrimaryWeaponSpecificChangedMessage @ cbo_primary_specific.GetText());
}

function cbo_backup_specific_OnChange(GUIComponent Sender)
{
	if (CustomScenarioPage.IsClient())
		return;

	if (cbo_backup_specific.MenuState != MSAT_Disabled)
		CustomScenarioPage.SendChangeMessage(EnemyBackupWeaponSpecificChangedMessage @ cbo_backup_specific.GetText());
}

function dlist_archetypes_OnMoveAB(GUIComponent Sender, GUIListElem Element)
{
	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(EnemyArchetypeAddedMessage @ Element.ExtraStrData);
}

function dlist_archetypes_OnMoveBA(GUIComponent Sender, GUIListElem Element)
{
	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(EnemyArchetypeRemovedMessage @ Element.ExtraStrData);
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
	for(i = 0; i < Scenario.AdvancedEnemyRosters.Length; i++)
	{
		if(Scenario.AdvancedEnemyRosters[i].DisplayName == NewName)
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
	Scenario.AdvancedEnemyRosters[Scenario.AdvancedEnemyRosters.Length] = NewRoster;

	RosterList.List.Add(NewRoster.DisplayName);
	RosterList.SetEnabled(true);
	CreateRosterName.SetText("");
}

function Roster_Delete(GUIComponent Sender)
{
	local CustomScenario Scenario;

	Scenario = CustomScenarioPage.GetCustomScenario();
	Scenario.AdvancedEnemyRosters.Remove(RosterList.List.Index, 1);
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
	NewRoster = Scenario.AdvancedEnemyRosters[RosterList.List.Index];

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
	CurrentRoster = Scenario.AdvancedEnemyRosters[RosterList.List.Index];
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
	CustomArchetype_OverridePrimaryWeapon.SetChecked(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].bOverridePrimaryWeapon);
	CustomArchetype_OverrideBackupWeapon.SetChecked(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].bOverrideBackupWeapon);
	CustomArchetype_OverrideHelmet.SetChecked(CurrentRoster.Archetypes[RosterArchetypeList.List.Index].bOverrideHelmet);

	for(i = 0; i < CustomArchetype_OverriddenPrimaryWeapon.List.ItemCount; i++)
	{
		if(CustomArchetype_OverriddenPrimaryWeapon.List.GetExtraAt(i) == CurrentRoster.Archetypes[RosterArchetypeList.List.Index].OverridePrimaryWeapon)
		{
			CustomArchetype_OverriddenPrimaryWeapon.SetIndex(i);
			break;
		}
	}

	for(i = 0; i < CustomArchetype_OverriddenBackupWeapon.List.ItemCount; i++)
	{
		if(CustomArchetype_OverriddenBackupWeapon.List.GetExtraAt(i) == CurrentRoster.Archetypes[RosterArchetypeList.List.Index].OverrideBackupWeapon)
		{
			CustomArchetype_OverriddenBackupWeapon.SetIndex(i);
			break;
		}
	}

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
	CurrentRoster = Scenario.AdvancedEnemyRosters[RosterList.List.Index];
	ArchetypeData.Chance = 0.5;
	ArchetypeData.bOverrideVoiceType = false;
	ArchetypeData.bOverrideMorale = false;
	ArchetypeData.bOverridePrimaryWeapon = false;
	ArchetypeData.bOverrideBackupWeapon = false;
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
	CurrentRoster = Scenario.AdvancedEnemyRosters[RosterList.List.Index];

	CurrentRoster.Archetypes.Remove(RosterArchetypeList.List.Index, 1);
	RosterArchetypeList.List.Remove(RosterArchetypeList.List.Index);

	if(CurrentRoster.Archetypes.Length == 0)
	{
		RosterDeleteArchetypeButton.DisableComponent();
		ArchetypeSelectionBox.DisableComponent();
		RosterArchetypeChanceSlider.DisableComponent();
	}

	Scenario.AdvancedEnemyRosters[RosterList.List.Index] = CurrentRoster;
}

function Roster_ArchetypeChanged(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster CurrentRoster;
	local CustomScenario.ArchetypeData ArchetypeData;
	local string ChanceAsString;

	Scenario = CustomScenarioPage.GetCustomScenario();
	CurrentRoster = Scenario.AdvancedEnemyRosters[RosterList.List.Index];
	ArchetypeData = CurrentRoster.Archetypes[RosterArchetypeList.List.Index];
	ArchetypeData.BaseArchetype = name(ArchetypeSelectionBox.List.GetExtra());
	ArchetypeData.Chance = RosterArchetypeChanceSlider.GetValue();
	ArchetypeData.bOverrideVoiceType = CustomArchetype_OverrideVoiceType.bChecked;
	ArchetypeData.OverrideVoiceType = name(CustomArchetype_OverriddenVoiceType.List.GetExtra());
	ArchetypeData.bOverrideMorale = CustomArchetype_OverrideMorale.bChecked;
	ArchetypeData.OverrideMinMorale = CustomArchetype_OverriddenMoraleMin.GetValue();
	ArchetypeData.OverrideMaxMorale = CustomArchetype_OverriddenMoraleMax.GetValue();
	ArchetypeData.bOverridePrimaryWeapon = CustomArchetype_OverridePrimaryWeapon.bChecked;
	ArchetypeData.bOverrideBackupWeapon = CustomArchetype_OverrideBackupWeapon.bChecked;
	ArchetypeData.bOverrideHelmet = CustomArchetype_OverrideHelmet.bChecked;
	ArchetypeData.OverridePrimaryWeapon = CustomArchetype_OverriddenPrimaryWeapon.List.GetExtra();
	ArchetypeData.OverrideBackupWeapon = CustomArchetype_OverriddenBackupWeapon.List.GetExtra();
	//ArchetypeData.OverrideHelmet
	ChanceAsString = ""$ArchetypeData.Chance$"";
	RosterArchetypeList.List.SetItemAtIndex(RosterArchetypeList.List.Index, "("$ArchetypeSelectionBox.List.Get()$", Chance="$ChanceAsString$")");

	if(RosterArchetypeList.List.Index >= 0 && RosterList.List.Index >= 0)
	{	// These can sometimes be negative = mega crash!!
		CurrentRoster.Archetypes[RosterArchetypeList.List.Index] = ArchetypeData;
		Scenario.AdvancedEnemyRosters[RosterList.List.Index] = CurrentRoster;
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
	Roster = Scenario.AdvancedEnemyRosters[RosterList.List.Index];

	Roster.Minimum = RosterMinimumSpinner.Value;
	Roster.Maximum = RosterMaximumSpinner.Value;

	Scenario.AdvancedEnemyRosters[RosterList.List.Index] = Roster;
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
	Roster = Scenario.AdvancedEnemyRosters[RosterList.List.Index];

	Roster.Maximum = RosterMaximumSpinner.Value;
	Roster.Minimum = RosterMinimumSpinner.Value;

	Scenario.AdvancedEnemyRosters[RosterList.List.Index] = Roster;
}

function Roster_SpawnAnywhereChanged(GUIComponent Sender)
{
	local CustomScenario Scenario;
	local CustomScenario.QMMRoster Roster;

	RosterSpawnerGroup.SetEnabled(!RosterSpawnAnywhereCheckbox.bChecked);

	Scenario = CustomScenarioPage.GetCustomScenario();
	Roster = Scenario.AdvancedEnemyRosters[RosterList.List.Index];

	Roster.SpawnAnywhere = RosterSpawnAnywhereCheckbox.bChecked;
	Scenario.AdvancedEnemyRosters[RosterList.List.Index] = Roster;
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

function CustomArchetype_OverridePrimaryWeaponChanged(GUIComponent Sender)
{
	CustomArchetype_OverriddenPrimaryWeapon.SetEnabled(CustomArchetype_OverridePrimaryWeapon.bChecked);
}

function CustomArchetype_OverrideBackupWeaponChanged(GUIComponent Sender)
{
	CustomArchetype_OverriddenBackupWeapon.SetEnabled(CustomArchetype_OverrideBackupWeapon.bChecked);
}

function CustomArchetype_OverrideHelmetChanged(GUIComponent Sender)
{
	CustomArchetype_OverriddenHelmet.SetEnabled(CustomArchetype_OverrideHelmet.bChecked);
}

// CustomScenarioTabPanel overrides

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

function PopulateFieldsFromScenario(bool NewScenario)
{
    local CustomScenario Scenario;
    local EnemyArchetype Archetype;
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
		chk_campaign.SetChecked(Scenario.UseCampaignEnemySettings, true);
		chk_campaign.EnableComponent();
	}


    spin_count_min.SetValue(Scenario.EnemyCountRangeCow.Min, true);
    spin_count_max.SetValue(Scenario.EnemyCountRangeCow.Max, true);

    slide_morale_min.SetValue(Scenario.EnemyMorale.Min);
    slide_morale_max.SetValue(Scenario.EnemyMorale.Max);

    dlist_archetypes.ListBoxA.Clear();
    dlist_archetypes.ListBoxB.Clear();

    chk_advanced.bChecked = Scenario.UseAdvancedEnemyRosters;

    CreateRosterButton.EnableComponent();
    if(NewScenario || Scenario.AdvancedEnemyRosters.Length == 0)
    {
    	OnAdvancedRosterListEmptied();
    }
    else
    {
    	// Add entries to the roster
    	DeleteRosterButton.EnableComponent();

    	for(i = 0; i < Scenario.AdvancedEnemyRosters.Length; i++)
    	{
    		RosterList.List.Add(Scenario.AdvancedEnemyRosters[i].DisplayName);
    	}
    }

    //fill archetypes
    for (i=0; i<Data.EnemyArchetype.length; ++i)
    {
        Archetype = new(None, string(Data.EnemyArchetype[i].Archetype)) class'EnemyArchetype';
        //NOTE! We're not calling Archetype.Initialize() because we won't actually use this Archetype
        //  for anything except reading its config data.

        if (NewScenario)
        {
            //when populating a new scenario,
            //  add an archetype to the "Selected" list iff it is ByDefault

            if (Data.EnemyArchetype[i].ByDefault)
                //add to List A: Selected Archetypes
                dlist_archetypes.ListBoxB.List.Add(
                        string(Data.EnemyArchetype[i].Archetype),
                        ,
                        Archetype.Description);
            else
                //add to List B: Available Archetypes
                dlist_archetypes.ListBoxA.List.Add(
                        string(Data.EnemyArchetype[i].Archetype),
                        ,
                        Archetype.Description);
        }
        else    //!NewScenario
        {
            //when populating an existing scenario,
            //  add an archetype to the "Selected" list iff it is selected in the Scenario

            for (j=0; j<Scenario.EnemyArchetypes.length; ++j)
            {
                if (Scenario.EnemyArchetypes[j] == Data.EnemyArchetype[i].Archetype)
                {
                    //add to List A: Selected Archetypes
                    dlist_archetypes.ListBoxB.List.Add(
                            string(Data.EnemyArchetype[i].Archetype),
                            ,
                            Archetype.Description);
                    break;
                }
            }
            if (j == Scenario.EnemyArchetypes.length)  //the Archetype was not found in the Scenario
                //add to List B: Available Archetypes
                dlist_archetypes.ListBoxA.List.Add(
                        string(Data.EnemyArchetype[i].Archetype),
                        ,
                        Archetype.Description);
        }
    }
    

    dlist_archetypes.ListBoxA.SetIndex(0);
    dlist_archetypes.ListBoxB.SetIndex(0);

    if (NewScenario)
    {
        cbo_skill.SetIndex(0);

        cbo_primary_type.SetIndex(0);
        cbo_primary_specific.SetIndex(0);
        cbo_backup_type.SetIndex(0);
        cbo_backup_specific.SetIndex(0);
    }
    else
    {
        cbo_skill.List.Find(Scenario.EnemySkill, true);

        cbo_primary_type.List.Find(Scenario.EnemyPrimaryWeaponType, true);   //bExact=true.
        cbo_primary_specific.List.Find(Scenario.EnemyPrimaryWeaponSpecific, true);   //bExact=true.
        cbo_backup_type.List.Find(Scenario.EnemyBackupWeaponType, true);   //bExact=true.
        cbo_backup_specific.List.Find(Scenario.EnemyBackupWeaponSpecific, true);   //bExact=true.
    }
}

function GatherScenarioFromFields()
{
    local CustomScenario Scenario;
    local int i;

    Scenario = CustomScenarioPage.GetCustomScenario();

	if(Scenario.IsCustomMap)
	{
		Scenario.UseCampaignEnemySettings = false;
	}
	else
	{
		Scenario.UseCampaignEnemySettings = chk_campaign.bChecked;
	}


    Scenario.EnemyCountRangeCow.Min = spin_count_min.Value;
    Scenario.EnemyCountRangeCow.Max = spin_count_max.Value;

    Scenario.EnemyMorale.Min = slide_morale_min.Value;
    Scenario.EnemyMorale.Max = slide_morale_max.Value;

    //add archetypes
    Scenario.EnemyArchetypes.Remove(0, Scenario.EnemyArchetypes.length);
    for (i=0; i<dlist_archetypes.ListBoxB.List.Elements.length; ++i)
        Scenario.EnemyArchetypes[Scenario.EnemyArchetypes.length] = name(dlist_archetypes.ListBoxB.List.GetItemAtIndex(i));

    Scenario.EnemySkill = cbo_skill.List.Get();

    Scenario.EnemyPrimaryWeaponType = cbo_primary_type.List.Get();
    Scenario.EnemyPrimaryWeaponSpecific = cbo_primary_specific.List.Get();
    GatherWeaponsOfType(
            Scenario.EnemyPrimaryWeaponType,
            Scenario.EnemyPrimaryWeaponSpecific,
            Data.PrimaryWeapon,
            Scenario.EnemyPrimaryWeaponOptions);

    Scenario.EnemyBackupWeaponType = cbo_backup_type.List.Get();
    Scenario.EnemyBackupWeaponSpecific = cbo_backup_specific.List.Get();
    GatherWeaponsOfType(
            Scenario.EnemyBackupWeaponType,
            Scenario.EnemyBackupWeaponSpecific,
            Data.BackupWeapon,
            Scenario.EnemyBackupWeaponOptions);
}

function GatherWeaponsOfType(
        string Type,
        string Specific,
        array<CustomScenarioCreatorData.WeaponPresentation> WeaponOptions,
        out array<string> WeaponSelections)
{
    local int i;

    WeaponSelections.Remove(0, WeaponSelections.length);

    if (Type == "None")     //no weapon
        return;
    else
    if (Specific != "Any")  //a specific weapon was supplied
        WeaponSelections[WeaponSelections.length] = Specific;
    else
    if (Type == "Any")      //any weapon at all
        for (i=0; i<WeaponOptions.length; ++i)
            WeaponSelections[WeaponSelections.length] = WeaponOptions[i].Weapon;
    else                    //all weapons of the Type
        for (i=0; i<WeaponOptions.length; ++i)
            if (string(WeaponOptions[i].Category) == Type)
                WeaponSelections[WeaponSelections.length] = WeaponOptions[i].Weapon;
}

defaultproperties
{
	OnActivate=InternalOnActivate
	UsingCampaignSettingsMessage="Using campaign settings"
	NotUsingCampaignSettingsMessage="Not using campaign settings"
	ModifiedEnemyCountMinMessage="Minimum enemy count modified:"
	ModifiedEnemyCountMaxMessage="Maximum enemy count modified:"
	ModifiedEnemyMoraleMinMessage="Minimum enemy morale modified:"
	ModifiedEnemyMoraleMaxMessage="Maximum enemy morale modified:"
	EnemyArchetypeAddedMessage="Enemy archetype added:"
	EnemyArchetypeRemovedMessage="Enemy archetype removed:"
	EnemySkillChangedMessage="Enemy skill changed:"
	EnemyPrimaryWeaponTypeChangedMessage="Enemy primary weapon type changed:"
	EnemyBackupWeaponTypeChangedMessage="Enemy backup weapon type changed:"
	EnemyPrimaryWeaponSpecificChangedMessage="Specific primary enemy weapon changed:"
	EnemyBackupWeaponSpecificChangedMessage="Specific backup enemy weapon changed:"
}
