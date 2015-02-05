// ====================================================================
//  Class:  SwatGui.SwatServerSetupMenu
//  Parent: SwatGUIPage
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatServerSetupMenu extends SwatGUIPage
     ;

import enum EMPMode from Engine.Repo;

var(SWATGui) EditInline Config GUIButton						MyMainMenuButton;
var(SWATGui) EditInline Config GUIButton						StartButton;
var(SWATGui) EditInline Config GUIButton						MyQuitButton;

var(SWATGui) EditInline Config SwatServerSetupQuickPanel		QuickSetupPanel;
var(SWATGui) EditInline Config SwatServerSetupAdvancedPanel		AdvancedSetupPanel;
var(SWATGui) EditInline Config GUIButton						QuickSetupButton;
var(SWATGui) EditInline Config GUIButton						AdvancedSetupButton;

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

var(SWATGui) EMPMode CurGameType;

var() private config localized string CannotUndercutCurrentPlayersFormatString;
var() private config localized string CannotStartDedicatedServerString;
var() private config localized string HostCDKeyInvalidString;
var() private config localized string StartDedicatedServerQueryString;
var() private config localized string StartServerQueryString;
var() private config localized string ReStartServerQueryString;


function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	QuickSetupPanel.SwatServerSetupMenu = self;
	AdvancedSetupPanel.SwatServerSetupMenu = self;

	QuickSetupButton.OnClick = OnQuickSetupButton;
	AdvancedSetupButton.OnClick = OnAdvancedSetupButton;
	ProfileButton.OnClick = OnProfileButton;

	OnActivate = InternalOnActivate;
}

function OpenQuickSetup()
{
	AdvancedSetupPanel.Hide();
	AdvancedSetupPanel.DeActivate();
	QuickSetupPanel.Show();
	QuickSetupPanel.Activate();
}

function OpenAdvancedSetup()
{
	QuickSetupPanel.Hide();
	QuickSetupPanel.DeActivate();
	AdvancedSetupPanel.Show();
	AdvancedSetupPanel.Activate();
}

function OnQuickSetupButton(GUIComponent Sender)
{
	OpenQuickSetup();
}

function OnAdvancedSetupButton(GUIComponent Sender)
{
	OpenAdvancedSetup();
}

function OnProfileButton(GUIComponent Sender)
{
	Controller.OpenMenu( "SwatGui.SwatGamespyProfilePopup", "SwatGamespyProfilePopup" );
}

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
                // Dan, here is where we are checking the host's CD key and
                // should display a dialog if the key is not valid.
                if ( !bUseGameSpy || SGSM.IsHostCDKeyValid() )
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
                else
                {
                    OpenDlg( HostCDKeyInvalidString, QBTN_Cancel, "HostCDKeyInvalid" );
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
    bIsAdmin = ( GC.SwatGameRole == GAMEROLE_MP_Host ) || SwatPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo).IsAdmin();

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
}

