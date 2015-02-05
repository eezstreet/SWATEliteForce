class CustomScenario_MissionTabPanel extends CustomScenarioTabPanel;

var(SWATGui) EditInline Config GUIComboBox                  cbo_mission;
var(SWATGui) private EditInline Config GUICheckBoxButton    chk_campaign_objectives;
var(SWATGui) EditInline Config GUIDualSelectionLists        dlist_objectives;
var(SWATGui) private EditInline Config GUILabel             lbl_mission;
var(SWATGui) private EditInline Config GUILabel             lbl_spawn_point;
var(SWATGui) private EditInline Config GUIRadioButton       opt_primary;
var(SWATGui) private EditInline Config GUILabel             lbl_primary;
var(SWATGui) private EditInline Config GUIRadioButton       opt_either;
var(SWATGui) private EditInline Config GUIRadioButton       opt_secondary;
var(SWATGui) private EditInline Config GUICheckBoxButton    chk_time_limit;
var(SWATGui) private EditInline Config GUILabel             lbl_time_limit;
var(SWATGui) private EditInline Config GUILabel             lbl_no_limit;
var(SWATGui) private EditInline Config GUILabel             lbl_either;
var(SWATGui) private EditInline Config GUILabel             lbl_secondary;
var(SWATGui) private EditInline Config GUILabel             lbl_primary_detail;
var(SWATGui) private EditInline Config GUILabel             lbl_secondary_detail;
var(SWATGui) private EditInline Config GUINumericEdit       time_limit;
var(SWATGui) private EditInline Config GUIComboBox          cbo_difficulty;

var MissionObjectives CustomMissionObjectives;  //the set of available objectives for custom scenarios

var() private config localized string MissionChangedMessage;
var() private config localized string UsingCampaignObjecivesMessage;
var() private config localized string NotUsingCampaignObjecivesMessage;
var() private config localized string UsingTimeLimitMessage;
var() private config localized string NotUsingTimeLimitMessage;
var() private config localized string EitherSpawnPointMessage;
var() private config localized string PrimarySpawnPointMessage;
var() private config localized string SecondarySpawnPointMessage;
var() private config localized string ObjectiveAddedMessage;
var() private config localized string ObjectiveRemovedMessage;
var() private config localized string DifficultyChangedMessage;

function InitComponent(GUIComponent MyOwner)
{
    local int i;

	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;

	chk_time_limit.OnChange = chk_time_limit_OnChange;

	chk_campaign_objectives.OnChange = chk_campaign_objectives_OnChange;

	cbo_mission.OnChange = cbo_mission_OnListIndexChanged;

	dlist_objectives.OnMoveAB = dlist_objectives_OnMoveAB;
	dlist_objectives.OnMoveBA = dlist_objectives_OnMoveBA;

	cbo_difficulty.OnChange = cbo_difficulty_OnChange;

	opt_either.OnChange = opt_either_OnChange;
	opt_primary.OnChange = opt_primary_OnChange;
	opt_secondary.OnChange = opt_secondary_OnChange;

	//fill mission combo list
	for (i=0; i<GC.CompleteMissionList.length; ++i)
		cbo_mission.AddItem(string(GC.CompleteMissionList[i]),, GC.CompleteFriendlyNameList[i]);

	//fill difficulties
	cbo_difficulty.AddItem("Any",, Data.AnyString);
	cbo_difficulty.AddItem("Easy",, Data.EasyString);
	cbo_difficulty.AddItem("Normal",, Data.NormalString);
	cbo_difficulty.AddItem("Hard",, Data.HardString);
	cbo_difficulty.AddItem("Elite",, Data.EliteString);
}

function ServerPoll(CoopQMMReplicationInfo CoopQMMRI)
{
	local int i;

	CoopQMMRI.MissionName = cbo_mission.GetText();

	CoopQMMRI.CampaignObjectivesChecked = chk_campaign_objectives.bChecked;

	CoopQMMRI.NoTimeLimitChecked = chk_time_limit.bChecked;
	CoopQMMRI.TimeLimit = time_limit.Value;

	CoopQMMRI.Difficulty = cbo_difficulty.GetText();

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_OBJECTIVES; ++i)
		CoopQMMRI.AvailableObjectives[i] = "";

	for (i = 0; i < dlist_objectives.ListBoxA.ItemCount(); ++i)
	{
		assert(i < class'CoopQMMReplicationInfo'.const.MAX_OBJECTIVES);
		CoopQMMRI.AvailableObjectives[i] = dlist_objectives.ListBoxA.List.GetExtraAtIndex(i);
	}

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_OBJECTIVES; ++i)
		CoopQMMRI.SelectedObjectives[i] = "";

	for (i = 0; i < dlist_objectives.ListBoxB.ItemCount(); ++i)
	{
		assert(i < class'CoopQMMReplicationInfo'.const.MAX_OBJECTIVES);
		CoopQMMRI.SelectedObjectives[i] = dlist_objectives.ListBoxB.List.GetExtraAtIndex(i);
	}

	CoopQMMRI.Primary = opt_primary.bChecked;
	CoopQMMRI.Secondary = opt_secondary.bChecked;
	CoopQMMRI.Either = opt_either.bChecked;

	CoopQMMRI.PrimaryEnabled = (opt_primary.MenuState != MSAT_Disabled);
	CoopQMMRI.SecondaryEnabled = (opt_secondary.MenuState != MSAT_Disabled);
	CoopQMMRI.EitherEnabled = (opt_either.MenuState != MSAT_Disabled);
}

