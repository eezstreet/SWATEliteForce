class SwatGUIController extends SwatGame.SwatGUIControllerBase
     ;

import enum eSwatGameState from SwatGame.SwatGuiConfig;
import enum eSwatGameRole from SwatGame.SwatGuiConfig;
import enum EMPMode from Engine.Repo;

//TODO: is this import required?
import enum eDifficultyLevel from SwatGame.SwatGUIConfig;

const VOIP_SPEAKER_EXPIRY_TIME = 1.0f;		// delay between last speaking time and when speaker is removed from speaker list

enum eTimeType
{
    TIMER_Special,
    TIMER_Mission,
    TIMER_MetaMission,
    TIMER_Respawn,
	TIMER_Referendum,
};

enum eIMDType
{
    IMD_GameMessages,
    IMD_RespawnMessages,
};

var(SwatGUIController) Editinline EditConst	Array<GUIPage>	StorageStack "Holds an out-of-game set of page names for recreating the stack";

var(SwatGUIController) public EditInline EditConst SwatSPLoadoutPanel              SPLoadoutPanel "The loadout panel that should be used to display messages";
var(SwatGUIController) private Editinline EditConst SwatMPLoadoutPanel              MPLoadoutPanel "The loadout panel that should be used to display messages";
var(SwatGUIController) private Editinline EditConst array<SwatChatPanel>            ChatPanel "The chat panel that should be used to display messages";
var(SwatGUIController) private Editinline EditConst SwatImportantMessageDisplay     ImportantMessageDisplays[eIMDType.EnumCount] "The important message display";
var(SwatGUIController) private Editinline EditConst SwatTimeDisplay                 TimeDisplays[eTimeType.EnumCount] "The important message display";
var(SwatGUIController) private Editinline EditConst CustomScenarioCoopPage          CoopPage "The main GUI page during coop QMM";

var(DEBUG) editconst editinline CustomScenarioCoopPage CoopQMMPopupMenu;
var(DEBUG) editconst editinline SwatMPPage MPPopupMenu;
var(DEBUG) editconst editinline SwatObjectivesPopupMenu SPPopupMenu;
var(DEBUG) editconst editinline SwatMissionLoadingMenu MissionLoadingMenu;
var(DEBUG) editconst editinline SwatServerSetupMenu ServerSetupMenu;

var() private config localized string WaitingString;
var() private config localized string VIPTimerText;
var() private config localized string SmashAndGrabTimerText;
var() private config localized string RDTimerText;
var() private config localized string ViewingFrom;
var() private config localized string ViewingFromNone;
var() private config localized string ViewingFromVIP;

var() private config localized string MissionCompleted;
var() private config localized string MissionFailed;
var() private config localized string ObjectiveShown;

var() private config localized string SwatWin;
var() private config localized string SuspectsWin;
var() private config localized string GameTied;
var() private config localized string OneMinWarning;
var() private config localized string TenSecWarning;
var() private config localized string DisarmBomb;
var() private config localized string SwatWinRD;
var() private config localized string SuspectsWinRD;
var() private config localized string SwatRespawnEvent;
var() private config localized string SuspectsRespawnEvent;
var() private config localized string BothTeamsRespawnEvent;
var() private config localized string VIPSafe;
var() private config localized string VIPRescued;
var() private config localized string VIPCaptured;
var() private config localized string YouAreVIP;
var() private config localized string WinSuspectsGoodKill;
var() private config localized string WinSuspectsBadKill;
var() private config localized string WinSwatBadKill;
var() private config localized string SwatWinSmashAndGrab;
var() private config localized string SuspectsWinSmashAndGrab;

var() private config localized string PreGameText;
var() private config localized string MidGameText;
var() private config localized string PostGameText;

var() private config localized string VoteYesNoKeys;

var() bool bNetPlayerLoaded;

var() string EnteredChatText;
var() bool   EnteredChatGlobal;

var() private config bool DispatchDisabled;

var() bool coopcampaign;

/////////////////////////////////////////////////////////////////////////////
// Initialization
/////////////////////////////////////////////////////////////////////////////
function InitializeController()
{
log("[dkaplan] >>> InitializeController of (SwatGUIController) "$self);
    Super.InitializeController();

    GetMissionLoadingMenu();

    if( Repo.InitAsListenServer || Repo.InitAsDedicatedServer )
    {
        //dont open any menu's now - wait for the level load to handle opening the necessary menus
        return;
    }
    else if( GuiConfig.SwatGameState==GAMESTATE_None )
    {
        OpenMenu( "SwatGui.SwatMainMenu", "SwatMainMenu" );

        if( !Repo.InitWithoutIntroMenu )
            OpenMenu( "SwatGui.SwatIntroMenu", "SwatIntroMenu" );
    }
    else
    {
        InternalOpenMenu( GetHudPage() );
    }
}