function SaveServerSettings()
{
    local ServerSettings Settings;
    local float EnemyFireAmount;

    //
    // Save to the pending server settings
    //
    Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);

	QuickSetupPanel.SaveServerSettings();
	AdvancedSetupPanel.SaveServerSettings();

    //
    // Update the modifiers based on checkbox value
    //
    if( AdvancedSetupPanel.MyEnemyFireButton.bChecked )
        EnemyFireAmount = 0.0;
    else
        EnemyFireAmount = 1.0;

    //
    // Set all server settings
    //
    SwatPlayerController(PlayerOwner()).ServerSetSettings( Settings,
                                CurGameType,
                                QuickSetupPanel.SelectedIndex,
                                QuickSetupPanel.MyRoundsBox.Value,
                                AdvancedSetupPanel.MyMaxPlayersBox.Value,
                                QuickSetupPanel.MyDeathLimitBox.Value,
                                AdvancedSetupPanel.MyPostGameTimeLimitBox.Value,
                                QuickSetupPanel.MyTimeLimitBox.Value,
                                AdvancedSetupPanel.MyPreGameTimeLimitBox.Value,
                                AdvancedSetupPanel.MyShowTeammatesButton.bChecked,
                                AdvancedSetupPanel.MyShowEnemyButton.bChecked,
								AdvancedSetupPanel.MyAllowReferendumsButton.bChecked,
                                QuickSetupPanel.MyNoRespawnButton.bChecked,
                                QuickSetupPanel.MyQuickResetBox.bChecked,
                                AdvancedSetupPanel.MyFriendlyFireSlider.GetValue(),
                                EnemyFireAmount,
								AdvancedSetupPanel.MyArrestRoundTimeDeductionBox.Value,
								AdvancedSetupPanel.MyAdditionalRespawnTimeBox.Value,
								!AdvancedSetupPanel.MyEnableLeadersCheck.bChecked,
								AdvancedSetupPanel.MyEnableStatsCheck.bChecked,
								!AdvancedSetupPanel.MyEnableTeamSpecificWeapons.bChecked );
    
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

                if ( bUseGameSpy )
                {
                    // MCJ: we have to tell the GameSpyManager whether we're
                    // doing a LAN game or an Internet game, since it
                    // currently can't figure it out on it's own.
                    SGSM.SetShouldCheckClientCDKeys( true );
                }
                else
                {
                    SGSM.SetShouldCheckClientCDKeys( false );
                }

                SaveServerSettings();
                LoadSelectedMap();
            }
            break;
        case "RestartServer":
            if( Selection == QBTN_Ok )
            {
                if ( bUseGameSpy )
                {
                    // MCJ: we have to tell the GameSpyManager whether we're
                    // doing a LAN game or an Internet game, since it
                    // currently can't figure it out on it's own.
                    SGSM.SetShouldCheckClientCDKeys( true );
                }
                else
                {
                    SGSM.SetShouldCheckClientCDKeys( false );
                }
                SaveServerSettings();

				if (CurGameType == MPM_COOPQMM)
					LoadSelectedMap();
				else
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
    local String URL;
	
	// Load the Coop-QMM lobby map if the game type is Coop-QMM, else load the selected map
	if (CurGameType == MPM_COOPQMM)
		URL = "CoopQMMLobby";
	else
		URL = QuickSetupPanel.SelectedMaps.List.GetItemAtIndex(QuickSetupPanel.SelectedIndex);

    URL = URL $ "?Name=" $ QuickSetupPanel.MyNameBox.GetText() $ "?listen";

    if (QuickSetupPanel.MyPasswordedButton.bChecked)
    {
        URL = URL$"?GamePassword="$QuickSetupPanel.MyPasswordBox.GetText();
    }

    SwatGUIController(Controller).LoadLevel(URL); 
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
        (!QuickSetupPanel.SelectedMaps.IsEmpty() || CurGameType == MPM_COOPQMM) &&
        QuickSetupPanel.MyNameBox.GetText() != "" &&
        QuickSetupPanel.MyServerNameBox.GetText() != "" &&
        ( QuickSetupPanel.MyPasswordBox.GetText() != "" || 
          !QuickSetupPanel.MyPasswordedButton.bChecked );
          
    StartButton.SetEnabled( bEnableStart );
    ProfileButton.SetEnabled( bUseGameSpy );
    
    if( bInGame )
        MyQuitButton.SetEnabled( bEnableStart );

	QuickSetupPanel.DoRefreshEnabled();
	AdvancedSetupPanel.DoRefreshEnabled();
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

    HostCDKeyInvalidString="Invalid CD Key!"	
    StartDedicatedServerQueryString="Quit the game and launch a dedicated server with the current settings?"
	StartServerQueryString="Start the server?"
	ReStartServerQueryString="Restart the server with the current settings?"

    CannotStartDedicatedServerString="Cannot start dedicated server. A SWAT4 dedicated server is already running on this machine."
    CannotUndercutCurrentPlayersFormatString="Cannot proceed.  The maximum number of players (%1) cannot be less than the current number of players (%2).  Please increase the Max Players value and try again."
}