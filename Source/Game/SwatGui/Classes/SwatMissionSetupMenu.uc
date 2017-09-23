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
    if (GC.SwatGameRole != eSwatGameRole.GAMEROLE_SP_Custom && SwatGUIController(Controller).coopcampaign)
	{
		MyLoadoutButton.Hide();
		MyLoadoutButton.DisableComponent();
		MyServerSetupButton.Show();
		MyServerSetupButton.EnableComponent();
	}
	else
	{
		SwatGUIController(Controller).coopcampaign = false;
		MyLoadoutButton.Show();
		MyLoadoutButton.EnableComponent();
		MyServerSetupButton.Hide();
		MyServerSetupButton.DisableComponent();
	}

	if( !bOpeningSubMenu )
        GC.ClearCurrentMission();

    bOpeningSubMenu = false;

    // Megahack to deal with All Campaigns having greyed-out Briefing panel
	if( GC.SwatGameRole != eSwatGameRole.GAMEROLE_SP_Custom &&  SwatGUIControllerBase(Controller).GetCampaign().CampaignPath == 2)
	{
	    MyTabControl.MyTabs[2].TabHeader.DisableComponent();
	}
	else
	{
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
	local SwatCampaignCoopSettingsPanel ServerPanel;
	local SwatGUIController GUIController;
	local SwatPlayerController PlayerController;

	Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
	GUIController = SwatGUIController(Controller);
	PlayerController = SwatPlayerController(PlayerOwner());

	switch (Sender)
	{
	    case MyQuitButton:
            Quit();
            break;
		case MyServerSetupButton:
			MyTabControl.OpenTab(3);
			break;
		case MyStartButton:
            if(GUIController.SPLoadoutPanel == None || GUIController.SPLoadoutPanel.CheckWeightBulkValidity())
			{
				if (GC.SwatGameRole != eSwatGameRole.GAMEROLE_SP_Custom && GUIController.coopcampaign)
				{
					ServerPanel = SwatCampaignCoopSettingsPanel(MyTabControl.GetTab(3).TabPanel);

					CampaignInfo = 666 ^ 666;
					CampaignPath = GUIController.GetCampaign().CampaignPath;
					MissionIndex = GUIController.GetCampaign().GetAvailableIndex() << 16;
					CampaignInfo = MissionIndex | CampaignPath;

					PlayerController.ServerSetDirty(Settings);
					PlayerController.ServerSetAdminSettings(
						Settings,
						GC.MPName $ " Coop Campaign",
						ServerPanel.MyPasswordBox.VisibleText,
						ServerPanel.MyPasswordedButton.bChecked,
						ServerPanel.MyPublishModeBox.GetIndex() == 0
					);
					PlayerController.ServerSetSettings(
						Settings,
						EMPMode.MPM_COOP,
						0, 1, ServerPanel.MyMaxPlayersSpinner.Value, 0, 60, 1, 10,
						true,
						true,
						ServerPanel.MyVotingEnabledBox.bChecked,
						true,
						true,
						1, 1, CampaignInfo, 0,
						false,
						false,
						true
					);
					GC.SaveConfig();
					GUIController.LoadLevel(GC.CurrentMission.Name $ "?listen");
				}
				else
				{
					GameStart();
				}
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
