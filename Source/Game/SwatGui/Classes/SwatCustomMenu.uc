// ====================================================================
//  Class:  SwatGui.SwatCustomMenu
//  Parent: SwatCustomScenarioPageBase
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatCustomMenu extends SwatCustomScenarioPageBase
     ;

import enum eDifficultyLevel from SwatGame.SwatGUIConfig;


var(SWATGui) private EditInline Config GUIButton		    MyMainMenuButton;
var(SWATGui) private EditInline Config GUIButton		    MyQuitButton;
//greyed out buttons
var(SWATGui) private EditInline Config GUIButton		    CampaignTabButton;
var(SWATGui) private EditInline Config GUIButton		    MissionTabButton;
var(SWATGui) private EditInline Config GUIButton		    BriefingTabButton;
var(SWATGui) private EditInline Config GUIButton		    LoadoutTabButton;
var(SWATGui) private EditInline Config GUIButton		    StartButton;

//load custom
var(SWATGui) private EditInline Config GUIComboBox          MyCustomSelectionBox;
var(SWATGui) private EditInline Config GUIButton		    MyUseCustomButton;

var private bool bRefreshingPaks;

function InitComponent(GUIComponent MyOwner)
{
 	Super.InitComponent(MyOwner);

    MyCustomSelectionBox.OnChange=CustomSelectionChange;

    MyUseCustomButton.OnClick=InternalOnClick;

    MyQuitButton.OnClick=InternalOnClick;
    MyMainMenuButton.OnClick=InternalOnClick;
    
    CampaignTabButton.bNeverFocus=false;
}


////////////////////////////////////////////////////////////////////////////////////
// Component Management
////////////////////////////////////////////////////////////////////////////////////
private function InternalOnActivate()
{
    MyQuitButton.OnClick=InternalOnClick;
    MyMainMenuButton.OnClick=InternalOnClick;

    CampaignTabButton.Focus();
    MissionTabButton.DisableComponent();
    BriefingTabButton.DisableComponent();
    LoadoutTabButton.DisableComponent();
    StartButton.DisableComponent();

    //refresh available paks  
    PopulatePakList();

    //set the current pak
	if( MyCustomSelectionBox.Find( GC.GetPakFriendlyName() ) == "" )
        MyCustomSelectionBox.SetIndex(0);

    //can only load if one already exists    
    MyCustomSelectionBox.SetEnabled( MyCustomSelectionBox.List.ItemCount != 0 );
    MyUseCustomButton.SetEnabled( MyCustomSelectionBox.List.ItemCount != 0 );
}

private function CustomSelectionChange(GUIComponent Sender)
{
	if( bRefreshingPaks )
		return;

    SetCustomScenarioPack( MyCustomSelectionBox.Get() );
}

private function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
	    case MyQuitButton:
            Quit(); 
            break;
		case MyUseCustomButton:
            //set the pak for custom
		    GC.SetCustomScenarioPackData( CustomScenarioPack, PackPlusExtension( MyCustomSelectionBox.Get() ), PackMinusExtension( MyCustomSelectionBox.Get() ), CustomScenarioCreatorData.ScenariosPath );
			Controller.OpenMenu("SwatGui.SwatMissionSetupMenu","SwatMissionSetupMenu"); 
			break;
		case MyMainMenuButton:
            Controller.CloseMenu(); break;
	}
}

////////////////////////////////////////////////////////////////////////////////////
// Custom Mission Pak Management
////////////////////////////////////////////////////////////////////////////////////
private function PopulatePakList()
{
    local int PackIterator;
    local string PackName;
    
    bRefreshingPaks=true;

    RefreshCustomScenarioPackList();

    MyCustomSelectionBox.Clear();
    PackIterator = -1;
    do 
    {
        PackName = PackMinusExtension(NextCustomScenarioPack(PackIterator));
        
        SetCustomScenarioPack( PackName );
        
        if( PackIterator >= 0 &&
            GetPack().GetScenarioCount() > 0 )
        {
            MyCustomSelectionBox.AddItem( PackName );
        }
        
    } until (PackIterator < 0);
    
    bRefreshingPaks=false;
}


defaultproperties
{
	OnActivate=InternalOnActivate
}