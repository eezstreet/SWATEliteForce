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
	local SwatCampaignCoopSettingsPanel ServerPanel;

	Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

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
					ServerPanel = SwatCampaignCoopSettingsPanel(MyTabControl.GetTab(3).TabPanel);

					CampaignInfo = 666 ^ 666;
					CampaignPath = SwatGUIController(Controller).GetCampaign().CampaignPath;
					MissionIndex = SwatGUIController(Controller).GetCampaign().GetAvailableIndex() << 16;
					CampaignInfo = MissionIndex | CampaignPath;

					SwatPlayerController(PlayerOwner()).ServerSetDirty(Settings);
					SwatPlayerController(PlayerOwner()).ServerSetAdminSettings(
						Settings,
						GC.MPName $ " Coop Campaign",
						ServerPanel.MyPasswordBox.VisibleText,
						ServerPanel.MyPasswordedButton.bChecked,
						ServerPanel.MyPublishModeBox.GetIndex() == 0
					);
					SwatPlayerController(PlayerOwner()).ServerSetSettings(
						Settings,
						EMPMode.MPM_COOP,
						0, // Map index
						1, // Number of rounds
						ServerPanel.MyMaxPlayersSpinner.Value, // Max players
						0, // Unused
						60, // Post-Round time (Not necessary in campaign CO-OP)
						1, // Unused
						10, // Mission ready time (Not necessary in campaign CO-OP)
						true, // Show teammate names
						true, // Not used
						true, // Allow voting
						true, // No respawning
						true, // Quick round reset
						1, // Friendly fire amount (FIXME: Make this configurable)
						1, // Not used
						CampaignInfo, // Campaign CO-OP data
						0, // Time between respawns
						false, // No Leaders
						false, // Not used
						true // Add snipers
					);
					GC.SaveConfig();
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