function ClientPoll(CoopQMMReplicationInfo CoopQMMRI)
{
	local int i;

	cbo_mission.SetText(CoopQMMRI.MissionName);

	chk_campaign_objectives.SetChecked(CoopQMMRI.CampaignObjectivesChecked);

	chk_time_limit.SetChecked(CoopQMMRI.NoTimeLimitChecked);
	time_limit.SetValue(CoopQMMRI.TimeLimit);

	cbo_difficulty.SetText(CoopQMMRI.Difficulty);

	dlist_objectives.ListBoxA.List.Clear();
    dlist_objectives.ListBoxB.List.Clear();

	dlist_objectives.ListBoxA.List.DisplayItem = LIST_ELEM_Item;
	dlist_objectives.ListBoxB.List.DisplayItem = LIST_ELEM_Item;

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_OBJECTIVES; ++i)
	{
		if (CoopQMMRI.AvailableObjectives[i] == "")
			break;

		dlist_objectives.ListBoxA.List.Add(CoopQMMRI.AvailableObjectives[i]);
	}

	for (i = 0; i < class'CoopQMMReplicationInfo'.const.MAX_OBJECTIVES; ++i)
	{
		if (CoopQMMRI.SelectedObjectives[i] == "")
			break;

		dlist_objectives.ListBoxB.List.Add(CoopQMMRI.SelectedObjectives[i]);
	}

	opt_primary.SetChecked(CoopQMMRI.Primary);
	opt_secondary.SetChecked(CoopQMMRI.Secondary);
	opt_either.SetChecked(CoopQMMRI.Either);

	if (CoopQMMRI.PrimaryEnabled)
		opt_primary.EnableComponent();
	else
		opt_primary.DisableComponent();

	if (CoopQMMRI.SecondaryEnabled)
		opt_secondary.EnableComponent();
	else
		opt_secondary.DisableComponent();

	if (CoopQMMRI.EitherEnabled)
		opt_either.EnableComponent();
	else
		opt_either.DisableComponent();
}

function chk_time_limit_OnChange(GUIComponent Sender)
{
    time_limit.SetEnabled(!chk_time_limit.bChecked);

	if (CustomScenarioPage.IsClient())
		return;

	if (chk_time_limit.bChecked)
		CustomScenarioPage.SendChangeMessage(NotUsingTimeLimitMessage);
	else
		CustomScenarioPage.SendChangeMessage(UsingTimeLimitMessage);
}

function opt_either_OnChange(GUIComponent Sender)
{
	if (CustomScenarioPage.IsClient())
		return;

	if (opt_either.bChecked)
		CustomScenarioPage.SendChangeMessage(EitherSpawnPointMessage);
}

function opt_primary_OnChange(GUIComponent Sender)
{
	if (CustomScenarioPage.IsClient())
		return;

	if (opt_primary.bChecked)
		CustomScenarioPage.SendChangeMessage(PrimarySpawnPointMessage);
}

function opt_secondary_OnChange(GUIComponent Sender)
{
	if (CustomScenarioPage.IsClient())
		return;

	if (opt_secondary.bChecked)
		CustomScenarioPage.SendChangeMessage(SecondarySpawnPointMessage);
}

function chk_campaign_objectives_OnChange(GUIComponent Sender)
{
    local CustomScenarioCreatorMissionSpecificData MissionData;

	if (CustomScenarioPage.IsClient())
		return;

	if (chk_campaign_objectives.bChecked)
		CustomScenarioPage.SendChangeMessage(UsingCampaignObjecivesMessage);
	else
		CustomScenarioPage.SendChangeMessage(NotUsingCampaignObjecivesMessage);

    MissionData = Data.GetMissionData_Slow(name(cbo_mission.List.Get()));

    UpdateSpawnCounts(MissionData);
}

