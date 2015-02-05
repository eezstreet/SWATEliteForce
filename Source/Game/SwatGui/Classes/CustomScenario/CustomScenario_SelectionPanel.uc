class CustomScenario_SelectionPanel extends CustomScenarioTabPanel;

var(SWATGui) private EditInline Config GUIButton            cmd_play;

var(SWATGui) private EditInline Config GUIButton            cmd_new;
var(SWATGui) private EditInline Config GUIButton            cmd_edit;
var(SWATGui) private EditInline Config GUIButton            cmd_delete;
var(SWATGui) private EditInline Config CustomScenarioList   lst_scenarios;

var() private config localized string ConfirmDeleteString;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;

    cmd_play.OnClick        = cmd_play_OnClick;

    cmd_new.OnClick         = cmd_new_OnClick;
    cmd_edit.OnClick        = cmd_edit_OnClick;
    cmd_delete.OnClick      = cmd_delete_OnClick;
    lst_scenarios.OnChange  = lst_scenarios_OnChange;
}

event Activate()
{
    RefreshScenariosList();
    
    Super.Activate();

    UpdateButtonStates();
}

function cmd_play_OnClick(GUIComponent Sender)
{
    local string Scenario;
    local string Pack;

    lst_scenarios.GetSelectedRow(Scenario, Pack);

    CustomScenarioPage.PlayScenario(Scenario, Pack);
}

function cmd_new_OnClick(GUIComponent Sender)
{
    CustomScenarioPage.CreateNewScenario();
}

function cmd_edit_OnClick(GUIComponent Sender)
{
    local string Scenario;
    local string Pack;

    lst_scenarios.GetSelectedRow(Scenario, Pack);

    CustomScenarioPage.EditScenario(Scenario, Pack);
}

function cmd_delete_OnClick(GUIComponent Sender)
{
    local string Scenario;
    local string Pack;

    lst_scenarios.GetSelectedRow(Scenario, Pack);

	Controller.TopPage().OnDlgReturned=ConfirmDeleteDlgReturned;
    Controller.TopPage().OpenDlg( FormatTextString( ConfirmDeleteString, Scenario, Pack ), QBTN_YesNo, "" );
}

function ConfirmDeleteDlgReturned( int Selection, String passback )
{
    local string Scenario;
    local string Pack;

    if( Selection != QBTN_Yes )
        return;

    lst_scenarios.GetSelectedRow(Scenario, Pack);

    CustomScenarioPage.DeleteScenario(Scenario, Pack);
    
    RefreshScenariosList();
}

function RefreshScenariosList()
{
    local int i,j;
    local string PackName;

    lst_scenarios.Clear();

    for( i = 0; i < CustomScenarioPage.ScenarioPacks.Length; i++ )
    {
        PackName = CustomScenarioPage.ScenarioPacks[i];

        CustomScenarioPage.SetCustomScenarioPack(PackName);

        for( j = 0; j < CustomScenarioPage.GetPack().ScenarioStrings.Length; j++ )
        {
            lst_scenarios.AddRow(CustomScenarioPage.GetPack().ScenarioStrings[j], PackName);
        }
    }
}

//refresh the activation of cmd_new/edit/delete/duplicate
function UpdateButtonStates()
{
    //the new button is active as long as we're looking at the scenarios list
    cmd_new.EnableComponent();

    //the other buttons are active if we're looking at the scenarios list and a scenario is selected
    cmd_edit.SetEnabled(lst_scenarios.ActiveRowIndex >= 0);
    cmd_delete.SetEnabled(lst_scenarios.ActiveRowIndex >= 0);
    
    cmd_play.SetEnabled(lst_scenarios.ActiveRowIndex >= 0);
}

function lst_scenarios_OnChange(GUIComponent Sender)
{
    UpdateButtonStates();
}

// CustomScenarioTabPanel overrides
function PopulateFieldsFromScenario(bool NewScenario)
{
}

function GatherScenarioFromFields()
{
}

defaultproperties
{
    ConfirmDeleteString="Are you sure that you wish to delete scenario %1 from pack %2?"
}
