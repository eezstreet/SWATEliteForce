// ====================================================================
//  Class:  SwatGui.SwatServerSetupMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatServerSetupMenu extends SwatGUIPage
     dependsOn(SwatAdmin);

import enum EMPMode from Engine.Repo;
import enum AdminPermissions from SwatGame.SwatAdmin;

var(SWATGui) EditInline Config GUIButton						MyMainMenuButton;
var(SWATGui) EditInline Config GUIButton						StartButton;
var(SWATGui) EditInline Config GUIButton						MyQuitButton;

var(SWATGui) EditInline Config SwatServerSetupQuickPanel		QuickSetupPanel;
var(SWATGui) EditInline Config SwatServerSetupAdvancedPanel		AdvancedSetupPanel;
var(SWATGui) EditInline Config SwatServerSetupAdminPanel		AdminPanel;
var(SWATGui) EditInline Config SwatServerSetupVotingPanel		VotingPanel;
var(SWATGui) EditInline Config SwatServerSetupEquipmentPanel	EquipmentPanel;
var(SWATGui) EditInline Config GUIButton						QuickSetupButton;
var(SWATGui) EditInline Config GUIButton						AdvancedSetupButton;
var(SWATGui) EditInline Config GUIButton						AdminButton;
var(SWATGui) EditInline Config GUIButton						VotingButton;
var(SWATGui) EditInline Config GUIButton						EquipmentButton;

var(SWATGui) EditInline Config GUIButton						ProfileButton;

var() private config localized string BackButtonHelpString;
var() private config localized string CancelButtonHelpString;
var() private config localized string QuitButtonHelpString;
var() private config localized string AcceptButtonHelpString;
var() private config localized string StartButtonHelpString;
var() private config localized string ReStartButtonHelpString;

var() private config localized string BackButtonString;
var() private config localized string CancelButtonString;
var() private config localized string QuitButtonString;
var() private config localized string AcceptButtonString;
var() private config localized string StartButtonString;
var() private config localized string ReStartButtonString;

var(DEBUG) SwatGameSpyManager SGSM;
var(DEBUG) bool bUseGameSpy;
var(DEBUG) bool bInGame;
var(DEBUG) bool bIsAdmin;
var(DEBUG) bool bQMM;

var() private config localized string CannotUndercutCurrentPlayersFormatString;
var() private config localized string CannotStartDedicatedServerString;
var() private config localized string StartDedicatedServerQueryString;
var() private config localized string StartServerQueryString;
var() private config localized string ReStartServerQueryString;


function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	QuickSetupPanel.SwatServerSetupMenu = self;
	AdvancedSetupPanel.SwatServerSetupMenu = self;
	AdminPanel.SwatServerSetupMenu = self;
	VotingPanel.SwatServerSetupMenu = self;
	EquipmentPanel.SwatServerSetupMenu = self;

	QuickSetupButton.OnClick = OnQuickSetupButton;
	AdvancedSetupButton.OnClick = OnAdvancedSetupButton;
	ProfileButton.OnClick = OnProfileButton;
	AdminButton.OnClick = OnAdminButton;
	VotingButton.OnClick = OnVotingButton;
	EquipmentButton.OnClick = OnEquipmentButton;

	OnActivate = InternalOnActivate;
}

function OpenQuickSetup()
{
	AdvancedSetupPanel.Hide();
	AdvancedSetupPanel.DeActivate();
	AdminPanel.Hide();
	AdminPanel.DeActivate();
	QuickSetupPanel.Show();
	QuickSetupPanel.Activate();
	VotingPanel.Hide();
	VotingPanel.DeActivate();
	EquipmentPanel.Hide();
	EquipmentPanel.DeActivate();
}

function OpenAdvancedSetup()
{
	QuickSetupPanel.Hide();
	QuickSetupPanel.DeActivate();
	AdminPanel.Hide();
	AdminPanel.DeActivate();
	AdvancedSetupPanel.Show();
	AdvancedSetupPanel.Activate();
	VotingPanel.Hide();
	VotingPanel.DeActivate();
	EquipmentPanel.Hide();
	EquipmentPanel.DeActivate();
}