/////////////////////////////////////////////////////////////////////////////
// Polling
/////////////////////////////////////////////////////////////////////////////
function PollGUI()
{
    UpdateTimers();
	UpdateVOIPSpeakers();
}

function PollCoopQMMGUI()
{
	if (CoopPage != None)
		CoopPage.Poll();
}

/////////////////////////////////////////////////////////////////////////////
// Required to be here because the damn thing is native!!
/////////////////////////////////////////////////////////////////////////////
function bool GetDispatchDisabled() {
  return DispatchDisabled;
}

function SetDispatchDisabled(bool newValue) {
  DispatchDisabled = newValue;
}

/////////////////////////////////////////////////////////////////////////////
// Game State / Game Systems Reference
/////////////////////////////////////////////////////////////////////////////
function OnRoleChange( eSwatGameRole oldRole, eSwatGameRole newRole )
{
    local GameSpyManager GSM;
log("[dkaplan] >>> OnRoleChange of (SwatGUIController) "$self);

    switch ( newRole )
    {
        case GAMEROLE_None:

        GSM = ViewportOwner.Actor.Level.GetGameSpyManager();
        if ( GSM != None )
        {
            GSM.CleanUpGameSpy();
        }

        break;
    }

    ClearChatHistory();
}

function OnStateChange( eSwatGameState oldState, eSwatGameState newState, optional EMPMode CurrentGameMode )
{
    local string CustomMissionLabel;
log("[dkaplan] >>> OnStateChange of (SwatGUIController) "$self);
//LogMenuStack();
//LogStorageStack();
    if( oldState == GAMESTATE_None )
        SaveEntryStack();

    Switch (newState)
    {
        case GAMESTATE_None:
            ConsoleCommand( "CLEARURL" );

            ClearChatHistory();

            if( StorageStack.Length == 0 )
                OpenMenu( "SwatGui.SwatMainMenu", "SwatMainMenu" );
            else
                OpenEntryStack();
            break;
        case GAMESTATE_ClientTravel:
            if( oldState != GAMESTATE_None &&
                ( GuiConfig.SwatGameRole == GAMEROLE_MP_Host ||
                  GuiConfig.SwatGameRole == GAMEROLE_MP_Client ) )
            {
                CloseAll();
                InternalOpenMenu( MPPopupMenu );
                break;
            }
        case GAMESTATE_LevelLoading:
        case GAMESTATE_EntryLoading:
			if (OldState != GAMESTATE_None)
	            HUDPage(GetHudPage()).OnGameOver(); //ensure the hud gets its OnGameOver

            CloseAll();
            InternalOpenMenu(MissionLoadingMenu);
            break;
        case GAMESTATE_PreGame:
			// pre-cache the popup menus
			GetCurrentPopupMenu();

			//precache the server setup menu if host
			if( GuiConfig.SwatGameRole == GAMEROLE_MP_Host )
			    GetServerSetupMenu();

            RemoveNonChatMessagesFromHistory();

            //get rid of MissionLoadingMenu
            CloseAll();
            InternalOpenMenu( GetHudPage() );
            HUDPage(GetHudPage()).OnGameInit();

        log( "      FirstTimeThrough="$GuiConfig.FirstTimeThrough );
        log( "      SwatGameRole="$GuiConfig.SwatGameRole );
            if(GuiConfig.SwatGameRole == GAMEROLE_MP_Host ||
               GuiConfig.SwatGameRole == GAMEROLE_MP_Client)
            {
                SetPlayerNotReady();
                OnMessageRecieved( "", 'PreGameWait' );

				if( CurrentGameMode == MPM_COOPQMM )
					InternalOpenMenu( GetCoopQMMPopupMenu() );
				else
					InternalOpenMenu( MPPopupMenu );
            }
            break;
        case GAMESTATE_MidGame:
            while( TopPage() != GetHudPage() )
            {
                if( TopPage() == None )
                {
                    InternalOpenMenu( GetHudPage() );
                    break;
                }

                if( SwatGuiPage(TopPage()) != None )
                    SwatGuiPage(TopPage()).PerformClose();
                else
                    CloseMenu();
            };

            ImportantMessageDisplays[eIMDType.IMD_GameMessages].ClearDisplay();
            HUDPage(GetHudPage()).OnGameStarted();

            break;
        case GAMESTATE_PostGame:
            HUDPage(GetHudPage()).OnGameOver();

            if( (GuiConfig.SwatGameRole == GAMEROLE_MP_Host && !coopcampaign) ||
                GuiConfig.SwatGameRole == GAMEROLE_MP_Client )
            {
                InternalOpenMenu( MPPopupMenu );
            }
            else
            {
                GuiConfig.CurrentMission.SetHasMetDifficultyRequirement( GetSwatGameInfo().LeadershipStatus() >= GuiConfig.DifficultyScoreRequirement[GuiConfig.CurrentDifficulty] );

                if( (GuiConfig.SwatGameRole == GAMEROLE_SP_Campaign &&
                    Campaign != None) || coopcampaign )
                {
                    Campaign.MissionEnded(GetLevelInfo().Label, GuiConfig.CurrentDifficulty,!(GuiConfig.CurrentMission.IsMissionFailed()), GetSwatGameInfo().LeadershipStatus(), GuiConfig.CurrentMission.HasMetDifficultyRequirement() );    //completed
                }
                else if( GuiConfig.SwatGameRole == GAMEROLE_SP_Custom )
                {
                    CustomMissionLabel = GuiConfig.GetPakFriendlyName()$"_"$GuiConfig.GetScenarioName();
                    AssertWithDescription( CustomMissionLabel != "", "Attempted to save results for a custom mission with no name. This should never happen. Contact a programmer." );
                    GuiConfig.MissionEnded(name(CustomMissionLabel), GuiConfig.CurrentDifficulty,!(GuiConfig.CurrentMission.IsMissionFailed()), GetSwatGameInfo().LeadershipStatus() );    //completed
                }

                OpenMenu( "SwatGui.SwatDebriefingMenu", "SwatDebriefingMenu" );
            }
            break;
        case GAMESTATE_ConnectionFailed:
            CloseAll();
            OpenMenu( "SwatGui.SwatConnectionFailureMenu", "SwatConnectionFailureMenu", CurrentFailureMessage1, CurrentFailureMessage2 );
            break;
    }
}


