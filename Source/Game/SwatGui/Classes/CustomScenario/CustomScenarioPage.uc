class CustomScenarioPage extends SwatCustomScenarioPageBase
    dependsOn(CustomScenarioTabControl)
    ;
    
import enum ETabPanels from SwatGui.CustomScenarioTabControl;

var(SWATGui) private EditInline Config GUIButton		    cmd_main;

//master tab control
var(SWATGui) protected EditInline Config CustomScenarioTabControl        tabs;

//component references needed by tab panels

var(SWATGui) EditInline Config GUILabel             pnl_enemies_pnl_body_lbl_count;
var(SWATGui) EditInline Config GUINumericEdit       pnl_enemies_spin_count_min;
var(SWATGui) EditInline Config GUINumericEdit       pnl_enemies_spin_count_max;

var(SWATGui) EditInline Config GUILabel             pnl_hostages_pnl_body_lbl_count;
var(SWATGui) EditInline Config GUINumericEdit       pnl_hostages_spin_count_min;
var(SWATGui) EditInline Config GUINumericEdit       pnl_hostages_spin_count_max;

var private CustomScenario              CustomScenario;
var private localized config string ConfirmationString;
var private localized config string ConfirmOverwriteExistingScenarioString;

var private bool bCheckForOverwrite;

function bool IsClient()
{
	return (PlayerOwner().Level.NetMode == NM_Client);
}

function bool IsServer()
{
	return (PlayerOwner().Level.NetMode == NM_DedicatedServer || PlayerOwner().Level.NetMode == NM_ListenServer);
}

function SendChangeMessage( String Msg )
{

}

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    cmd_main.OnClick        = cmd_main_OnClick;
}

function cmd_main_OnClick(GUIComponent Sender)
{
    PerformClose();
}

function PerformClose()
{
    if( CustomScenarioCreatorData.IsCurrentMisisonDirty() )
        ConfirmQuitOrSave( "MainMenu" );
    else
        Super.PerformClose();
}

function ConfirmQuitOrSave( string passback )
{
    OnDlgReturned=ConfirmedQuitOrSave;
    OpenDlg( ConfirmationString, QBTN_YesNo, passback );
}

private function ConfirmedQuitOrSave( int returnButton, optional string Passback )
{
    if( returnButton == QBTN_Yes )
    {
        if( Passback == "MainMenu" )
            Super.PerformClose();
        else if( Passback == "Selection" )
            OnActivate();
    }
}

function OnActivate()
{
    CustomScenarioCreatorData.ClearCurrentMissionDirty();

    RefreshCustomScenarioPackList();

	tabs.OpenTabByIndex(ETabPanels.Tab_Selection);
}

function CreateNewScenario()
{
    Controller.OpenWaitDialog();

    NewCustomScenario();

    InternalEditScenario(false);

    CustomScenario_SavePanel(tabs.MyTabs[ETabPanels.Tab_Save].TabPanel).LocalizeNewScenarioName();

    Controller.CloseWaitDialog();

    bCheckForOverwrite = true;
}

function EditScenario(string Scenario, string Pack)
{
    Controller.OpenWaitDialog();

    CustomScenarioPack.LoadCustomScenarioInPlace(
            NewCustomScenario(),
            Scenario, 
            PackPlusExtension(Pack), 
            CustomScenarioCreatorData.ScenariosPath);

    InternalEditScenario(false);

    Controller.CloseWaitDialog();

    bCheckForOverwrite = false;
}

function DeleteScenario(string Scenario, string Pack)
{
    CustomScenarioPack.DeleteCustomScenario(
            Scenario, 
            PackPlusExtension(Pack), 
            CustomScenarioCreatorData.ScenariosPath);

    OnActivate();
}

function SaveCurrentScenario()
{
    local string Scenario;
    local string Pack;

    GatherScenarioFromFields();
    
    // Check for scenario overwrite
    if (bCheckForOverwrite)
    {
        Scenario = GetCustomScenario().ScenarioName;
        Pack = GetCustomScenario().PackName;

        CustomScenarioPack.Reset(PackPlusExtension(Pack), CustomScenarioCreatorData.ScenariosPath);
        if (CustomScenarioPack.HasScenario(Scenario))
        {
        //log( FormatTextString( ConfirmOverwriteExistingScenarioString, Scenario, Pack ) );
            OnDlgReturned=ConfirmOverwriteExistingScenario;
            OpenDlg( FormatTextString( ConfirmOverwriteExistingScenarioString, Scenario, Pack ), QBTN_YesNo, "Overwrite" );
            
            return;
        }
    }

    ReallySaveCurrentScenario();
}