function OpenAdmin()
{
	QuickSetupPanel.Hide();
	QuickSetupPanel.DeActivate();
	AdvancedSetupPanel.Hide();
	AdvancedSetupPanel.DeActivate();
	AdminPanel.Show();
	AdminPanel.Activate();
	VotingPanel.Hide();
	VotingPanel.DeActivate();
	EquipmentPanel.Hide();
	EquipmentPanel.DeActivate();
}

function OpenVoting()
{
	QuickSetupPanel.Hide();
	QuickSetupPanel.DeActivate();
	AdvancedSetupPanel.Hide();
	AdvancedSetupPanel.DeActivate();
	AdminPanel.Hide();
	AdminPanel.DeActivate();
	VotingPanel.Show();
	VotingPanel.Activate();
	EquipmentPanel.Hide();
	EquipmentPanel.DeActivate();
}

function OpenEquipment()
{
	QuickSetupPanel.Hide();
	QuickSetupPanel.DeActivate();
	AdvancedSetupPanel.Hide();
	AdvancedSetupPanel.DeActivate();
	AdminPanel.Hide();
	AdminPanel.DeActivate();
	VotingPanel.Hide();
	VotingPanel.DeActivate();
	EquipmentPanel.Show();
	EquipmentPanel.Activate();
}

function OnQuickSetupButton(GUIComponent Sender)
{
	OpenQuickSetup();
}

function OnAdvancedSetupButton(GUIComponent Sender)
{
	OpenAdvancedSetup();
}

function OnAdminButton(GUIComponent Sender)
{
	OpenAdmin();
}

function OnVotingButton(GUIComponent Sender)
{
	OpenVoting();
}

function OnEquipmentButton(GUIComponent Sender)
{
	OpenEquipment();
}

function OnProfileButton(GUIComponent Sender)


function InternalOnClick(GUIComponent Sender)
{
    local int MaxPlayers, CurrentPlayers;

    MaxPlayers = AdvancedSetupPanel.MyMaxPlayersBox.Value;
    CurrentPlayers = SwatGameReplicationInfo(PlayerOwner().GameReplicationInfo).NumPlayers();

	switch (Sender)
	{
	    case MyQuitButton:
	        if( bInGame && MaxPlayers < CurrentPlayers )
	        {
	            OpenDlg( FormatTextString( CannotUndercutCurrentPlayersFormatString, MaxPlayers, CurrentPlayers ), QBTN_OK, "IncreaseMaxPlayers" );
	            break;
	        }
    		SaveServerSettings();
		    //if in-game, accept and return
		    if( bInGame )
            {
                Controller.CloseMenu();
            }
            else
                Quit();
            break;
		case StartButton:
	        if( bInGame && MaxPlayers < CurrentPlayers )
	        {
	            OpenDlg( FormatTextString( CannotUndercutCurrentPlayersFormatString, MaxPlayers, CurrentPlayers ), QBTN_OK, "IncreaseMaxPlayers" );
	            break;
	        }

		    OnDlgReturned=InternalOnDlgReturned;
		    if( bInGame )
            {
        		OpenDlg( ReStartServerQueryString, QBTN_OkCancel, "RestartServer" );
            }
            else
            {
                    if( AdvancedSetupPanel.MyDedicatedServerCheck.bChecked )
                    {
                        // Dan, here's the check to use.
                        log( "mcj CanLaunchDedicatedServer="$Controller.CanLaunchDedicatedServer() );
                        if ( Controller.CanLaunchDedicatedServer() )
                            OpenDlg( StartDedicatedServerQueryString, QBTN_OkCancel, "StartDedicatedServer" );
                        else
                            OpenDlg( CannotStartDedicatedServerString, QBTN_Ok, "CannotStartDedicatedServer" );
                    }
                    else
                    {
            		    OpenDlg( StartServerQueryString, QBTN_OkCancel, "StartServer" );
                    }
            }
            break;
		case MyMainMenuButton:
            //only save on back, not cancel
		    if( !bInGame && !QuickSetupPanel.SelectedMaps.IsEmpty() )
            {
    		    SaveServerSettings();
            }
            Controller.CloseMenu();
            break;
	}
}