/////////////////////////////////////////////////////////////////////////////
// Entry stack loading/saving utilities
/////////////////////////////////////////////////////////////////////////////
function SaveEntryStack()
{
    local int i;
    StorageStack.Remove(0,StorageStack.Length);
	for (i=0;i<MenuStack.Length;i++)
	{
	    if( MenuStack[i] != MissionLoadingMenu )
    		StorageStack[StorageStack.Length]=MenuStack[i];
	}
}

function OpenEntryStack()
{
    local int i;
    CloseAll();
	for (i=0;i<StorageStack.Length-1;i++)
	{
	    MenuStack[MenuStack.Length]=StorageStack[i];
	}
	InternalOpenMenu(StorageStack[StorageStack.Length-1]);
}

function LogMenuStack()
{
    local int i;

	for (i=0;i<MenuStack.Length-1;i++)
	{
log( self$"::LogMenuStack() ... MenuStack["$i$"] = "$MenuStack[i]);
	}
}

function LogStorageStack()
{
    local int i;

	for (i=0;i<StorageStack.Length-1;i++)
	{
log( self$"::LogStorageStack() ... StorageStack["$i$"] = "$StorageStack[i]);
	}
}


private function SendMessageToChat( String Msg, Name Type, optional bool bStopScrolling )
{
    local int i;

    for( i = 0; i < ChatPanel.Length; i++ )
    {
    //log("[dkaplan] sending message "$Msg$" to "$ChatPanel[i]);
        ChatPanel[i].MessageRecieved( Msg, Type, bStopScrolling );
    }
}

private function RemoveNonChatMessagesFromHistory()
{
    local int i;

    for( i = 0; i < ChatPanel.Length; i++ )
    {
        ChatPanel[i].RemoveNonChatMessagesFromHistory();
    }
}

private function ClearChatHistory()
{
    local int i;

    for( i = 0; i < ChatPanel.Length; i++ )
    {
        ChatPanel[i].ClearChatHistory();
    }
}

