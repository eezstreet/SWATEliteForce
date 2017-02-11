// ====================================================================
//  Class:  SwatGui.SwatMainMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMainMenu extends SwatGUIPage
     ;

var(SWATGui) private EditInline Config GUIButton		    MyInstantActionButton;
var(SWATGui) private EditInline Config GUIButton		    MyTrainingButton;
var(SWATGui) private EditInline Config GUIButton		    MyCampaignButton;
var(SWATGui) private EditInline Config GUIButton		    MyCoopCampaignButton;
var(SWATGui) private EditInline Config GUIButton		    MyPlayCustomButton;
var(SWATGui) private EditInline Config GUIButton		    MyCustomMissionButton;
var(SWATGui) private EditInline Config GUIButton		    MyHostButton;
var(SWATGui) private EditInline Config GUIButton		    MyJoinButton;
var(SWATGui) private EditInline Config GUIButton		    MyGameSettingsButton;
var(SWATGui) private EditInline Config GUIButton		    MyCreditsButton;
var(SWATGui) private EditInline Config GUIButton		    MyQuitButton;

var() private config localized string TrainingFriendlyString;

var() private config localized string PromptToGotoTrainingFirstString;
var() private config localized string ConfirmNoTrainingString;

function InitComponent(GUIComponent MyOwner)
{
    local int i;

	Super.InitComponent(MyOwner);

    MyInstantActionButton.OnClick=InternalOnClick;
    MyTrainingButton.OnClick=InternalOnClick;
    MyCampaignButton.OnClick=InternalOnClick;
    MyCoopCampaignButton.OnClick=InternalOnClick;
    MyPlayCustomButton.OnClick=InternalOnClick;
    MyCustomMissionButton.OnClick=InternalOnClick;
    MyHostButton.OnClick=InternalOnClick;
    MyJoinButton.OnClick=InternalOnClick;
    MyGameSettingsButton.OnClick=InternalOnClick;
    MyCreditsButton.OnClick=InternalOnClick;

    for( i = 0; i < Controls.Length; i++ )
        Controls[i].ShowPositionDelay = -1.0;
}

function InternalOnActivate()
{
    local int i;

    for( i = 0; i < Controls.Length; i++ )
        Controls[i].ShowPositionDelay = -1.0;

    MyQuitButton.OnClick=InternalOnClick;

    //ensure we are displaying help text if appropriate
    Controller.bDontDisplayHelpText = !GC.bShowHelp;
    if( GC.SwatGameState == GAMESTATE_None )
    	SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_None );
		
	SwatGUIController(Controller).coopcampaign = false;
}

function InternalOnDlgReturned( int Selection, optional string Passback )
{
    switch (passback)
    {
        case "FirstTrainingPrompt":
            if( Selection == QBTN_Yes )
            {
                OpenDlg( ConfirmNoTrainingString, QBTN_YesNo, "LastTrainingPrompt" );
            }
            break;
        case "LastTrainingPrompt":
            if( Selection == QBTN_Yes )
            {
                //continue to load into the campaign, training was intentionally skipped by this player
                GC.bEverRanTraining = true;
                GC.SaveConfig();

                SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_SP_Campaign );
			    Controller.OpenMenu("SwatGui.SwatCampaignMenu", "SwatCampaignMenu");
            }
            break;
    }
}


function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyInstantActionButton:
			//Ryan: Training is not used in the expansion pack
		    //if you have never played or clicked through training
            if( !GC.bEverRanTraining )
            {
                //play training first
                GC.bEverRanTraining = true;
                GC.SaveConfig();

                GC.SetCurrentMission( 'SP-Training', TrainingFriendlyString );
                GameStart();
            }
            else
            {
              SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_SP_Other );
              GameStart();
		        }

            break;
		case MyTrainingButton:
            GC.bEverRanTraining = true;
            SwatGuiController(Controller).Repo.RoleChange(GAMEROLE_SP_Other);
            GC.SetCurrentMission('SP-Training', TrainingFriendlyString);
            GameStart();
            break;
		case MyCoopCampaignButton:
			SwatGuiController(Controller).coopcampaign = true;
			PlayCampaign();
			break;
		case MyCampaignButton:
			SwatGuiController(Controller).coopcampaign = false;
			PlayCampaign();
			break;
		case MyPlayCustomButton:
            SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_SP_Custom );
			Controller.OpenMenu("SwatGui.SwatCustomMenu", "SwatCustomMenu");
			break;
		case MyCustomMissionButton:
            //todo, remove when chage over
//            SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_SP_Custom );
			Controller.OpenMenu("SwatGui.CustomScenarioPage", "CustomScenarioPage");
			break;
		case MyHostButton:
            SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_MP_Host );
			Controller.OpenMenu("SwatGui.SwatServerSetupMenu", "SwatServerSetupMenu");
			break;
		case MyJoinButton:
            SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_MP_Client );
			Controller.OpenMenu("SwatGui.SwatServerBrowserMenu", "SwatServerBrowserMenu");
			break;
		case MyGameSettingsButton:
			Controller.OpenMenu("SwatGui.SwatGameSettingsMenu", "SwatGameSettingsMenu");
			break;
		case MyCreditsButton:
			Controller.OpenMenu("SwatGui.SwatCreditsMenu", "SwatCreditsMenu");
			break;
		case MyQuitButton:
            Quit();
            break;
	}
}

function PlayCampaign()
{
	// dbeswick: no training for expansion
    //if you have never played or clicked through training
    if( !GC.bEverRanTraining )
    {
        OnDlgReturned=InternalOnDlgReturned;
        OpenDlg( PromptToGotoTrainingFirstString, QBTN_YesNo, "FirstTrainingPrompt" );
    }
    else
    {
        SwatGuiController(Controller).Repo.RoleChange( GAMEROLE_SP_Campaign );
	    Controller.OpenMenu("SwatGui.SwatCampaignMenu", "SwatCampaignMenu");
	}
}

function PerformClose()
{
    Quit();
}

defaultproperties
{
    OnActivate=InternalOnActivate

	TrainingFriendlyString="Training"
	StyleName="STY_MainMenu"

	PromptToGotoTrainingFirstString="SWAT (R) 4 requires challenging squad-based tactics and compliance with law-enforcement procedures. It is [b]strongly[\\b] recommended that you play the training mission before attempting other SWAT engagements. Continue anyway?"
	ConfirmNoTrainingString="Are you sure that you do not want to play the training mission?"
}