function InternalOnActivate()
{
    MyQuitButton.OnClick=InternalOnClick;
    MyMainMenuButton.OnClick=InternalOnClick;
    StartButton.OnClick=InternalOnClick;

	SGSM = SwatGameSpyManager(PlayerOwner().Level.GetGameSpyManager());
	if (SGSM == None)
	{
		Log("Error:  no GameSpy manager found");
	}

	OpenQuickSetup();

	ProfileButton.Hide();
}

event HandleParameters(string Param1, string Param2, optional int param3)
{
    Super.HandleParameters( Param1, Param2, param3 );

    //if param1 == InGame, this is to be opened as an in game screen - special options apply
    bInGame = ( Param1 == "InGame" );
    bIsAdmin = ( GC.SwatGameRole == GAMEROLE_MP_Host ) ||
		SwatPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).MyRights[AdminPermissions.Permission_ChangeSettings] > 0;

    StartButton.Hint = StartButtonHelpString;
    MyQuitButton.Hint = QuitButtonHelpString;
    MyMainMenuButton.Hint = BackButtonHelpString;

    StartButton.SetCaption( StartButtonString );
    MyQuitButton.SetCaption( QuitButtonString );
    MyMainMenuButton.SetCaption( BackButtonString );

    if( bInGame )
    {
        StartButton.Hint = ReStartButtonHelpString;
        MyQuitButton.Hint = AcceptButtonHelpString;
        MyMainMenuButton.Hint = CancelButtonHelpString;

        StartButton.SetCaption( ReStartButtonString );
        MyQuitButton.SetCaption( AcceptButtonString );
        MyMainMenuButton.SetCaption( CancelButtonString );
    }

	QuickSetupPanel.HandleParameters( Param1, Param2, Param3 );
	AdvancedSetupPanel.HandleParameters( Param1, Param2, Param3 );
	AdminPanel.HandleParameters( Param1, Param2, Param3 );
	VotingPanel.HandleParameters( Param1, Param2, Param3 );
	EquipmentPanel.HandleParameters( Param1, Param2, Param3 );
}

function SaveServerSettings()
{
    local ServerSettings Settings;

    //
    // Save to the pending server settings
    //
    Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);

	QuickSetupPanel.SaveServerSettings();
	AdvancedSetupPanel.SaveServerSettings();
	EquipmentPanel.SaveServerSettings();
	AdminPanel.SaveServerSettings();
	VotingPanel.SaveServerSettings();

    //
    // Set all server settings
    //
    SwatPlayerController(PlayerOwner()).ServerSetSettings( Settings,
                                EMPMode.MPM_COOP,
                                QuickSetupPanel.SelectedIndex,
                                QuickSetupPanel.MyRoundsBox.Value,
                                AdvancedSetupPanel.MyMaxPlayersBox.Value,
                                AdvancedSetupPanel.MyRoundStartTimerCheck.bChecked,
                                AdvancedSetupPanel.MyPostGameTimeLimitBox.Value,
                                AdvancedSetupPanel.MyRoundEndTimerCheck.bChecked,
                                AdvancedSetupPanel.MyPreGameTimeLimitBox.Value,
                                AdvancedSetupPanel.MyShowTeammatesButton.bChecked,
                                false, // Not used
								VotingPanel.MyVotingEnabledBox.bChecked,
                                QuickSetupPanel.MyNoRespawnButton.bChecked,
                                QuickSetupPanel.MyQuickResetBox.bChecked,
                                AdvancedSetupPanel.MyFriendlyFireSlider.GetValue(),
                                EquipmentPanel.GetDisabledEquipmentClasses(),
								-1^0,
								AdvancedSetupPanel.MyAdditionalRespawnTimeBox.Value,
								!AdvancedSetupPanel.MyEnableLeadersCheck.bChecked,
								!AdvancedSetupPanel.MyEnableKillMessagesCheck.bChecked,
								AdvancedSetupPanel.MyEnableSnipers.bChecked);
	SwatPlayerController(PlayerOwner()).ServerSetQMMSettings(Settings,
		None,
		None,
		false,
		0);
    GC.SaveConfig();
}