function cbo_mission_OnListIndexChanged(GUIComponent Sender)
{
    local CustomScenarioCreatorMissionSpecificData MissionData;

	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(MissionChangedMessage @ cbo_mission.GetText());

    MissionData = Data.GetMissionData_Slow(name(cbo_mission.List.Get()));

    UpdateSpawnCounts(MissionData);

    //update entry points

    AssertWithDescription( MissionData.PrimarySpawnPoint != "", "Error! There is no Primary Spawn point available for this Map!" );

    lbl_primary_detail.SetCaption(MissionData.PrimarySpawnPoint);
    opt_primary.EnableComponent();

    if (MissionData.SecondarySpawnPoint != "")
    {
        lbl_secondary_detail.SetCaption(MissionData.SecondarySpawnPoint);
        opt_secondary.EnableComponent();
        opt_either.EnableComponent(); //both options available, either is available
        opt_either.SelectRadioButton(); //both options available, select either by default
    }
    else
    {
        lbl_secondary_detail.SetCaption(Data.UnavailableString);
        opt_secondary.DisableComponent();
        opt_either.DisableComponent(); //both options available, either is un-available
        opt_primary.SelectRadioButton(); //only primary available, select primary by default
    }
}

function dlist_objectives_OnMoveAB(GUIComponent Sender, GUIListElem Element)
{
	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(ObjectiveAddedMessage @ Element.ExtraStrData);
}

function dlist_objectives_OnMoveBA(GUIComponent Sender, GUIListElem Element)
{
	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(ObjectiveRemovedMessage @ Element.ExtraStrData);
}

function cbo_difficulty_OnChange(GUIComponent Sender)
{
	if (CustomScenarioPage.IsClient())
		return;

	CustomScenarioPage.SendChangeMessage(DifficultyChangedMessage @ cbo_difficulty.GetText());
}

//update the controls on the Enemies and Hostages tabs, including lbl_count, spin_count_min, and spin_count_max
function UpdateSpawnCounts(CustomScenarioCreatorMissionSpecificData MissionData)
{
    local int NumEnemies, NumHostages;

    //
    //Enemies
    //

    NumEnemies = MissionData.CampaignObjectiveEnemySpawn.length;

    if  (
            chk_campaign_objectives.bChecked
        &&  NumEnemies > 0
        )
    {
        //"Number of enemies, including {#} campiagn objectives."
        CustomScenarioPage.pnl_enemies_pnl_body_lbl_count.SetCaption(
                Data.NumberOfEnemiesString
            $   Data.CommaIncludingString
            $   " "
            $   NumEnemies
            $   " "
            $   Data.CampaignObjectivesString);

        CustomScenarioPage.pnl_enemies_spin_count_min.SetMinValue(NumEnemies);
		CustomScenarioPage.pnl_enemies_spin_count_max.SetMinValue(NumEnemies);
    }
    else
    {
        //"Number of enemies, including {#} campiagn objectives."
        CustomScenarioPage.pnl_enemies_pnl_body_lbl_count.SetCaption(Data.NumberOfEnemiesString);

        CustomScenarioPage.pnl_enemies_spin_count_min.SetMinValue(0);
		CustomScenarioPage.pnl_enemies_spin_count_max.SetMinValue(0);
    }

    //max'es are the number of spawners
    CustomScenarioPage.pnl_enemies_spin_count_min.SetMaxValue(MissionData.EnemySpawners);
    CustomScenarioPage.pnl_enemies_spin_count_max.SetMaxValue(MissionData.EnemySpawners);

    //
    //Hostages
    //

    NumHostages = MissionData.CampaignObjectiveHostageSpawn.length;

    if  (
            chk_campaign_objectives.bChecked
        &&  NumHostages > 0
        )
    {
        //"Number of hostages, including {#} campiagn objectives."
        CustomScenarioPage.pnl_hostages_pnl_body_lbl_count.SetCaption(
                Data.NumberOfHostagesString
            $   Data.CommaIncludingString
            $   " "
            $   MissionData.CampaignObjectiveHostageSpawn.length
            $   " "
            $   Data.CampaignObjectivesString);

        CustomScenarioPage.pnl_hostages_spin_count_min.SetMinValue(NumHostages);
		CustomScenarioPage.pnl_hostages_spin_count_max.SetMinValue(NumHostages);
    }
    else
    {
        //"Number of hostages, including {#} campiagn objectives."
        CustomScenarioPage.pnl_hostages_pnl_body_lbl_count.SetCaption(Data.NumberOfHostagesString);

        CustomScenarioPage.pnl_hostages_spin_count_min.SetMinValue(0);
		CustomScenarioPage.pnl_hostages_spin_count_max.SetMinValue(0);
    }

    //max'es are the number of spawners
    CustomScenarioPage.pnl_hostages_spin_count_min.SetMaxValue(MissionData.HostageSpawners);
    CustomScenarioPage.pnl_hostages_spin_count_max.SetMaxValue(MissionData.HostageSpawners);
}