function bool OnMessageRecieved( String Msg, Name Type )
{
//log( "[dkaplan]: >>>OnMessageRecieved: Msg = "$Msg$", Type = "$Type$", ViewportOwner.Actor = "$ViewportOwner.Actor);
    ViewportOwner.Actor.ConsoleMessage("OnMessageReceived("$Type$"): "$Msg);
    switch (Type)
    {
        case 'Connected':
            if( MPLoadoutPanel != None )
                MPLoadoutPanel.LoadMultiPlayerLoadout();
            break;

        case 'SwitchTeams':
        case 'NameChange':
        case 'Kick':
        case 'KickBan':
        case 'Say':
        case 'TeamSay':
        case 'CommandGiven':
        case 'SwatKill':
        case 'SuspectsKill':
        case 'SwatSuicide':
        case 'SuspectsSuicide':
        case 'SwatTeamKill':
        case 'SuspectsTeamKill':
        case 'SwatArrest':
        case 'SuspectsArrest':
        case 'PlayerConnect':
        case 'PlayerDisconnect':
        case 'SettingsUpdated':
        case 'NameChange':
        case 'Kick':
        case 'KickBan':
		case 'KickReferendumStarted':
		case 'BanReferendumStarted':
		case 'LeaderReferendumStarted':
		case 'MapReferendumStarted':
		case 'ReferendumAlreadyActive':
		case 'ReferendumStartCooldown':
		case 'PlayerImmuneFromReferendum':
		case 'ReferendumAgainstAdmin':
		case 'ReferendumsDisabled':
		case 'LeaderVoteTeamMismatch':
		case 'YesVote':
		case 'NoVote':
		case 'ReferendumSucceeded':
		case 'ReferendumFailed':
		case 'CoopQMM':
		case 'SmashAndGrabArrestTimeDeduction':
		case 'SmashAndGrabGotItem':
		case 'SmashAndGrabDroppedItem':
		case 'Stats':
		case 'CoopLeaderPromoted':
		case 'CoopMessage':
		case 'StatsValidatedMessage':
		case 'StatsBadProfileMessage':
            if( GuiConfig.SwatGameRole == GAMEROLE_MP_Host ||
                GuiConfig.SwatGameRole == GAMEROLE_MP_Client )
            {
                SendMessageToChat( Msg, Type );
            }
            break;

        //single-player messages
        case 'MissionEnded':
            //do nothing
            break;
        case 'PenaltyIssued':
        case 'ObjectiveCompleted':
            SendMessageToChat(Msg, Type, true);
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( Msg );
            break;
        case 'MissionCompleted':
            SendMessageToChat( Msg, Type, true );
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( MissionCompleted );
            break;
        case 'MissionFailed':
            SendMessageToChat( Msg, Type, true );
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( MissionFailed );
            break;
        case 'ObjectiveShown':
            SendMessageToChat( Msg, Type );
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( ObjectiveShown );
            break;
        case 'SniperAlerted':
            SendMessageToChat( Msg, Type );
            break;
        case 'EquipNotAvailable':
            SendMessageToChat( Msg, Type );
            break;

        case 'Caption':
            SendMessageToChat( Msg, Type );
            break;

        //multi-player messages
        case 'PreGameWait':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( WaitingString, -1.0 );
            break;

        case 'SwatWin':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( SwatWin, -1.0 );
            break;
        case 'SuspectsWin':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( SuspectsWin, -1.0 );
            break;

        case 'SwatWinSmashAndGrab':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( SwatWinSmashAndGrab, -1.0 );
            break;
        case 'SuspectsWinSmashAndGrab':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( SuspectsWinSmashAndGrab, -1.0 );
            break;

		case 'AllBombsDisarmed':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( SwatWinRD, -1.0 );
            break;
        case 'BombExploded':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( SuspectsWinRD, -1.0 );
            break;

        case 'GameTied':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( GameTied, -1.0 );
            break;
        case 'OneMinWarning':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( OneMinWarning );
            break;
        case 'TenSecWarning':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( TenSecWarning );
            break;
        case 'DisarmBomb':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( DisarmBomb );
            break;
        case 'SwatRespawnEvent':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( SwatRespawnEvent );
            break;
        case 'SuspectsRespawnEvent':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( SuspectsRespawnEvent );
            break;
        case 'VIPSafe':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( VIPSafe, -1.0 );
            break;
        case 'VIPRescued':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( VIPRescued );
            SetTimer( TIMER_Special, 0 );
            break;
        case 'VIPCaptured':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( VIPCaptured );
            break;
        case 'YouAreVIP':
            mplog( "In SwatGUIController::OnMessageRecieved(). Should show VIP message." );
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( YouAreVIP );
            break;
        case 'WinSuspectsGoodKill':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( WinSuspectsGoodKill, -1.0 );
            break;
        case 'WinSuspectsBadKill':
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( WinSuspectsBadKill, -1.0 );
            break;
        case 'WinSwatBadKill':
            mplog( "...winswatbadkill. string="$WinSwatBadKill );
            ImportantMessageDisplays[eIMDType.IMD_GameMessages].MessageRecieved( WinSwatBadKill, -1.0 );
            break;
        case 'ViewingFromEvent':
            if( Msg != "" )
            {
				// Display "viewing from: xxx" and don't hide the the respawn timer
                ImportantMessageDisplays[eIMDType.IMD_RespawnMessages].MessageRecieved( ViewingFrom$Msg );
            }
            else
            {
				// This causes the "Viewing from" text to disappear *remove* the respawn timer
				// (e.g., after respawning)
                ImportantMessageDisplays[eIMDType.IMD_RespawnMessages].ClearDisplay();
                SetTimer( TIMER_Respawn, 0 );
            }
            break;
        case 'ViewingFromNoneEvent':
			// This causes the "Viewing from" text to disappear but still display the respawn timer
            ImportantMessageDisplays[eIMDType.IMD_RespawnMessages].MessageRecieved( ViewingFromNone );
            break;
        case 'ViewingFromVIPEvent':
            ImportantMessageDisplays[eIMDType.IMD_RespawnMessages].MessageRecieved( ViewingFromVIP$Msg );
            break;

		case 'DebugMessage':
                SendMessageToChat( Msg, Type );

        default:
            return true;
            break;
    }

    return true;
}