function InternalOnDlgReturned( int Selection, String passback )
{
    switch (passback)
    {
        case "StartDedicatedServer":
            if( Selection == QBTN_Ok )
            {
                SaveServerSettings();
                LaunchDedicatedServer();
            }
            break;
        case "StartServer":
            if( Selection == QBTN_Ok )
            {
                GC.FirstTimeThrough = true;
                SGSM.SetShouldCheckClientCDKeys( false );

                SaveServerSettings();
                LoadSelectedMap();
            }
            break;
        case "RestartServer":
            if( Selection == QBTN_Ok )
            {
                SGSM.SetShouldCheckClientCDKeys( false );
                SaveServerSettings();
				SwatPlayerController(PlayerOwner()).ServerQuickRestart();
            }
            break;
    }
}

private final function LaunchDedicatedServer()
{
    FlushConfig();
    Controller.LaunchDedicatedServer();
}

///////////////////////////////////////////////////////////////////////////
// Start & Restart: Load a map
///////////////////////////////////////////////////////////////////////////
private function LoadSelectedMap()
{
    QuickSetupPanel.BootUpSelectedMap();
}

function ResetDefaultsForGameMode( EMPMode NewMode )
{
	QuickSetupPanel.DoResetDefaultsForGameMode( NewMode );
	AdvancedSetupPanel.DoResetDefaultsForGameMode( NewMode );
}

function RefreshEnabled()
{
    local bool bEnableStart;

    bEnableStart = bIsAdmin &&
        !QuickSetupPanel.SelectedMaps.IsEmpty() &&
        QuickSetupPanel.MyNameBox.GetText() != "" &&
        QuickSetupPanel.MyServerNameBox.GetText() != "" &&
        ( QuickSetupPanel.MyPasswordBox.GetText() != "" ||
          !QuickSetupPanel.MyPasswordedButton.bChecked );

    StartButton.SetEnabled( bEnableStart );
    ProfileButton.SetEnabled( bUseGameSpy );

    if( bInGame )
        MyQuitButton.SetEnabled( bEnableStart );

	QuickSetupPanel.DoRefreshEnabled();
}

function string GetSelectedLessLethalName()
{
	return EquipmentPanel.MyLessLethalBox.GetExtra();
}

defaultproperties
{
	StartButtonString="START SERVER"
	ReStartButtonString="RESTART SERVER"
	BackButtonString="MAIN"
	CancelButtonString="CANCEL"
	QuitButtonString="QUIT"
	AcceptButtonString="APPLY"

	StartButtonHelpString="Start the server with the current settings."
	ReStartButtonHelpString="Restart the server with the current settings."
	BackButtonHelpString="Return to the Main Menu."
	CancelButtonHelpString="Discard changes and return to the previous menu."
	QuitButtonHelpString="Exit the game and return to Windows."
	AcceptButtonHelpString="Apply the current settings and return to the previous menu."

    StartDedicatedServerQueryString="Quit the game and launch a dedicated server with the current settings?"
	StartServerQueryString="Start the server?"
	ReStartServerQueryString="Restart the server with the current settings?"

    CannotStartDedicatedServerString="Cannot start dedicated server. A SWAT4 dedicated server is already running on this machine."
    CannotUndercutCurrentPlayersFormatString="Cannot proceed.  The maximum number of players (%1) cannot be less than the current number of players (%2).  Please increase the Max Players value and try again."
}
