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

    MyBackButton.SetCaption(CampaignString );
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
	if( GC.SwatGameRole != eSwatGameRole.GAMEROLE_SP_Custom && SwatGUIControllerBase(Controller).GetCampaign().CampaignPath == 2)
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
	local EMPMode DesiredMode;

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
				if (GUIController.coopcampaign)
				{
					ServerPanel = SwatCampaignCoopSettingsPanel(MyTabControl.GetTab(3).TabPanel);

					CampaignInfo = 666 ^ 666;
					CampaignPath = GUIController.GetCampaign().CampaignPath;
					MissionIndex = GUIController.GetCampaign().GetAvailableIndex() << 16;
					CampaignInfo = MissionIndex | CampaignPath;

					// Hack to clear the list of disabled referendums
					class'Voting.ReferendumManager'.default.DisabledReferendums.Length = 0;

					DesiredMode = EMPMode.MPM_COOP;

					PlayerController.ServerSetDirty(Settings);
					PlayerController.ServerSetAdminSettings(
						Settings,
						GC.MPName $ " Coop Campaign",
						ServerPanel.MyPasswordBox.VisibleText,
						ServerPanel.MyPasswordedButton.bChecked,
						ServerPanel.MyPublishModeBox.GetIndex() == 0
					);

					PlayerController.ServerSetSettingsNoConfigSave(
						Settings,
						DesiredMode,
						0, // Map index
						1, // Number of rounds
						ServerPanel.MyMaxPlayersSpinner.Value, // Max players
						false,	// Preround start timer
						60, // Post-Round time (Not necessary in campaign CO-OP)
						false, // Postround timer
						10, // Mission ready time (Not necessary in campaign CO-OP)
						true, // Show teammate names
						true, // Not used
						ServerPanel.MyVotingEnabledBox.bChecked, // Allow voting
						true, // No respawning
						true, // Quick round reset
						1, // Friendly fire amount (FIXME: Make this configurable)
						"", // Disabled equipment
						CampaignInfo, // Campaign CO-OP data
						0, // Time between respawns
						false, // No Leaders
						!ServerPanel.MyEnableKillsBox.bChecked,
						true // Add snipers
					);
					if(GC.SwatGameRole == eSwatGameRole.GAMEROLE_SP_Custom)
					{
						PlayerController.ServerSetQMMSettings(Settings,
							GC.CurrentMission.CustomScenario,
							GC.GetCustomScenarioPack(),
							true,
							GUIController.GetCampaign().GetAvailableIndex());
					}
					else
					{
						PlayerController.ServerSetQMMSettings(Settings, None, None, true, 0);
					}
					GC.SaveConfig();

					if(GC.CurrentMission.CustomScenario != None && GC.CurrentMission.CustomScenario.IsCustomMap)
					{	// Custom map in QMM scenario - use the URL
						GUIController.LoadLevel(GC.CurrentMission.CustomScenario.CustomMapURL $ "?listen");
					}
					else
					{
						GUIController.LoadLevel(GC.CurrentMission.Name $ "?listen");
					}
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