function UpdateTimers()
{
    local SwatGameReplicationInfo SGRI;
    local SwatPlayerReplicationInfo SPRI;

    SGRI = SwatGameReplicationInfo(SwatGamePlayerController(ViewportOwner.Actor).GameReplicationInfo);
    SPRI = SwatPlayerReplicationInfo(SwatGamePlayerController(ViewportOwner.Actor).PlayerReplicationInfo);

    SetTimer( TIMER_Special, SGRI.SpecialTime );
    UpdateSpecialTimerLabel();
    SetTimer( TIMER_Mission, SGRI.RoundTime );
    UpdateMissionTimerLabel();
    SetTimer( TIMER_Respawn, SPRI.RespawnTime );
	SetTimer( TIMER_Referendum, SGRI.RefMgr.GetTimeRemaining() );
	UpdateReferendumTimerLabel();
}

function UpdateVOIPSpeakers()
{
 	local int LocalPlayerTeamNumber;
	local SwatGameReplicationInfo SGRI;
	local SwatPlayerReplicationInfo PlayerInfo;
	local array<String> Speakers;
	local array<int> TeamNumbers;
	local float expirationTime;
	local int i, j;

	// Do nothing if we don't have access to the local players team data
	if (ViewportOwner.Actor == None || ViewportOwner.Actor.PlayerReplicationInfo == None || NetTeam(ViewportOwner.Actor.PlayerReplicationInfo.Team) == None)
		return;

	LocalPlayerTeamNumber = NetTeam(ViewportOwner.Actor.PlayerReplicationInfo.Team).GetTeamNumber();
	SGRI = SwatGameReplicationInfo(SwatGamePlayerController(ViewportOwner.Actor).GameReplicationInfo);

    if( SGRI == None )
        return;

	expirationTime = ViewportOwner.Actor.Level.TimeSeconds - VOIP_SPEAKER_EXPIRY_TIME;

	// remove old entries from speaking list
	for (i = VOIPSpeakingPlayerIDs.Length-1; i >= 0; i--)
	{
		if ( VOIPSpeakingPlayerIDs[i].SpeakTime <= expirationTime)
			VOIPSpeakingPlayerIDs.remove(i, 1);
	}

	// dbeswick: include self in list
	if (ViewportOwner.Actor.bVoiceTalk != 0)
	{
		PlayerInfo = SwatPlayerReplicationInfo(ViewportOwner.Actor.PlayerReplicationInfo);
		Speakers[Speakers.Length] = PlayerInfo.PlayerName;
		TeamNumbers[TeamNumbers.Length] = NetTeam(PlayerInfo.Team).GetTeamNumber();
	}

	// find names of people (on my team) currently speaking
	for (i = 0; i < ArrayCount(SGRI.PRIStaticArray); ++i)
    {
        PlayerInfo = SGRI.PRIStaticArray[i];

        if (PlayerInfo != None && NetTeam(PlayerInfo.Team) != None &&
			( ViewportOwner.Actor.Level.IsPlayingCOOP || // display all teams in co-op
			 NetTeam(PlayerInfo.Team).GetTeamNumber() == LocalPlayerTeamNumber))
        {
			for (j = 0; j < VOIPSpeakingPlayerIDs.Length; j++)
				if (VOIPSpeakingPlayerIDs[j].PlayerID == PlayerInfo.PlayerID)
				{
					Speakers[Speakers.Length] = PlayerInfo.PlayerName;
					TeamNumbers[TeamNumbers.Length] = NetTeam(PlayerInfo.Team).GetTeamNumber();
					break;
				}
		}
	}

	// update individual HUD elements
	GetHUDPage().UpdateVOIPSpeakers(Speakers, TeamNumbers);
}

final function SetMPLoadoutPanel( SwatMPLoadoutPanel panel )
{
    MPLoadoutPanel=panel;
}

final function SetChatPanel( SwatChatPanel panel )
{
    ChatPanel[ChatPanel.Length]=panel;
}

final function SetTimeDisplay( SwatTimeDisplay display, eTimeType type )
{
    Assert( TimeDisplays[type] == None );
    TimeDisplays[type]=display;
}

final function SetCoopPage( CustomScenarioCoopPage page )
{
	CoopPage = page;
}

final function SetIMD( SwatImportantMessageDisplay display, eIMDType type )
{
    Assert( ImportantMessageDisplays[type] == None );
    ImportantMessageDisplays[type]=display;
}

final private function SetTimer( eTimeType type, int value )
{
    if ( TimeDisplays[type] == None )
        return;
    if( Value <= 0 )
        TimeDisplays[type].StopTimer();
    else
        TimeDisplays[type].StartTimer( value,,true );
}

