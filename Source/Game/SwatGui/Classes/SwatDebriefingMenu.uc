// ====================================================================
//  Class:  SwatGui.SwatDebriefingMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatDebriefingMenu extends SwatGUIPage
     ;

import enum eSwatGameRole from SwatGame.SwatGuiConfig;

var(SWATGui) private EditInline Config GUIButton		    MyQuitButton;

var(SWATGui) private EditInline Config GUIButton		    MyContinueButton;
var(SWATGui) private EditInline Config GUIButton		    MyRestartButton;
var(SWATGui) private EditInline Config SwatObjectivesPanel	MyObjectivesPanel;
var(SWATGui) private EditInline Config SwatLeadershipPanel	MyLeadershipPanel;
var(SWATGui) private EditInline Config GUILabel		        MyMissionOutcome;

var(SWATGui) private EditInline Config GUIButton		    MyDebriefingButton;
var(SWATGui) private EditInline Config GUIButton		    MyLoadoutButton;
var(SWATGui) private EditInline Config SwatSPLoadoutPanel   MyLoadoutPanel;
//var(SWATGui) private EditInline Config GUIMultiColumnListBox MyWeaponStats;

var() private config localized string MissionCompletedString;
var() private config localized string MissionFailedString;
var() private config localized string MissionCompletedDifficultyReqFailedString;
var() private config localized string ContinueMissionCompletedString;
var() private config localized string ContinueMissionFailedString;
var() private config localized string MainMenuString;
var() private config localized string ContinueString;

var() bool bOpeningSubMenu;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyContinueButton.OnClick=InternalOnClick;
    MyRestartButton.OnClick=InternalOnClick;
    MyDebriefingButton.OnClick=InternalOnClick;
    MyLoadoutButton.OnClick=InternalOnClick;
}

function InternalOnActivate()
{
    MyQuitButton.OnClick=InternalOnClick;

    //display mission info
    if( !(GC.CurrentMission.IsMissionFailed()) )
    {
        if( GC.CurrentMission.HasMetDifficultyRequirement() )
            MyMissionOutcome.SetCaption( MissionCompletedString );
        else
            MyMissionOutcome.SetCaption( MissionCompletedDifficultyReqFailedString );

        // if playing a quick mission, always "fail" back to the mission select
        if( GC.CurrentMission.CustomScenario != None || !GC.CurrentMission.HasMetDifficultyRequirement() )
            MyContinueButton.SetCaption( ContinueMissionFailedString );
        else
            MyContinueButton.SetCaption( ContinueMissionCompletedString );
    }
    else
    {
        MyMissionOutcome.SetCaption( MissionFailedString );
        MyContinueButton.SetCaption( ContinueMissionFailedString );
    }

    if( GC.SwatGameRole == GAMEROLE_SP_Other )
        MyContinueButton.SetCaption( MainMenuString );

    if( bOpeningSubMenu )
        OpenLoadout();
    else
        OpenDebriefing();

    bOpeningSubMenu = false;
}

function OpenPopup( string ClassName, string ObjName )
{
    bOpeningSubMenu = true;
    Super.OpenPopup( ClassName, ObjName );
}

function OpenDebriefing()
{
    MyObjectivesPanel.Show();
    MyObjectivesPanel.Activate();
    MyLeadershipPanel.Show();
    MyLeadershipPanel.Activate();
    MyLoadoutPanel.Hide();
    MyLoadoutPanel.DeActivate();

    MyMissionOutcome.Show();

    MyDebriefingButton.DisableComponent();
    MyLoadoutButton.EnableComponent();
    if( PlayerOwner().Level.IsTraining )
        MyLoadoutButton.DisableComponent();
}

function OpenLoadout()
{
    MyObjectivesPanel.Hide();
    MyObjectivesPanel.DeActivate();
    MyLeadershipPanel.Hide();
    MyLeadershipPanel.DeActivate();
    MyLoadoutPanel.Show();
    MyLoadoutPanel.Activate();

    MyMissionOutcome.Hide();

    MyDebriefingButton.EnableComponent();
    MyLoadoutButton.DisableComponent();
}

function InternalOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyContinueButton:
	        SwatGUIController(Controller).GameOver();
            break;
		case MyRestartButton:
            if(MyLoadoutPanel.CheckWeightBulkValidity()) {
		            GameStart();
            }
            break;
		case MyDebriefingButton:
		    OpenDebriefing();
            break;
		case MyLoadoutButton:
		    OpenLoadout();
            break;
		case MyQuitButton:
            Quit();
            break;
	}
}

function PerformClose()
{
    //do nothing on this menu
    //SwatGUIController(Controller).GameOver();
}

protected function bool ShouldSetSplashCameraPosition()
{
    return !SwatGamePlayerController(PlayerOwner()).SPBombExploded;
}

defaultproperties
{
    OnActivate=InternalOnActivate

    MissionCompletedString="[c=ffffff]Mission [c=00ff00]Completed[c=ffffff]!"
    MissionCompletedDifficultyReqFailedString="[c=ffffff]Mission [c=ff0000]Completed[c=ffffff]!"
    MissionFailedString="[c=ffffff]Mission [c=ff0000]Failed[c=ffffff]!"
    MainMenuString="MAIN MENU"
    ContinueMissionCompletedString="NEXT MISSION"
    ContinueMissionFailedString="SELECT MISSION"
}
