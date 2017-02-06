// ====================================================================
//  Class:  SwatGui.SwatMPPage
//  Parent: SwatPopupMenuBase
//
//  Menu to load map from entry screen.
// ====================================================================

class SwatMPPage extends SwatPopupMenuBase
    ;

import enum EInputKey from Engine.Interactions;
import enum EInputAction from Engine.Interactions;
import enum EMPMode from Engine.Repo;

var(SWATGui) private EditInline Config GUILabel MyServerNameLabel;
var(SWATGui) private EditInline Config GUILabel MyWaitingForPlayersLabel;

var(SWATGui) private EditInline Config GUIImage MyLoadingGraphic;
var(SWATGui) private EditInline Config GUIImage MyLoadingBlackGraphic;
var(SWATGui) private EditInline Config GUILabel MyLoadingTextLabel;

var(SWATGui) private EditInline Config GUILabel MyBombsRemainingLabel;
var(SWATGui) private EditInline Config GUILabel MyRoundsLabel;

var(SWATGui) private EditInline Config GUIButton MyStartButton;
var(SWATGui) private EditInline Config GUIButton MyBackButton;

var(SWATGui) private EditInline Config GUIButton MyLoadoutButton;
var(SWATGui) private EditInline Config GUIButton MyScoresButton;
var(SWATGui) private EditInline Config GUIButton MyVotingButton;

var(SWATGui) private EditInline Config SwatMPLoadoutPanel  MyMPLoadoutPanel;
var(SWATGui) private EditInline Config SwatMPScoresPanel  MyMPScoresPanel;
var(SWATGui) private EditInline Config SwatMPVotingPanel  MyMPVotingPanel;

var(SWATGui) private EditInline Config GUIButton		    MyGameSettingsButton;
var(SWATGui) private EditInline Config GUIButton		    MyServerSettingsButton;

var(SWATGui) private EditInline Config GUILabel MyGameInfoLabel;
var(SWATGui) private EditInline Config GUIScrollTextBox MyServerInfoBox;
var(SWATGui) private EditInline Config SwatChatPanel  MyChatPanel;

var(SWATGui) private localized config String BombsRemaining;
var(SWATGui) private localized config String RoundsRemainingString;
var(SWATGui) private localized config String ReadyString;
var(SWATGui) private localized config String UnreadyString;
var(SWATGui) private localized config String ContinueString;
var(SWATGui) private localized config String GameModeAndLevelString;

#if IG_SWAT_PROGRESS_BAR
var(SWATGui) private EditInline config GUILabel MissionLoadingStatusText;
var(SWATGui) private EditInline config GUIProgressBar MissionLoadingProgressBar;

var() private config localized string LoadSplashString;
var() private config localized string WaitForConnectionString;
var() private config localized string LoadMapString;
var() private config localized string DownloadString;
#endif

var(SWATGui) private EditInline Config GUIImage         LoadingImage;
var(SWATGui) private            config array<Material>  DefaultImages;

var() private config localized string ConfirmAbortString;
var() private config localized string WaitingForPlayersString;

var private EMPMode CachedGameMode;
var private string CachedTitle;
var private bool bPressedReady;

////////////////////////////////////////////////////////////////////////
// Initial Setup of Page
////////////////////////////////////////////////////////////////////////
function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyStartButton.OnClick=CommonOnClick;
    MyBackButton.OnClick=CommonOnClick;

    MyLoadoutButton.OnClick=CommonOnClick;
    MyScoresButton.OnClick=CommonOnClick;
	MyVotingButton.OnClick=CommonOnClick;

    MyGameSettingsButton.OnClick=CommonOnClick;
    MyServerSettingsButton.OnClick=CommonOnClick;

    CachedGameMode = MPM_BarricadedSuspects;
    MyGameInfoLabel.SetCaption( GC.GetGameModeName(MPM_BarricadedSuspects) );
    MyServerInfoBox.SetContent( GC.GetGameDescription(MPM_BarricadedSuspects) );
}

////////////////////////////////////////////////////////////////////////
// Page Delegates & Parameter Handling
////////////////////////////////////////////////////////////////////////

event HandleParameters(string Param1, string Param2, optional int param3)
{
    Super.HandleParameters( Param1, Param2, param3 );

    SwatGuiController(Controller).SetPlayerNotReady();
    bPressedReady = false;
    MyStartButton.EnableComponent();
}