final private function UpdateSpecialTimerLabel()
{
    local SwatGameReplicationInfo SGRI;
    local int BombsRemainingCount;
    local ServerSettings Settings;

    Settings = ServerSettings(ViewportOwner.Actor.Level.CurrentServerSettings);
    SGRI = SwatGameReplicationInfo(SwatGamePlayerController(ViewportOwner.Actor).GameReplicationInfo);

    if( SGRI == None )
        return;

    if( GuiConfig.SwatGameRole == GAMEROLE_MP_Host ||
        GuiConfig.SwatGameRole == GAMEROLE_MP_Client )
    {
        //log( "[dkaplan] >>>UpdateSpecialTimerLabel... Settings.GameType = "$Settings.GameType );
        switch( Settings.GameType )
        {
            case MPM_BarricadedSuspects:
                TimeDisplays[eTimeType.TIMER_Special].TimerLabel.SetCaption( "Shazbot" );
                return;
                break;
            case MPM_VIPEscort:
                TimeDisplays[eTimeType.TIMER_Special].TimerLabel.SetCaption( VIPTimerText );
                return;
                break;
            case MPM_RapidDeployment:
                BombsRemainingCount = SGRI.TotalNumberOfBombs - SGRI.DiffusedBombs;
                TimeDisplays[eTimeType.TIMER_Special].TimerLabel.SetCaption( class'GUI'.Static.FormatTextString( RDTimerText, BombsRemainingCount, SGRI.TotalNumberOfBombs ) );
                return;
            case MPM_SmashAndGrab:
                TimeDisplays[eTimeType.TIMER_Special].TimerLabel.SetCaption( SmashAndGrabTimerText );
                return;
        }
    }

    if( SGRI.TimedObjectiveIndex >= 0 && Repo.MissionObjectives != None )
        TimeDisplays[eTimeType.TIMER_Special].TimerLabel.SetCaption( Repo.MissionObjectives.Objectives[SGRI.TimedObjectiveIndex].TimerCaption );
}

final private function UpdateMissionTimerLabel()
{
    if( GuiConfig.SwatGameRole == GAMEROLE_MP_Host ||
        GuiConfig.SwatGameRole == GAMEROLE_MP_Client )
    {
        switch( GuiConfig.SwatGameState )
        {
            case GAMESTATE_PreGame:
                TimeDisplays[eTimeType.TIMER_Mission].TimerLabel.SetCaption( PreGameText );
                break;
            case GAMESTATE_MidGame:
                TimeDisplays[eTimeType.TIMER_Mission].TimerLabel.SetCaption( MidGameText );
                break;
            case GAMESTATE_PostGame:
                TimeDisplays[eTimeType.TIMER_Mission].TimerLabel.SetCaption( PostGameText );
                break;
            default:
                TimeDisplays[eTimeType.TIMER_Mission].TimerLabel.Hide();
        }
    }
}

final private function UpdateReferendumTimerLabel()
{
	local SwatGameReplicationInfo SGRI;
	local PlayerReplicationInfo PRI;
	local String VoteYesKey;
	local String VoteNoKey;

	SGRI = SwatGameReplicationInfo(SwatGamePlayerController(ViewportOwner.Actor).GameReplicationInfo);

    if( SGRI == None )
        return;

	PRI = SwatGamePlayerController(ViewportOwner.Actor).PlayerReplicationInfo;

	if( PRI == None )
		return;

	if (SGRI.RefMgr.ReferendumActive() && (SGRI.RefMgr.GetTeam() == None || PRI.Team == SGRI.RefMgr.GetTeam()))
	{
		VoteYesKey = ViewportOwner.Actor.ConsoleCommand("GETKEYFORBINDING ServerVoteYes");
		VoteNoKey = ViewportOwner.Actor.ConsoleCommand("GETKEYFORBINDING ServerVoteNo");
		TimeDisplays[eTimeType.TIMER_Referendum].TimerLabel.SetCaption( SGRI.RefMgr.GetReferendumDescription() $ " - " $ SGRI.RefMgr.GetNumberOfYesVotes() $ "/" $ SGRI.RefMgr.GetNumberOfNoVotes() $ " (" $ FormatTextString(VoteYesNoKeys, VoteYesKey, VoteNoKey) $ ")");
	}
	else
	{
		TimeDisplays[eTimeType.TIMER_Referendum].Hide();
	}
}

exec function LoadLocalizedPerObjectConfig()
{
	local Object NewObj;
    local int i;
    local class<SwatContentDumper> dumper;
    local class NewClass;

log("[carlos] LoadLocalizedPerObjectConfig()");
    dumper = class<SwatContentDumper>(DynamicLoadObject("SwatGui.SwatContentDumper",class'class'));
log("[carlos] Dumping Content... dumper = "$dumper$", dumper.default.ClassName.Length= "$dumper.default.ClassName.Length);

    for (i=0;i<dumper.default.ClassName.Length;i++)
	{
		log("NewClass: "@dumper.default.ClassName[i]);
        NewClass = class( DynamicLoadObject(dumper.default.ClassName[i], class'Class') );
    	NewObj = new( None, dumper.default.ObjName[i] ) NewClass;
		log("DUMP: "@NewClass@NewObj);
		if (NewObj == None)
        	log("  Could not load"@dumper.default.ObjName[i]);
        else
		{
            log("Loaded object"$dumper.default.ObjName[i]);
		}
	}

    LoadLocalizedPerObjectConfigGUI();
}