//reset the state of dlist_objectives to present all potential
//  objectives as "available" and none as "selected"
//This method is used in preparation for populating the data
//  from a Scenario, ie. any objectives specified in the
//  Scenario will be "added".
function InitializeObjectives()
{
    local int i;

    if (CustomMissionObjectives == None)
    {
        CustomMissionObjectives = new (None, "CustomScenario") class'SwatGame.MissionObjectives';
        assert(CustomMissionObjectives != None);
    }

    dlist_objectives.ListBoxA.List.Clear();
    dlist_objectives.ListBoxB.List.Clear();

    for (i=0; i<CustomMissionObjectives.Objectives.length; ++i)
        if (CustomMissionObjectives.Objectives[i].name != 'Automatic_DoNot_Die')
            dlist_objectives.ListBoxA.List.Add(
                    string(CustomMissionObjectives.Objectives[i].name),
                    , 
                    CustomMissionObjectives.Objectives[i].Description);
}

// CustomScenarioTabPanel overrides

function PopulateFieldsFromScenario(bool NewScenario)
{
    local int i;
    local CustomScenario Scenario;
    local string Found;

    Scenario = CustomScenarioPage.GetCustomScenario();

    //mission
    cbo_mission.List.Find(string(Scenario.LevelLabel), true);   //bExact=true.
    //note that GUIList::Find() acutally selects the found item

    //objectives
    InitializeObjectives();
    chk_campaign_objectives.SetChecked(Scenario.UseCampaignObjectives);
    for (i=0; i<Scenario.ScenarioObjectives.length; ++i)
    {
        Found = dlist_objectives.ListBoxA.List.Find(string(Scenario.ScenarioObjectives[i]));
        assertWithDescription(Found != "",
            "[tcohen] CustomScenario_MissionTabPanel::PopulateFieldsFromScenario()"
            $" Couldn't find selected Objective named "$Scenario.ScenarioObjectives[i]
            $" in dlist_objectives.ListBoxA.");
        dlist_objectives.MoveAB(None);  //move the objective from "available" to "selected"
    }

    //entry options
    if (!NewScenario)
    {
        if (Scenario.SpecifyStartPoint)
        {
            if (Scenario.UseSecondaryStartPoint)
                opt_secondary.SelectRadioButton();
            else
                opt_primary.SelectRadioButton();
        }
        else
            opt_either.SelectRadioButton();
    }

    //difficulty
    if (NewScenario)
        cbo_difficulty.SetIndex(0);
    else
        cbo_difficulty.List.Find(Scenario.Difficulty, true);

    //time limit
    chk_time_limit.SetChecked(Scenario.TimeLimit == 0);  //this should trigger chk_time_limit_Onchanged()
    if (Scenario.TimeLimit > 0)
        time_limit.SetValue(Scenario.TimeLimit, true);
    else
        time_limit.SetValue(Data.DefaultTimeLimit, true);
}

function GatherScenarioFromFields()
{
    local int i;
    local CustomScenario Scenario;

    Scenario = CustomScenarioPage.GetCustomScenario();

    Scenario.LevelLabel = name(cbo_mission.List.Get());
    
    //gather Objectives, including TimeLimit

    Scenario.UseCampaignObjectives = chk_campaign_objectives.bChecked;

    //clear mission objectives
    Scenario.ScenarioObjectives.Remove(0, Scenario.ScenarioObjectives.length);
    //add specified objectives
    for (i=0; i<dlist_objectives.ListBoxB.List.Elements.length; ++i)
        Scenario.ScenarioObjectives[i] = name(dlist_objectives.ListBoxB.List.GetItemAtIndex(i));

    Scenario.Difficulty = cbo_difficulty.List.Get();
    
    Scenario.SpecifyStartPoint = !opt_either.bChecked;
    if (!opt_either.bChecked)
        Scenario.UseSecondaryStartPoint = opt_secondary.bChecked;

    if (chk_time_limit.bChecked)
        Scenario.TimeLimit = 0;
    else
        Scenario.TimeLimit = time_limit.Value;
}

event Activate()
{
    Data.SetCurrentMissionDirty();
    Super.Activate();
}

defaultproperties
{
	MissionChangedMessage="Mission changed:"
	UsingCampaignObjecivesMessage="Using campaign objectives"
	NotUsingCampaignObjecivesMessage="Not using campaign objectives"
	UsingTimeLimitMessage="The mission will have a time limit"
	NotUsingTimeLimitMessage="The mission will not have a time limit"
	EitherSpawnPointMessage="Either spawn point will be used"
	PrimarySpawnPointMessage="The primary spawn point will be used"
	SecondarySpawnPointMessage="The secondary spawn point will be used"
	ObjectiveAddedMessage="Objective added:"
	ObjectiveRemovedMessage="Objective removed:"
	DifficultyChangedMessage="Difficulty changed:"
}