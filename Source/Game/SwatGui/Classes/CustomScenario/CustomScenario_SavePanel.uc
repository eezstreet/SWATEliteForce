class CustomScenario_SavePanel extends CustomScenarioTabPanel;

var(SWATGui) private EditInline Config GUIEditBox           txt_name;
var(SWATGui) private EditInline Config GUIComboBox          cbo_pack;
var(SWATGui) private EditInline Config GUIButton            cmd_save_OK;
var(SWATGui) private EditInline Config GUIButton            cmd_save_Cancel;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	
    cmd_save_OK.OnClick     = cmd_save_OK_OnClick;
    cmd_save_Cancel.OnClick = cmd_save_Cancel_OnClick;

    txt_name.OnChange = OnSaveNameChanged;
    cbo_pack.OnChange = OnSaveNameChanged;

    Data = CustomScenarioPage.CustomScenarioCreatorData;
}

function OnSaveNameChanged(GUIComponent Sender)
{
    cmd_save_OK.SetEnabled( txt_name.GetText() != "" && cbo_pack.GetText() != "" );
    CustomScenarioPage.SetCheckForOverwrite();
}

function cmd_save_OK_OnClick(GUIComponent Sender)
{
    CustomScenarioPage.SaveCurrentScenario();
}

function cmd_save_Cancel_OnClick(GUIComponent Sender)
{
    CustomScenarioPage.OpenInitialTab();
}

function LocalizeNewScenarioName()
{
    txt_name.SetText(Data.NewScenarioString);
    cbo_pack.SetText(CustomScenarioPage.PackMinusExtension(Data.DefaultPackString));
}

// CustomScenarioTabPanel overrides
function PopulateFieldsFromScenario(bool NewScenario)
{
    local CustomScenario Scenario;
    local int i;
    
    cbo_pack.Clear();

    for( i = 0; i < CustomScenarioPage.ScenarioPacks.Length; i++ )
    {
        cbo_pack.AddItem( CustomScenarioPage.ScenarioPacks[i] );
    }

    if( NewScenario )
    {
        txt_name.SetText(Data.NewScenarioString);
        cbo_pack.SetText(CustomScenarioPage.PackMinusExtension(Data.DefaultPackString));
    }
    else
    {
        Scenario = CustomScenarioPage.GetCustomScenario();

        txt_name.SetText(Scenario.ScenarioName);
        cbo_pack.Edit.SetText(CustomScenarioPage.PackMinusExtension(Scenario.PackName));
    }
}

function GatherScenarioFromFields()
{
    local CustomScenario Scenario;

    Scenario = CustomScenarioPage.GetCustomScenario();

    Scenario.ScenarioName = txt_name.GetText();
    Scenario.PackName = cbo_pack.Edit.GetText();
}

function bool AllowChat()
{
	return txt_name.MenuState != MSAT_Focused && cbo_pack.Edit.MenuState != MSAT_Focused;
}