//loads the entire gui as specified by the GUIDUMP.ini;  command line capable for localization commandlet purposes
exec function LoadLocalizedPerObjectConfigGUI()
{
	local GUIComponent NewMenu;
    local int i;
    local class<SwatGUIDumper> loader;
log("[dkaplan] Loading GUI");
    loader = class<SwatGUIDumper>(DynamicLoadObject("SwatGui.SwatGUIDumper",class'class'));
log("[dkaplan] Loading GUI... loader = "$loader$", loader.default.ClassName.Length= "$loader.default.ClassName.Length);

    for (i=0;i<loader.default.ClassName.Length;i++)
	{
    	NewMenu = CreateComponent(loader.default.ClassName[i],loader.default.ObjName[i]);
		if (NewMenu==None)
        	log("  Could not load"@loader.default.ObjName[i]);
        else
		{
	        if (!NewMenu.bInited)
				NewMenu.InitComponent(None);
            log("Loaded Menu "$loader.default.ObjName[i]);
		}
	}
}

// Carlos: Moved this to a function so it can be checked in other places.
function bool CanChat()
{
  return ( (Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Host) ||
           (Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Client) ) &&
         ( (Repo.GuiConfig.SwatGameState == GAMESTATE_PreGame) ||
           (Repo.GuiConfig.SwatGameState == GAMESTATE_MidGame) ||
           (Repo.GuiConfig.SwatGameState == GAMESTATE_PostGame) );
 }

function OpenChat(bool bGlobal)
{
    local int i;
log("[dkaplan] OpenChat bGlobal = "$bGlobal );
    if( CanChat() )
    {
        for( i = 0; i < ChatPanel.Length; i++ )
        {
            if( ChatPanel[i].bVisible &&                    //chat panel is visible
                ChatPanel[i].MenuOwner == TopPage() &&      //chat panel's MenuOwner is the current, active page
                ( SwatMPPage(TopPage()) == None ||          //top page is not the mp page
                  !SwatMPPage(TopPage()).bPopup ) )         //top page is not in popup mode
            {
                ChatPanel[i].OpenChatEntry( bGlobal );
            }
        }
    }
}


function ShowGamePopup( bool bSticky )
{
    local SwatPopupMenuBase PopupPage;
//log( "dkaplan .......... "$self$"::ShowGamePopup()... Repo.GuiConfig.SwatGameState = "$Repo.GuiConfig.SwatGameState$", HudPage = "$HudPage$", TopPage() = "$TopPage() );

    //dont do anything if not in-game, or the hud is not on top
    if( ( Repo.GuiConfig.SwatGameState != GAMESTATE_PreGame &&
          Repo.GuiConfig.SwatGameState != GAMESTATE_MidGame ) ||
        GetHudPage() != TopPage() )
        return;

    PopupPage = GetCurrentPopupMenu();
//log( "dkaplan .......... "$self$"::ShowGamePopup()... PopupPage = "$PopupPage );

    if( bSticky )
        InternalOpenMenu( PopupPage );
    else
        InternalOpenMenu( PopupPage, "Popup" );
}

function SwatPopupMenuBase GetCurrentPopupMenu()
{
    //popup page we're interested in dependent on game role
    if( (Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Host) ||
        (Repo.GuiConfig.SwatGameRole == GAMEROLE_MP_Client) )
		return GetMPPopupMenu();
    else
        return GetSPPopupMenu();
}

function CustomScenarioCoopPage GetCoopQMMPopupMenu()
{
    if( CoopQMMPopupMenu == None )
    {
		CoopQMMPopupMenu = CustomScenarioCoopPage(CreateComponent( "SwatGui.CustomScenarioCoopPage", "CustomScenarioCoopPage" ));

	    if (!CoopQMMPopupMenu.bInited)
			CoopQMMPopupMenu.InitComponent(None);
    }
    Assert( CoopQMMPopupMenu != None );
    return CoopQMMPopupMenu;
}

function SwatMPPage GetMPPopupMenu()
{
    if( MPPopupMenu == None )
    {
		MPPopupMenu = SwatMPPage(CreateComponent( "SwatGui.SwatMPPage", "SwatMPPage" ));
	    if (!MPPopupMenu.bInited)
			MPPopupMenu.InitComponent(None);
    }
    Assert( MPPopupMenu != None );
    return MPPopupMenu;
}

function SwatObjectivesPopupMenu GetSPPopupMenu()
{
    if( SPPopupMenu == None )
    {
        SPPopupMenu = SwatObjectivesPopupMenu(CreateComponent( "SwatGui.SwatObjectivesPopupMenu", "SwatObjectivesPopupMenu" ));
	    if (!SPPopupMenu.bInited)
		    SPPopupMenu.InitComponent(None);
    }
    Assert( SPPopupMenu != None );
    return SPPopupMenu;
}