event PostActivate()
{
    Super.PostActivate();
    SetupPopup();

	if (SwatGUIController(Controller).Repo.Level.IsPlayingCOOP)
		MyChatPanel.RePosition('COOP');
	else
		MyChatPanel.RePosition('MP');
}


private function bool IsAdminable()
{
    return ( GC.SwatGameRole == GAMEROLE_MP_Host &&
             ( GC.SwatGameState == GAMESTATE_PreGame ||
               GC.SwatGameState == GAMESTATE_MidGame ||
               GC.SwatGameState == GAMESTATE_PostGame ) );
}

private function SetupPopup()
{
    local bool bAdminable;

    OpenScores();

    bAdminable = IsAdminable();

    //big state check to determin component visibility/activity
    if( GC.SwatGameState == GAMESTATE_PreGame )
    {
        MyLoadingGraphic.Hide();
        MyLoadingBlackGraphic.Hide();
        MyLoadingTextLabel.Hide();
        LoadingImage.Hide();

        if(!bPressedReady)
          MyStartButton.SetCaption( ReadyString );
        else
          MyStartButton.SetCaption( UnreadyString );

        MyServerSettingsButton.SetVisibility( bAdminable );
        MyServerSettingsButton.SetActive( bAdminable );

#if IG_SWAT_PROGRESS_BAR
        MissionLoadingProgressBar.Hide();
        MissionLoadingStatusText.Hide();
#endif
    }
    else if( GC.SwatGameState == GAMESTATE_MidGame && bPopup )
    {
        MyLoadingGraphic.Hide();
        MyLoadingBlackGraphic.Hide();
        MyLoadingTextLabel.Hide();
        LoadingImage.Hide();

        MyStartButton.Hide();
        MyStartButton.DeActivate();

        MyServerSettingsButton.Hide();
        MyServerSettingsButton.DeActivate();

		MyVotingButton.Hide();
        MyVotingButton.DeActivate();
        MyScoresButton.Hide();
        MyScoresButton.DeActivate();
        MyLoadoutButton.Hide();
        MyLoadoutButton.DeActivate();
        MyBackButton.Hide();
        MyBackButton.DeActivate();
        MyGameSettingsButton.Hide();
        MyGameSettingsButton.DeActivate();

        MyMPScoresPanel.MyChangeTeamButton.Hide();
        MyMPScoresPanel.MyChangeTeamButton.DeActivate();
        MyMPScoresPanel.MyToggleVOIPIgnoreButton.Hide();
        MyMPScoresPanel.MyToggleVOIPIgnoreButton.DeActivate();

#if IG_SWAT_PROGRESS_BAR
        MissionLoadingProgressBar.Hide();
        MissionLoadingStatusText.Hide();
#endif
    }
    else if( GC.SwatGameState == GAMESTATE_MidGame && !bPopup )
    {
        MyLoadingGraphic.Hide();
        MyLoadingBlackGraphic.Hide();
        MyLoadingTextLabel.Hide();
        LoadingImage.Hide();

        MyStartButton.SetCaption( ContinueString );

        MyServerSettingsButton.SetVisibility( bAdminable );
        MyServerSettingsButton.SetActive( bAdminable );

#if IG_SWAT_PROGRESS_BAR
        MissionLoadingProgressBar.Hide();
        MissionLoadingStatusText.Hide();
#endif
    }
    else if( GC.SwatGameState == GAMESTATE_PostGame )
    {
        MyLoadingGraphic.Hide();
        MyLoadingBlackGraphic.Hide();
        MyLoadingTextLabel.Hide();
        LoadingImage.Hide();

//        MyStartButton.Hide();
//        MyStartButton.DeActivate();
//        MyStartButton.DisableComponent();
        if(!bPressedReady)
          MyStartButton.SetCaption( ReadyString );
        else
          MyStartButton.SetCaption( UnreadyString );

        MyServerSettingsButton.SetVisibility( bAdminable );
        MyServerSettingsButton.SetActive( bAdminable );

//        MyScoresButton.Hide();
//        MyScoresButton.DeActivate();
//        MyLoadoutButton.Hide();
//        MyLoadoutButton.DeActivate();


//        MyGameSettingsButton.Hide();
//        MyGameSettingsButton.DeActivate();

#if IG_SWAT_PROGRESS_BAR
        MissionLoadingProgressBar.Hide();
        MissionLoadingStatusText.Hide();
#endif
    }
    else if( GC.SwatGameState == GAMESTATE_ClientTravel )
    {
        //display mission loading image only when leaving a mission where you were playing COOP,
        //  and only if there are any loading images available
        if( SwatGUIController(Controller).Repo.Level.IsPlayingCOOP && DefaultImages.Length > 0 )
        {
            LoadingImage.Image = DefaultImages[ Rand( DefaultImages.Length ) ];
        }
        else
        {
            LoadingImage.Hide();
        }

        MyStartButton.Hide();
        MyStartButton.DeActivate();

        MyServerSettingsButton.Hide();
        MyServerSettingsButton.DeActivate();

		MyVotingButton.Hide();
        MyVotingButton.DeActivate();
        MyScoresButton.Hide();
        MyScoresButton.DeActivate();
        MyLoadoutButton.Hide();
        MyLoadoutButton.DeActivate();
        MyBackButton.Hide();
        MyBackButton.DeActivate();
        MyGameSettingsButton.Hide();
        MyGameSettingsButton.DeActivate();

        MyMPScoresPanel.MyTitleLabel.Hide();
        MyMPScoresPanel.MyChangeTeamButton.Hide();
        MyMPScoresPanel.MyChangeTeamButton.DeActivate();
        MyMPScoresPanel.MyToggleVOIPIgnoreButton.Hide();
        MyMPScoresPanel.MyToggleVOIPIgnoreButton.DeActivate();
		MyMPScoresPanel.MyAbortGameButton.Hide();
        MyMPScoresPanel.MyAbortGameButton.DeActivate();
        MyMPScoresPanel.MyObjectivesPanel.Hide();
        MyMPScoresPanel.MyLeadershipPanel.Hide();
        MyMPScoresPanel.MyDebriefingLeadershipPanel.Hide();
        MyMPScoresPanel.MyMapPanel.Hide();
        MyMPScoresPanel.MyOfficerStatusPanel.Hide();

        MyChatPanel.Hide();
        MyServerInfoBox.Hide();
        MyBombsRemainingLabel.Hide();
        MyRoundsLabel.Hide();
        MyGameInfoLabel.Hide();
        MyServerNameLabel.Hide();

#if IG_SWAT_PROGRESS_BAR
        MissionLoadingProgressBar.Show();
        MissionLoadingStatusText.Show();
#endif
    }
    else
    {
        Assert( false );
    }
}

