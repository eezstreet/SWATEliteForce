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
var(SWATGui) private EditInline COnfig GUIComboBox			MyEntranceSelectBox;

var(SWATGui) private EditInline Config GUIButton		    MyDebriefingButton;
var(SWATGui) private EditInline Config GUIButton		    MyLoadoutButton;
var(SWATGui) private EditInline Config SwatSPLoadoutPanel   MyLoadoutPanel;
//var(SWATGui) private EditInline Config GUIMultiColumnListBox MyWeaponStats;

var() private config localized string MissionCompletedString;
var() private config localized string MissionFailedString;
var() private config localized string MissionCompletedDifficultyReqFailedString;
var() private config localized string ContinueMissionCompletedString;
var() private config localized string ContinueMissionFailedString;
var() private config localized string ContinueMissionEndCampaignString;
var() private config localized string MainMenuString;
var() private config localized string ContinueString;

var() private config localized string PrimaryEntranceString;
var() private config localized string SecondaryEntranceString;

var() bool bOpeningSubMenu;
var() bool bPopulatingEntrances;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyContinueButton.OnClick=InternalOnClick;
    MyRestartButton.OnClick=InternalOnClick;
    MyDebriefingButton.OnClick=InternalOnClick;
    MyLoadoutButton.OnClick=InternalOnClick;
	MyEntranceSelectBox.OnChange=InternalOnChange;
}

function InternalOnChange(GUIComponent Sender)
{
	switch(Sender)
	{
		case MyEntranceSelectBox:
			if(!bPopulatingEntrances)
			{
				if(MyEntranceSelectBox.GetInt() == 0)
				{
					GC.SetDesiredEntryPoint(ET_Primary);
				}
				else if(MyEntranceSelectBox.GetInt() == 1)
				{
					GC.SetDesiredEntryPoint(ET_Secondary);
				}
			}
			break;
	}
}

function InternalOnActivate()
{
    local Campaign theCampaign;

    MyQuitButton.OnClick=InternalOnClick;

    theCampaign = SwatGUIController(Controller).GetCampaign();

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

        if(theCampaign.HardcoreMode) {
            MyContinueButton.SetCaption(ContinueMissionEndCampaignString);
        } else if(theCampaign.PlayerPermadeath && theCampaign.PlayerDied) {
          MyContinueButton.SetCaption(ContinueMissionEndCampaignString);
        } else {
          MyContinueButton.SetCaption( ContinueMissionFailedString );
        }
    }

	bPopulatingEntrances = true;
	MyEntranceSelectBox.Clear();
	MyEntranceSelectBox.AddItem(PrimaryEntranceString, , , 0);
	MyEntranceSelectBox.AddItem(SecondaryEntranceString, , , 1);
	bPopulatingEntrances = false;

	if(GC.GetDesiredEntryPoint() == ET_Primary)
	{
		MyEntranceSelectBox.SetIndex(0);
	}
	else
	{
		MyEntranceSelectBox.SetIndex(1);
	}

    MyRestartButton.SetEnabled(true);
    MyLoadoutButton.SetEnabled(true);

    if(GC.CurrentMission.IsMissionFailed()) {
        if((theCampaign.PlayerPermadeath && theCampaign.PlayerDied) || theCampaign.HardcoreMode) {
            MyRestartButton.SetEnabled(false);
            MyLoadoutButton.SetEnabled(false);
            MyEntranceSelectBox.DisableComponent();
        }
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
	{
		MyLoadoutButton.DisableComponent();
		MyEntranceSelectBox.DisableComponent();
	}
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
    ContinueMissionEndCampaignString="END CAMPAIGN"

	PrimaryEntranceString="Primary Entrance"
	SecondaryEntranceString="Secondary Entrance"
}