function SwatMissionLoadingMenu GetMissionLoadingMenu()
{
    if( MissionLoadingMenu == None )
    {
        MissionLoadingMenu = SwatMissionLoadingMenu(CreateComponent( "SwatGui.SwatMissionLoadingMenu", "SwatMissionLoadingMenu" ));
	    if (!MissionLoadingMenu.bInited)
		    MissionLoadingMenu.InitComponent(None);
    }
    Assert( MissionLoadingMenu != None );
    return MissionLoadingMenu;
}

function SwatServerSetupMenu GetServerSetupMenu()
{
    if( ServerSetupMenu == None )
    {
        ServerSetupMenu = SwatServerSetupMenu(CreateComponent( "SwatGui.SwatServerSetupMenu", "SwatServerSetupMenu" ));
	    if (!ServerSetupMenu.bInited)
			ServerSetupMenu.InitComponent(None);
    }
    Assert( ServerSetupMenu != None );
    return ServerSetupMenu;
}

function DebugServerList(int num)
{
    SwatServerBrowserMenu(TopPage()).DebugServerList(num);
}

//handle loading as a network client by displaying the mission loading menu
function OnNetworkPlayerLoading()
{
    if( !bNetPlayerLoaded )
    {
        InternalOpenMenu(GetMissionLoadingMenu());
        bNetPlayerLoaded = true;
    }
}

function ScrollChatPageUp()
{
    local int i;
    for( i = 0; i < ChatPanel.Length; i++ )
    {
        if( ChatPanel[i].bVisible )
            ChatPanel[i].ScrollChatPageUp();
    }
}

function ScrollChatPageDown()
{
    local int i;
    for( i = 0; i < ChatPanel.Length; i++ )
    {
        if( ChatPanel[i].bVisible )
            ChatPanel[i].ScrollChatPageDown();
    }
}

function ScrollChatUp()
{
    local int i;
    for( i = 0; i < ChatPanel.Length; i++ )
    {
        if( ChatPanel[i].bVisible )
            ChatPanel[i].ScrollChatUp();
    }
}

function ScrollChatDown()
{
    local int i;
    for( i = 0; i < ChatPanel.Length; i++ )
    {
        if( ChatPanel[i].bVisible )
            ChatPanel[i].ScrollChatDown();
    }
}

function ScrollChatToHome()
{
    local int i;
    for( i = 0; i < ChatPanel.Length; i++ )
    {
        if( ChatPanel[i].bVisible )
            ChatPanel[i].ScrollChatToHome();
    }
}

function ScrollChatToEnd()
{
    local int i;
    for( i = 0; i < ChatPanel.Length; i++ )
    {
        if( ChatPanel[i].bVisible )
            ChatPanel[i].ScrollChatToEnd();
    }
}

defaultproperties
{
    WaitingString="Waiting for round to start..."
    VIPTimerText="VIP Time Remaining:"
    RDTimerText="Bombs Active: %1/%2"
	SmashAndGrabTimerText="Time Remaining"
    ViewingFrom="Now viewing from: "
    ViewingFromVIP="Now viewing from the VIP: "
    ViewingFromNone=""

    SwatWin="SWAT has won the round!"
    SuspectsWin="The Suspects have won the round!"
    GameTied="The Game Ended in a Tie!"

    OneMinWarning="1 Minute left!"
    TenSecWarning="10 Seconds!"
    DisarmBomb="SWAT has disarmed a bomb!"
    SwatWinRD="SWAT has disarmed all the bombs!"
    SuspectsWinRD="[c=ff0000]The Suspects have won the round!"

    SwatRespawnEvent="SWAT reinforcements have arrived."
    SuspectsRespawnEvent="Suspect reinforcements have arrived."
    BothTeamsRespawnEvent="Reinforcements have arrived."

    VIPSafe="The VIP has escaped!"
    VIPRescued="SWAT has freed the VIP!"
    VIPCaptured="Suspects have captured the VIP!"
    YouAreVIP="You are the VIP! Escape before you get captured."

    WinSuspectsGoodKill="SWAT has killed the VIP!"
    WinSuspectsBadKill="The Suspects have killed the VIP!"
    WinSwatBadKill="The Suspects have killed the VIP too soon!"

    SwatWinSmashAndGrab="SMASH AND GRAB SWAT WIN MESSAGE"
    SuspectsWinSmashAndGrab="SMASH AND GRAB SUSPECTS WIN MESSAGE"

	MissionFailed="You have [c=ff0000]FAILED[\\c] the mission!"
    MissionCompleted="You have [c=00ff00]COMPLETED[\\c] the mission!"
    ObjectiveShown="You have received a new objective!"

    PreGameText="Time before round begins:"
    MidGameText="Round time remaining:"
    PostGameText="Time before next round:"

	VoteYesNoKeys="Vote yes = %1, Vote no = %2"

    CaptureScriptExec=true
	
	coopcampaign=false
}