function InternalOnActivate()
{
	SetFocusInstead(MyServerInfoBox);

    DisplayGameInfo();

    MyMPLoadoutPanel.LoadMultiPlayerLoadout();

    SetTimer( 1.0, true );
	
	if (SwatGUIController(Controller).coopcampaign)
	{
		MyServerSettingsButton.Hide();
		MyServerSettingsButton.DisableComponent();
	}
	else 
	{
		MyServerSettingsButton.Show();
		MyServerSettingsButton.EnableComponent();
	}
}

function InternalOnDeActivate()
{
    KillTimer();
}

function DisplayGameInfo()
{
    local SwatGameReplicationInfo SGRI;
    local int BombsRemainingCount;
    local string displayString;
    local int i;
    local ServerSettings Settings;

    SGRI = SwatGameReplicationInfo( PlayerOwner().GameReplicationInfo );
    Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

    if( SGRI == None || Settings == None )
        return;

    MyServerNameLabel.SetCaption( Settings.ServerName );

    if( SGRI.bWaitingForPlayers )
        MyWaitingForPlayersLabel.SetCaption( WaitingForPlayersString );
    else
        MyWaitingForPlayersLabel.SetCaption( "" );

    if( CachedGameMode != Settings.GameType || CachedTitle != PlayerOwner().Level.Summary.Title )
    {
        CachedTitle = PlayerOwner().Level.Summary.Title;
        CachedGameMode = Settings.GameType;
        MyGameInfoLabel.SetCaption( FormatTextString( GameModeAndLevelString, GC.GetGameModeName(Settings.GameType), CachedTitle ) );
        MyServerInfoBox.SetContent( GC.GetGameDescription(Settings.GameType) );
    }

    if( Settings.GameType == EMPMode.MPM_COOP &&
        GC.CurrentMission != None &&
        MyGameInfoLabel.GetCaption() != GC.CurrentMission.FriendlyName )
    {
        MyGameInfoLabel.SetCaption( GC.CurrentMission.FriendlyName );

        // display briefing
        displayString = "";
        for( i = 0; i < GC.CurrentMission.BriefingText.Length; i++ )
        {
            displayString = displayString $ GC.CurrentMission.BriefingText[i] $ "|";
        }

        MyServerInfoBox.SetContent( displayString );

        MyRoundsLabel.Hide();
    }

    if( Settings.GameType == EMPMode.MPM_RapidDeployment )
    {
        BombsRemainingCount = SGRI.TotalNumberOfBombs - SGRI.DiffusedBombs;
        MyBombsRemainingLabel.SetCaption( FormatTextString( BombsRemaining, string( BombsRemainingCount ), string( SGRI.TotalNumberOfBombs ) ) );
        MyBombsRemainingLabel.Show();
    }
    else
    {
        MyBombsRemainingLabel.Hide();
    }

    MyRoundsLabel.SetCaption( FormatTextString( RoundsRemainingString, string( Settings.RoundNumber + 1 ), string( Settings.NumRounds ) ) );
}

