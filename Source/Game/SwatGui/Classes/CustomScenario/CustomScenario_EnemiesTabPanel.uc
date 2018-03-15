class CustomScenario_EnemiesTabPanel extends CustomScenarioTabPanel;

var(SWATGui) EditInline Config GUICheckBoxButton            chk_campaign;
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

	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;

    chk_campaign.OnChange               = chk_campaign_OnChange;

	dlist_archetypes.OnMoveAB			= dlist_archetypes_OnMoveAB;
	dlist_archetypes.OnMoveBA			= dlist_archetypes_OnMoveBA;

    cbo_primary_type.OnChange           = cbo_primary_type_OnChange;
    cbo_backup_type.OnChange            = cbo_backup_type_OnChange;

    spin_count_min.OnChange             = spin_count_min_OnChange;
    spin_count_max.OnChange             = spin_count_max_OnChange;
    slide_morale_min.OnChange           = slide_morale_min_OnChange;
    slide_morale_max.OnChange           = slide_morale_max_OnChange;

	cbo_skill.OnChange					= cbo_skill_OnChange;

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

	cbo_primary_specific.OnChange           = cbo_primary_specific_OnChange;
	cbo_backup_specific.OnChange            = cbo_Backup_specific_OnChange;

    //specifics are disabled until type changes
    cbo_primary_specific.AddItem("Any",, Data.AnyString);
    cbo_primary_specific.SetEnabled(false);
    cbo_backup_specific.AddItem("Any",, Data.AnyString);
    cbo_backup_specific.SetEnabled(false);
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
}

function PopulateFieldsFromScenario(bool NewScenario)
{
    local CustomScenario Scenario;
    local EnemyArchetype Archetype;
    local int i,j;

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
