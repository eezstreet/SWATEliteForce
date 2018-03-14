class CustomScenario_HostagesTabPanel extends CustomScenarioTabPanel;

var(SWATGui) EditInline Config GUICheckBoxButton            chk_campaign;
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
	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;

	chk_campaign.OnChange = chk_campaign_OnChange;

	dlist_archetypes.OnMoveAB = dlist_archetypes_OnMoveAB;
	dlist_archetypes.OnMoveBA = dlist_archetypes_OnMoveBA;

	spin_count_min.OnChange = spin_count_min_OnChange;
	spin_count_max.OnChange = spin_count_max_OnChange;
	slide_morale_min.OnChange = slide_morale_min_OnChange;
	slide_morale_max.OnChange = slide_morale_max_OnChange;
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

// CustomScenarioTabPanel overrides

function PopulateFieldsFromScenario(bool NewScenario)
{
    local CustomScenario Scenario;
    local HostageArchetype Archetype;
    local int i,j;

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
	UsingCampaignSettingsMessage="Using campaign settings"
	NotUsingCampaignSettingsMessage="Not using campaign settings"
	ModifiedHostageCountMinMessage="Minimum hostage count modified:"
	ModifiedHostageCountMaxMessage="Maximum hostage count modified:"
	ModifiedHostageMoraleMinMessage="Minimum hostage morale modified:"
	ModifiedHostageMoraleMaxMessage="Maximum hostage morale modified:"
	HostageArchetypeAddedMessage="Hostage archetype added:"
	HostageArchetypeRemovedMessage="Hostage archetype removed:"
}