event Timer()
{
    DisplayGameInfo();
}

////////////////////////////////////////////////////////////////////////
// Component Delegates
////////////////////////////////////////////////////////////////////////
function CommonOnClick(GUIComponent Sender)
{
	switch (Sender)
	{
		case MyStartButton:
            if(!bPressedReady) {
              if(MyMPLoadoutPanel.CheckWeightBulkValidity()) {
                SwatGuiController(Controller).SetPlayerReady();
                bPressedReady = true;
                MyStartButton.SetCaption(UnreadyString);
                MyLoadoutButton.DeActivate();
              }
            } else {
              SwatGuiController(Controller).SetPlayerNotReady();
              bPressedReady = false;
              MyStartButton.SetCaption(ReadyString);
              MyLoadoutButton.Activate();
            }
	          ResumeGame();
            break;
		case MyBackButton:
            OnDlgReturned=InternalOnDlgReturned;
            OpenDlg( ConfirmAbortString, QBTN_YesNo, "Abort" );
            break;
		case MyLoadoutButton:
            OpenLoadout();
            break;
		case MyScoresButton:
            OpenScores();
            break;
		case MyVotingButton:
            OpenVoting();
            break;
		case MyGameSettingsButton:
			OpenGameSettings();
			break;
		case MyServerSettingsButton:
			Controller.OpenMenu("SwatGui.SwatServerSetupMenu", "SwatServerSetupMenu", "InGame");
			break;
	}
}

private function InternalOnDlgReturned( int Selection, String passback )
{
    switch (passback)
    {
        case "Abort":
            if( Selection == QBTN_Yes )
            {
                AbortGame();
            }
            break;
    }
}

protected function AbortGame()
{
    SwatGuiController(Controller).PlayerDisconnect();
}

function ResumeGame()
{
    if( GC.SwatGameState == GAMESTATE_ClientTravel )
        return;

    if( GC.SwatGameState != GAMESTATE_MidGame )
    {
        return;
    }

	Controller.CloseMenu();
}

private function OpenVoting()
{
	MyMPVotingPanel.Show();
    MyMPVotingPanel.Activate();
	MyMPScoresPanel.Hide();
    MyMPScoresPanel.DeActivate();
	MyMPLoadoutPanel.Hide();
    MyMPLoadoutPanel.DeActivate();

	MyVotingButton.Focus();
	MyScoresButton.EnableComponent();
    MyLoadoutButton.EnableComponent();
}

private function OpenScores()
{
    local bool bPlayingCOOP;

    bPlayingCOOP = SwatGUIController(Controller).Repo.Level.IsPlayingCOOP;

//    MyChatPanel.SetVisibility( !bPlayingCOOP );
//    MyChatPanel.SetActive( !bPlayingCOOP );
    MyServerInfoBox.SetVisibility( !bPlayingCOOP || GC.SwatGameState != GAMESTATE_PostGame );
    MyServerInfoBox.SetActive( !bPlayingCOOP || GC.SwatGameState != GAMESTATE_PostGame );
    MyGameInfoLabel.SetVisibility( !bPlayingCOOP || GC.SwatGameState != GAMESTATE_PostGame );

	MyMPVotingPanel.Hide();
    MyMPVotingPanel.DeActivate();
    MyMPScoresPanel.Show();
    MyMPScoresPanel.Activate();
    MyMPLoadoutPanel.Hide();
    MyMPLoadoutPanel.DeActivate();

	MyVotingButton.EnableComponent();
    MyScoresButton.Focus();
    MyLoadoutButton.EnableComponent();
}

