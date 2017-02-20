// ====================================================================
//  Class:  SwatGui.SwatMissionSetupMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMissionSetupMenu extends SwatGUIPage;

import enum eSwatGameRole from SwatGame.SwatGuiConfig;
import enum EMPMode from Engine.Repo;

var(SWATGui) private EditInline Config GUIButton    MyQuitButton;
var(SWATGui) private EditInline Config GUIButton    MyStartButton;
var(SWATGui) private EditInline Config GUIButton    MyBackButton;
var(SWATGui) private EditInline Config GUIButton    MyMainMenuButton;
var(SWATGui) private EditInline Config GUIButton    MyLoadoutButton;
var(SWATGui) private EditInline Config GUIButton		MyServerSetupButton;
var(SWATGui) private EditInline Config GUITabControl	MyTabControl;

var() private config localized string CampaignString;
var() private config localized string CustomString;

var() bool bOpeningSubMenu;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
}

function InternalOnShow()
{
    MyQuitButton.OnClick=InternalOnClick;
    MyStartButton.OnClick=InternalOnClick;
    MyBackButton.OnClick=InternalOnClick;
    MyMainMenuButton.OnClick=InternalOnClick;
		MyServerSetupButton.OnClick=InternalOnClick;

    if( GC.SwatGameRole == eSwatGameRole.GAMEROLE_SP_Custom )
    {
        MyBackButton.SetCaption(CustomString );
    }
    else
    {
        MyBackButton.SetCaption(CampaignString );
    }
}

function InternalOnActivate()
{
    if (SwatGUIController(Controller).coopcampaign)
	{
		MyLoadoutButton.Hide();
		MyLoadoutButton.DisableComponent();
		MyServerSetupButton.Show();
		MyServerSetupButton.EnableComponent();
	}
	else
	{
		MyLoadoutButton.Show();
		MyLoadoutButton.EnableComponent();
		MyServerSetupButton.Hide();
		MyServerSetupButton.DisableComponent();
	}

	if( !bOpeningSubMenu )
        GC.ClearCurrentMission();

    bOpeningSubMenu = false;

    // Megahack to deal with All Campaigns having greyed-out Briefing panel
    if(SwatGUIControllerBase(Controller).GetCampaign().CampaignPath == 2) {
      MyTabControl.MyTabs[2].TabHeader.DisableComponent();
    } else {
      MyTabControl.MyTabs[2].TabHeader.EnableComponent();
    }
}

function OpenPopup( string ClassName, string ObjName )
{
    bOpeningSubMenu = true;
    Super.OpenPopup( ClassName, ObjName );
}

function InternalOnClick(GUIComponent Sender)
{
	local ServerSettings Settings;
	local float CampaignInfo;
	local int CampaignPath, MissionIndex;
	Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);
	switch (Sender)
	{
	    case MyQuitButton:
            Quit();
            break;
			case MyServerSetupButton:
						MyTabControl.OpenTab(3);
						break;
		case MyStartButton:
            if(SwatGUIController(Controller).SPLoadoutPanel == None || SwatGUIController(Controller).SPLoadoutPanel.CheckWeightBulkValidity()) {
				if (SwatGUIController(Controller).coopcampaign)
				{
					CampaignInfo = 666 ^ 666;
					CampaignPath = SwatGUIController(Controller).GetCampaign().CampaignPath;
					MissionIndex = SwatGUIController(Controller).GetCampaign().GetAvailableIndex() << 16;
					CampaignInfo = MissionIndex | CampaignPath;

					SwatPlayerController(PlayerOwner()).ServerSetSettings(
						Settings,
						EMPMode.MPM_COOP,
						0, 1, 5, 0, 60, 1, 10,
						true, true, false, true, true,
						1, 1, CampaignInfo, 0, false, false, true
					);
					SwatPlayerController(PlayerOwner()).ServerSetAdminSettings(
						Settings,
						GC.MPName $ " Coop Campaign",
						"Coop Campaign",
						false, true
					);
					SwatGUIController(Controller).LoadLevel(GC.CurrentMission.Name $ "?listen");
				}
				else {GameStart();}
            }
            break;
		case MyBackButton:
            Controller.CloseMenu();
            break;
		case MyMainMenuButton:
            DisplayMainMenu();
            break;
	}
}

defaultproperties
{
    OnShow=InternalOnShow
    OnActivate=InternalOnActivate

    CampaignString="CAMPAIGN"
    CustomString="CUSTOM"
}