function ReallySaveCurrentScenario()
{
    local string Scenario;
    local string Pack;

    Scenario = GetCustomScenario().ScenarioName;
    Pack = GetCustomScenario().PackName;

    CustomScenarioPack.SaveCustomScenario(
            GetCustomScenario(), 
            Scenario, 
            PackPlusExtension(Pack), 
            CustomScenarioCreatorData.ScenariosPath);

    OnActivate();   //return to list
}

private function ConfirmOverwriteExistingScenario( int returnButton, optional string Passback )
{
    if( returnButton == QBTN_Yes )
    {
        ReallySaveCurrentScenario();
    }
}

function SetCheckForOverwrite()
{
    bCheckForOverwrite = true;
}

private function InternalEditScenario(bool NewScenario)
{
	if (!IsClient())
		PopulateFieldsFromScenario(NewScenario);

    OpenInitialTab();
}

function OpenInitialTab()
{
    tabs.OpenTabByIndex(ETabPanels.Tab_Mission);
}

//take the data from GetCustomScenario() and _completely_
//  populate all fields that represent data from the Scenario,
//  including resetting components to their default values if
//  the Scenario doesn't specify their data
function PopulateFieldsFromScenario(bool NewScenario)  //NOTE: NewScenario should ALWAYS be false now, this is a holdover from before
{
    local int i;

    Assert( !NewScenario );

    for (i=0; i<ETabPanels.EnumCount; ++i)
        CustomScenarioTabPanel(tabs.MyTabs[i].TabPanel).PopulateFieldsFromScenario(NewScenario);
}

//take the data from all fields that represent data in the Scenario,
//  and set the related data in GetCustomScenario()
function GatherScenarioFromFields()
{
    local int i;

    for (i=0; i<ETabPanels.EnumCount; ++i)
        CustomScenarioTabPanel(tabs.MyTabs[i].TabPanel).GatherScenarioFromFields();
}

//
// Custom Scneario Creator System support
//

// Scenario Management

function CustomScenario NewCustomScenario()
{
    //TMC TODO This will leak the current CustomScenario if it != None.
    //This should be fine, since it will be cleaned up as soon as the player
    //  starts a mission.  But we could reference count it if necessary.

    CustomScenario = new() class'CustomScenario';
    assert(CustomScenario != None);

    CustomScenarioPack.LoadCustomScenarioInPlace(
            CustomScenario,
            "New Scenario", 
            "Default.pak", 
            "..\\..\\Content\\Classes\\");

    return CustomScenario;
}

function CustomScenario GetCustomScenario()
{
    return CustomScenario;
}


// special function to advance the game state to the point of having selected the scenario on the Play Quick Mission path
function PlayScenario( string ScenarioName, string PackName )
{
    //reset the current pack
    SetCustomScenarioPack( PackName );
    
    //store the selected pack & scenario data
	GC.SetCustomScenarioPackData( CustomScenarioPack, PackPlusExtension( PackName ), PackMinusExtension( PackName ), CustomScenarioCreatorData.ScenariosPath );
    GC.SetScenarioName( ScenarioName );

    //return to main menu
	Controller.CloseMenu(); 

	//Perform the role change
	SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_SP_Custom ); 

    //open Play QM menu
	Controller.OpenMenu("SwatGui.SwatCustomMenu","SwatCustomMenu"); 

    //open Mission Setup menu
	Controller.OpenMenu("SwatGui.SwatMissionSetupMenu","SwatMissionSetupMenu"); 
}


defaultproperties
{
    ConfirmationString="There are unsaved changes.  Are you sure you want to leave and lose those changes?"
    ConfirmOverwriteExistingScenarioString="A scenario named '%1' already exists in pack '%2'.  Are you sure you wish to overwrite it?"
}
