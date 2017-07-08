class CustomScenario_SquadTabPanel extends CustomScenarioTabPanel;

var(SWATGui) private EditInline Config GUIPanel             pnl_officers;
var(SWATGui) private EditInline Config GUICheckBoxButton    chk_lone_wolf;
var(SWATGui) private EditInline Config GUILabel             lbl_lone_wolf;

var(SWATGui) private EditInline Config GUICheckBoxButton    pnl_officers_chk_red_one;
var(SWATGui) private EditInline Config GUICheckBoxButton    pnl_officers_chk_red_two;
var(SWATGui) private EditInline Config GUICheckBoxButton    pnl_officers_chk_blue_two;
var(SWATGui) private EditInline Config GUICheckBoxButton    pnl_officers_chk_blue_one;

var(SWATGui) EditInline Config CustomScenarioOfficerPanel   pnl_officer_red_one;
var(SWATGui) EditInline Config CustomScenarioOfficerPanel   pnl_officer_red_two;
var(SWATGui) EditInline Config CustomScenarioOfficerPanel   pnl_officer_blue_one;
var(SWATGui) EditInline Config CustomScenarioOfficerPanel   pnl_officer_blue_two;

var() private bool bLoneWolfBeingChecked;

function InitComponent(GUIComponent MyOwner)
{
    local int i;

	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;

    chk_lone_wolf.OnChange =             chk_lone_wolf_OnChange;

    pnl_officers_chk_red_one.OnChange =  pnl_officers_chk_red_one_OnChange;
    pnl_officers_chk_red_two.OnChange =  pnl_officers_chk_red_two_OnChange;
    pnl_officers_chk_blue_one.OnChange = pnl_officers_chk_blue_one_OnChange;
    pnl_officers_chk_blue_two.OnChange = pnl_officers_chk_blue_two_OnChange;

    //propagate load-out combo boxes with avalable predefined loadout descriptions

    pnl_officer_red_one.cbo.AddItem("Any",,Data.AnyLoadoutString);  //the word "Any Loadout"
    for (i=0; i<Data.PredefinedRedOneLoadOut.length; ++i)
        pnl_officer_red_one.cbo.AddItem(
                Data.PredefinedRedOneLoadOut[i],
                ,
                GetLoadoutFriendlyName(Data.PredefinedRedOneLoadOut[i], 'OfficerRedOne'));

    pnl_officer_red_two.cbo.AddItem("Any",,Data.AnyLoadoutString);  //the word "Any Loadout"
    for (i=0; i<Data.PredefinedRedTwoLoadOut.length; ++i)
        pnl_officer_red_two.cbo.AddItem(
                Data.PredefinedRedTwoLoadOut[i],
                ,
                GetLoadoutFriendlyName(Data.PredefinedRedTwoLoadOut[i], 'OfficerRedTwo'));

    pnl_officer_blue_one.cbo.AddItem("Any",,Data.AnyLoadoutString);  //the word "Any Loadout"
    for (i=0; i<Data.PredefinedBlueOneLoadOut.length; ++i)
        pnl_officer_blue_one.cbo.AddItem(
                Data.PredefinedBlueOneLoadOut[i],
                ,
                GetLoadoutFriendlyName(Data.PredefinedBlueOneLoadOut[i], 'OfficerBlueOne'));

    pnl_officer_blue_two.cbo.AddItem("Any",,Data.AnyLoadoutString);  //the word "Any Loadout"
    for (i=0; i<Data.PredefinedBlueTwoLoadOut.length; ++i)
        pnl_officer_blue_two.cbo.AddItem(
                Data.PredefinedBlueTwoLoadOut[i],
                ,
                GetLoadoutFriendlyName(Data.PredefinedBlueTwoLoadOut[i], 'OfficerBlueTwo'));

    chk_lone_wolf.SetChecked(false);
}

function string GetLoadoutFriendlyName(string LoadOut, name Officer)
{
    local int i;

    for (i=0; i<GC.CustomEquipmentLoadouts.length; ++i)
       if (GC.CustomEquipmentLoadouts[i] == LoadOut)
           return GC.CustomEquipmentLoadoutFriendlyNames[i];

    assertWithDescription(false,
        "[tcohen] CustomScenario_SquadTabPanel::GetLoadoutFriendlyName() couldn't find the LoadOut named "$LoadOut
        $" for "$Officer
        $" in his PredefinedLoadOut in CustomScenarioCreator.ini.");
}