private function OpenLoadout()
{
    MyChatPanel.Show();
    MyChatPanel.Activate();
    MyServerInfoBox.Show();
    MyServerInfoBox.Activate();
    MyGameInfoLabel.Show();

	MyMPVotingPanel.Hide();
    MyMPVotingPanel.DeActivate();
    MyMPScoresPanel.Hide();
    MyMPScoresPanel.DeActivate();
    MyMPLoadoutPanel.Show();
    MyMPLoadoutPanel.Activate();

	MyVotingButton.EnableComponent();
    MyScoresButton.EnableComponent();
    MyLoadoutButton.Focus();
}

protected function bool HandleKeyEventFirstCrack( out byte Key, out byte State, float delta )
{
    if( State == EInputAction.IST_Press )
    {
        //don't handle first crack on chat up/down if the chat entry is open
        if( !MyChatPanel.MyChatEntry.bActiveInput )
        {
            if( KeyMatchesBinding( Key, "ScrollChatUp" ) )
            {
                SwatGUIController(Controller).ScrollChatUp();
                return true;
            }
            if( KeyMatchesBinding( Key, "ScrollChatDown" ) )
            {
                SwatGUIController(Controller).ScrollChatDown();
                return true;
            }
        }
        if( KeyMatchesBinding( Key, "ScrollChatPageUp" ) )
        {
            SwatGUIController(Controller).ScrollChatPageUp();
            return true;
        }
        if( KeyMatchesBinding( Key, "ScrollChatPageDown" ) )
        {
            SwatGUIController(Controller).ScrollChatPageDown();
            return true;
        }
        if( KeyMatchesBinding( Key, "ScrollChatToEnd" ) )
        {
            SwatGUIController(Controller).ScrollChatToEnd();
            return true;
        }
        if( KeyMatchesBinding( Key, "ScrollChatToHome" ) )
        {
            SwatGUIController(Controller).ScrollChatToHome();
            return true;
        }
    }

    return false;
}

protected function bool HandleKeyEvent( out byte Key, out byte State, float delta )
{
    if( State == EInputAction.IST_Press )
    {
        if( KeyMatchesBinding( Key, "OpenHudChat 1" ) )
        {
            SwatGUIController(Controller).OpenChat( true );
            return true;
        }
        if( KeyMatchesBinding( Key, "OpenHudChat 0" ) )
        {
            SwatGUIController(Controller).OpenChat( false );
            return true;
        }
    }

    return Super.HandleKeyEvent( Key, State, delta );
}

#if IG_SWAT_PROGRESS_BAR
function OnProgress(string PercentComplete, string ExtraInfo)
{
	log("  SwatMissionLoadingMenu ONPROGRESS Received: ["$PercentComplete$"] ["$ExtraInfo$"]");
	MissionLoadingProgressBar.Value = float(PercentComplete);

    if( ExtraInfo == "LoadSplash" )
        MissionLoadingStatusText.SetCaption( LoadSplashString );
    else if( ExtraInfo == "WaitForConnection" )
        MissionLoadingStatusText.SetCaption( WaitForConnectionString );
    else if( ExtraInfo == "LoadMap" )
        MissionLoadingStatusText.SetCaption( LoadMapString );
    else if( ExtraInfo == "Download" )
        MissionLoadingStatusText.SetCaption( DownloadString );

	if (Controller != None)
		Controller.PaintProgress();
}
#endif


function BringServerInfoToFront()
{
    BringToFront( MyServerInfoBox );
}

function SendServerInfoToBack()
{
    BringToBack( MyServerInfoBox );
}

function OnProfileButton(GUIComponent Sender)
{
	Controller.OpenMenu( "SwatGui.SwatGamespyProfilePopup", "SwatGamespyProfilePopup" );
}

////////////////////////////////////////////////////////////////////////
// Page Defaults
////////////////////////////////////////////////////////////////////////
defaultproperties
{
    OnKeyEventFirstCrack=HandleKeyEventFirstCrack
    OnActivate=InternalOnActivate
    OnDeActivate=InternalOnDeActivate

    BombsRemaining="Bombs Remaining: %1/%2"
    RoundsRemainingString="Round: %1/%2"
    GameModeAndLevelString="Level: %2    Mode: %1"
    WaitingForPlayersString="Waiting for players to reconnect..."

    LoadSplashString="Loading..."
    WaitForConnectionString="Connecting..."
    LoadMapString="Loading..."
    DownloadString="Downloading..."

    bPressedReady = false;

    ConfirmAbortString="Disconnect from the current game?"
}