function chk_lone_wolf_OnChange(GUIComponent Sender)
{
    bLoneWolfBeingChecked = true;
    pnl_officers_chk_red_one.SetChecked(!chk_lone_wolf.bChecked);
    pnl_officers_chk_red_two.SetChecked(!chk_lone_wolf.bChecked);
    pnl_officers_chk_blue_one.SetChecked(!chk_lone_wolf.bChecked);
    pnl_officers_chk_blue_two.SetChecked(!chk_lone_wolf.bChecked);
    bLoneWolfBeingChecked = false;
}

function pnl_officers_chk_red_one_OnChange(GUIComponent Sender)
{
    pnl_officer_red_one.SetEnabled(pnl_officers_chk_red_one.bChecked);
    SetLoneWolfCheck();
}

function pnl_officers_chk_red_two_OnChange(GUIComponent Sender)
{
    pnl_officer_red_two.SetEnabled(pnl_officers_chk_red_two.bChecked);
    SetLoneWolfCheck();
}

function pnl_officers_chk_blue_one_OnChange(GUIComponent Sender)
{
    pnl_officer_blue_one.SetEnabled(pnl_officers_chk_blue_one.bChecked);
    SetLoneWolfCheck();
}

function pnl_officers_chk_blue_two_OnChange(GUIComponent Sender)
{
    pnl_officer_blue_two.SetEnabled(pnl_officers_chk_blue_two.bChecked);
    SetLoneWolfCheck();
}

private function SetLoneWolfCheck()
{
    if( bLoneWolfBeingChecked )
        return;
        
    chk_lone_wolf.bChecked = !( pnl_officers_chk_red_one.bChecked || 
                                pnl_officers_chk_red_two.bChecked || 
                                pnl_officers_chk_blue_one.bChecked || 
                                pnl_officers_chk_blue_two.bChecked );
}

// CustomScenarioTabPanel overrides

function PopulateFieldsFromScenario(bool NewScenario)
{
    local CustomScenario Scenario;

    Scenario = CustomScenarioPage.GetCustomScenario();

    if (NewScenario)
    {
        pnl_officer_red_one.cbo.List.Find("Any");
        pnl_officers_chk_red_one.SetChecked(true);

        pnl_officer_red_two.cbo.List.Find("Any");
        pnl_officers_chk_red_two.SetChecked(true);

        pnl_officer_blue_one.cbo.List.Find("Any");
        pnl_officers_chk_blue_one.SetChecked(true);

        pnl_officer_blue_two.cbo.List.Find("Any");
        pnl_officers_chk_blue_two.SetChecked(true);
    }
    else
    {
        chk_lone_wolf.SetChecked(Scenario.LoneWolf);

        if (!Scenario.LoneWolf)
        {
            pnl_officer_red_one.cbo.List.Find(string(Scenario.RedOneLoadOut));
            pnl_officers_chk_red_one.SetChecked(Scenario.HasOfficerRedOne);

            pnl_officer_red_two.cbo.List.Find(string(Scenario.RedTwoLoadOut));
            pnl_officers_chk_red_two.SetChecked(Scenario.HasOfficerRedTwo);

            pnl_officer_blue_one.cbo.List.Find(string(Scenario.BlueOneLoadOut));
            pnl_officers_chk_blue_one.SetChecked(Scenario.HasOfficerBlueOne);

            pnl_officer_blue_two.cbo.List.Find(string(Scenario.BlueTwoLoadOut));
            pnl_officers_chk_blue_two.SetChecked(Scenario.HasOfficerBlueTwo);
        }
    }
}

function GatherScenarioFromFields()
{
    local CustomScenario Scenario;

    Scenario = CustomScenarioPage.GetCustomScenario();

    Scenario.LoneWolf = chk_lone_wolf.bChecked;

    Scenario.HasOfficerRedOne = pnl_officers_chk_red_one.bChecked;
    Scenario.RedOneLoadOut = name(pnl_officer_red_one.cbo.List.Get());

    Scenario.HasOfficerRedTwo = pnl_officers_chk_red_two.bChecked;
    Scenario.RedTwoLoadOut = name(pnl_officer_red_two.cbo.List.Get());

    Scenario.HasOfficerBlueOne = pnl_officers_chk_blue_one.bChecked;
    Scenario.BlueOneLoadOut = name(pnl_officer_blue_one.cbo.List.Get());

    Scenario.HasOfficerBlueTwo = pnl_officers_chk_blue_two.bChecked;
    Scenario.BlueTwoLoadOut = name(pnl_officer_blue_two.cbo.List.Get());
}
