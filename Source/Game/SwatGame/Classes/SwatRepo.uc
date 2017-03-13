// This singleton is meant to provide a place to store information that should
// persist across level changes. A single instance of it is created in
// PostBeginPlay() of LevelInfo if it is the entry level. Because the entry
// level is always present, any class that can get a reference to the entry
// level can get to the Repo.

// To get the entry level:
// If you have a Level var:
// If you don't have a Level var:
//     Viewport.Actor.GetEntryLevel()

class SwatRepo extends Engine.Repo
    native;

import enum eSwatGameState from SwatGuiConfig;
import enum eSwatGameRole from SwatGuiConfig;
import enum ESwatRoundOutcome from SwatGameInfo;
import enum EEntryType from SwatStartPointBase;

// the GUI config object holding all the gui config information
var SwatGUIConfig GuiConfig;

// These are the game systems that will be called to process game events
var SwatPlayerController PlayerController;

// Creates and provides accessors to the game's animation sets, which are
// shared for all pawns.
var private AnimationSetManager AnimationSetManager;

// This is the monotonically increasing value that we use for assigning new
// SwatPlayerID's. Zero is an invalid ID, so start at one.
var private int SwatPlayerIDCounter;

// This is an array that contains all the player items. It's unsorted.
var private array< SwatRepoPlayerItem > PlayerItems;

// This is false if the server is has just told the clients to disconnect and
// reconnect because a new round is starting. It is true otherwise.
var private bool bTravellingToNewRound;


// True if this is the first round we're hosting, false otherwise. Only valid
// on the server.
var bool bFirstRound;

// true if this is the host of a round in progress
var bool NetRoundInProgress;

// how long since we last polled
var private Float CumulativeDelta;

// the last game time we received from the server
var private Float LastServerTime;

//are we in the finished delay state?
var private bool bDelayedFinish;

//are we processing a critical moment?
var private float CriticalMomentCountdown;

var private bool bFailedServerTransitionEnabled;

//fudge factor to account for precaching
var const float     PRECACHING_FUDGE;

//a rounds won holder for the net teams
var private int RoundsWon[2];

// This is a cached reference to the SGRI in the non-entry level.
var SwatGameReplicationInfo CachedSGRI;

// When true, we have initialized loading as a net client
//   The GUIController, when initialized, should check this
//     and bring the GUI up to the appropriate state
var bool bInitAsNetPlayer;

// I also need some functions to delete the items. We need some sort of call
// that marks the ones in use and gets rid of the others, but it'll have to be
// done after the game has restarted and we wait awhile for all the returning
// players to reconnect.

var MissionObjectives MissionObjectives;
var Procedures Procedures;

// Hold a reference to the ConversationManager, which is Spawn()ed only on demand
var private ConversationManager ConversationManager;
// Hold a reference to the TrainingTextManager, which is Spawn()ed only on demand
var private TrainingTextManager TrainingTextManager;

//flag to perform a QuickRoundReset on next tick
var private bool bShouldPerformQuickRoundReset;

//////////////////////////////////////////////////////////////////////////////////
// Initialization
//////////////////////////////////////////////////////////////////////////////////
function Initialize()
{
    AnimationSetManager = new class'AnimationSetManager';
    Assert(AnimationSetManager != None);
    SwatPlayerIDCounter = 1;
    GuiConfig = new class'SwatGUIConfig';
    Assert( GuiConfig != None );
log( "[dkaplan] >>> SwatRepo::Initialize()... self = "$self$", GuiConfig = "$GuiConfig);
    StateChange( GAMESTATE_None );
    RoleChange( GAMEROLE_SP_Other );
    //mTestingItem = new class'SwatRepoPlayerItem';
    bTravellingToNewRound = false;
    NetRoundInProgress = false;
    bFirstRound = true;
    bDelayedFinish=false;
}

event PostGameEngineInit()
{
    if( InitAsListenServer )
    {
        StartServer( CommandLineMap, "?listen" );
    }
    else if( InitAsDedicatedServer )
    {
        StartServer( CommandLineMap, "?dedicated" );
    }

	// dbeswick:
	CommandLineMap = "";
}

///////////////////////////////////////////////////////////////////////////
//  Level Loading
///////////////////////////////////////////////////////////////////////////
function LoadLevel( string MapName )
{
	local String cmd;
	assertWithDescription(MapName != "", "SwatRepo::LoadLevel(): 'MapName' for mission '"$GuiConfig.CurrentMission$"' was not set correctly. Please check SwatMissions.ini");

	cmd = "start"@MapName;
	log("[dkaplan] >>> SwatRepo::LoadLevel()... MapName = '"$MapName$"' ... ConsoleCommand = '"$cmd$"'" );
    Level.ConsoleCommand( cmd );
}

///////////////////////////////////////////////////////////////////////////
//starts a server from the GuiConfig's server settings
///////////////////////////////////////////////////////////////////////////
function StartServer( string MapOverride, string AdditionalURLOptions )
{
    local string URL;
    local SwatGameSpyManager SGSM;

    SGSM = SwatGameSpyManager(Level.GetGameSpyManager());

    if ( ServerSettings(Level.CurrentServerSettings).bLAN )
        SGSM.SetShouldCheckClientCDKeys( false );
    else
        SGSM.SetShouldCheckClientCDKeys( true );

	if (MapOverride != "")
		URL = MapOverride;
	else
		URL = ServerSettings(Level.CurrentServerSettings).Maps[ServerSettings(Level.CurrentServerSettings).MapIndex];

	URL = URL $ "?Name=" $ GuiConfig.MPName $ AdditionalURLOptions;

	if( ServerSettings(Level.CurrentServerSettings).bPassworded )
    {
        URL = URL$"?GamePassword="$ServerSettings(Level.CurrentServerSettings).Password;
    }

    LoadLevel( URL );
}


//////////////////////////////////////////////////////////////////////////////////
// Register Game Systems
//////////////////////////////////////////////////////////////////////////////////
function SetPlayerController( SwatPlayerController theController )
{
    PlayerController = theController;
}

//////////////////////////////////////////////////////////////////////////////////
// Ticks
//////////////////////////////////////////////////////////////////////////////////

event Tick( Float DeltaSeconds )
{
    if(GuiConfig.SwatGameState == GAMESTATE_PreGame ||
       GuiConfig.SwatGameState == GAMESTATE_MidGame ||
       GuiConfig.SwatGameState == GAMESTATE_PostGame ||
       GuiConfig.SwatGameState == GAMESTATE_ClientTravel)
    {
        if( GuiConfig.SwatGameRole == GAMEROLE_MP_Host )
        {
            //if the flag was set on the previous tick, perform a QuickRoundReset this tick
            if( bShouldPerformQuickRoundReset )
            {
                bShouldPerformQuickRoundReset = false;
                PerformQuickRoundReset();
                return;
            }

            //dont update timers/check readiness if there are no players on the server
            if( Level.NetMode == NM_DedicatedServer && !AnyPlayersOnServer() )
                return;

            GetSGRI().ServerCountdownTime-=DeltaSeconds;

            // Notify the SwatGameInfo, so the GameMode can take any necessary actions.
            if( !bDelayedFinish )
                SwatGameInfo(Level.Game).NetRoundTimeRemaining( GetSGRI().ServerCountdownTime );

            switch ( GuiConfig.SwatGameState )
            {
                case GAMESTATE_PreGame:
					if (!SwatGameInfo(Level.Game).AllowRoundStart())
						break;
                case GAMESTATE_PostGame:
                    CumulativeDelta += DeltaSeconds;

					          if (ServerSettings(Level.CurrentServerSettings).isCampaignCoop())
					          {
						                CumulativeDelta = 0;
						                GetSGRI().ServerCountdownTime = 0;
						                CheckAllPlayersReady();
						                break;
					          }

                    if( GetSGRI().ServerCountdownTime <= 0 )
                    {
                        CumulativeDelta = 0;
                        AllPlayersReady();
                    }
                    else if( CumulativeDelta > GuiConfig.MPPollingDelay &&
                             NumberOfPlayersWhoShouldReturn() <= NumberOfReturnedPlayers() )
                    {
                        CumulativeDelta = 0;
                        CheckAllPlayersReady();
                    }
                    break;
                case GAMESTATE_MidGame:
                    //TimeLimit Reached?
                    if( GetSGRI().ServerCountdownTime <= 0 )
                    {
                        if( bDelayedFinish )
                        {
                            bDelayedFinish = false;
                            NetRoundDelayedFinish();
                        }
                        else
                        {
                            SwatGameInfo(Level.Game).NetRoundTimerExpired();
                        }
                    }

                    break;
            }
        }
        else if( GuiConfig.SwatGameRole == GAMEROLE_MP_Client )
        {
            if ( GetSGRI() != None && LastServerTime != GetSGRI().ServerCountdownTime )
            {
                LastServerTime = GetSGRI().ServerCountdownTime;
                CumulativeDelta=0;
            }
            else
            {
                CumulativeDelta+=DeltaSeconds;
                if ( CumulativeDelta > MPTimeOut )
                {
					Log("SwatRepo::Tick - Client timed out in the repo while trying to connect to the server");
                    FailedServerConnection();
                }
            }
        }

        if( CriticalMomentCountdown > 0 )
        {
            CriticalMomentCountdown -= DeltaSeconds;
            if( CriticalMomentCountdown <= 0 )
                OnDelayedCriticalMoment();
        }
    }
}


//quickly restarts the server (updates all clients, maintaining state flow, then instantly goes to next map
function QuickServerRestart( PlayerController PC )
{
    if( Level.Game.IsA( 'SwatGameInfo' ) && !SwatGameInfo(Level.Game).Admin.IsAdmin( PC ) )
        return;

    //set this flag to perform the quick round reset next tick
    bShouldPerformQuickRoundReset = true;
}

//Restarts the server from the Coop QMM lobby
function CoopQMMServerRestart( PlayerController PC )
{
    if( Level.Game.IsA( 'SwatGameInfo' ) && !SwatGameInfo(Level.Game).Admin.IsAdmin( PC ) )
        return;

    NetNextRound();
}

//quickly restarts the server (updates all clients, maintaining state flow, then instantly goes to next map
private function PerformQuickRoundReset()
{
    switch ( GuiConfig.SwatGameState )
    {
        case GAMESTATE_PreGame:
            NetRoundStart();
        case GAMESTATE_MidGame:
            NetRoundDelayedFinish();
        case GAMESTATE_PostGame:
            NetNextRound();
            break;
    }
}

//////////////////////////////////////////////////////////////////////////////////
// Game Events
//////////////////////////////////////////////////////////////////////////////////

event PreLevelChange( Player thePlayer, String MapName )
{
log("[dkaplan]: >>> SwatRepo::PreLevelChange( New Level == " $ MapName $ " )");

    PreLevelChangeCleanup();

    //always send the mission ended game event before level changing to avoid hanging ref problems
    if( PlayerController != None && Level.Game != None && SwatGameInfo(Level.Game) != None )
        SwatGameInfo(Level.Game).MissionEnded();

    if( GuiConfig.SwatGameState != GAMESTATE_ClientTravel )
    {
        if( InStr( MapName, "Entry" ) < 0 &&
            InStr( MapName, SplashSceneMapName ) < 0  )
        {
            StateChange( GAMESTATE_LevelLoading );
        }
        else if( GuiConfig.SwatGameRole == GAMEROLE_MP_Client &&
                 GuiConfig.SwatGameState == GAMESTATE_None )
        {
            StateChange( GAMESTATE_ClientTravel );
        }
        else
        {
            StateChange( GAMESTATE_EntryLoading );
        }
    }

    //always clear the current mission before level changing to avoid hanging ref problems
    GuiConfig.ClearCurrentMission();

    //cleanup actor refs
    PlayerController = None;
    CachedSGRI = None;
    MissionObjectives = None;
    Procedures = None;
    ConversationManager = None;
    TrainingTextManager = None;
}

event PostLevelChange( Player thePlayer, String MapName )
{
    local GameSpyManager GSM;

    GSM = Level.GetGameSpyManager();

    //clear the dirty flag on the server settings
    ServerSettings(Level.CurrentServerSettings).bDirty=false;

log("[dkaplan]: >>> SwatRepo::PostLevelChange()");
    if( GuiConfig.SwatGameState == GAMESTATE_EntryLoading )
    {
        Assert( InStr( MapName, "Entry" ) >= 0 ||
                InStr( MapName, SplashSceneMapName ) >= 0 );
        StateChange( GAMESTATE_None );
    }
    else if( Level.NetMode == NM_DedicatedServer )
    {
        //perform state change to PreGame now, since there will be no player login
        StateChange( GAMESTATE_PreGame );
    }

    if( thePlayer != None )
    {
        PlayerController = SwatPlayerController(thePlayer.Actor);
    }

    if ( GuiConfig.SwatGameRole == GAMEROLE_MP_Host )
    {
        // Tell the GameSpy manager that we've started a new round so it
        // should get new server info from us.
        UpdateGameSpyStats();

        //clean up gamespy any time you return to gamestate_none
        if( GuiConfig.SwatGameState == GAMESTATE_None )
        {
            //log( "In SwatRepo::PostLevelChange(). calling GSM.CleanUpGameSpy()." );
            GSM.CleanUpGameSpy();
        }

        mplog( "Setting bTravellingToNewRound to false." );
        bTravellingToNewRound = false;
    }
}

event PostBeginPlay()
{
    if( Level.NetMode == NM_Standalone ||
        Level.IsPlayingCOOP )
    {
        //if we are testing (ie, running off the command line/via UnrealEd)
        //set the current mission if not already set (only occurs if entering via the command line)
        if( GuiConfig.GetCurrentMissionName() != Level.Label )
            GuiConfig.SetCurrentMission( Level.Label, Level.Title );
        else
            GuiConfig.ResetCurrentMission();

        AssertWithDescription( GuiConfig.CurrentMission != None, "No Mission was created for level "$Level.Label );

    	MissionObjectives = GuiConfig.CurrentMission.Objectives;
        log("[MISSION] Mission Objectives created for Mission "$GuiConfig.CurrentMission);

        //hackish backup to starting the level via the command line/from the editor
        AssertWithDescription( MissionObjectives != None, "No Mission Objectives specified for mission "$GuiConfig.CurrentMission.FriendlyName );

        //create and initialize Leadership system
        Procedures = new class'Procedures';
    }
}


event PostPlayerLogin( SwatPlayerController thePC, optional EMPMode CurrentGameMode )
{
log("[dkaplan]: >>> SwatRepo::PostPlayerLogin(), the PlayerController = "$ thePC);
    PlayerController = thePC;

    if( GuiConfig.SwatGameState == GAMESTATE_LevelLoading ||
        GuiConfig.SwatGameState == GAMESTATE_ClientTravel )
    {
        StateChange( GAMESTATE_PreGame, CurrentGameMode );
    }
}


function FlushBogusPlayerItems()
{
    local int i;
    local int NumberOfPlayers;

    mplog( "---SwatRepo::FlushBogusPlayerItems()." );

    NumberOfPlayers = PlayerItems.Length;
    for ( i = NumberOfPlayers - 1; i >= 0; i-- )
    {
        if ( PlayerItems[i] != None && !PlayerItems[i].bConnected )
        {
            // Remove the item
            mplog( "...flushed PlayerItem from Repo at index="$i );
            PlayerItems.Remove( i, 1 );
        }
    }

    UpdateGameSpyStats();
}


function Logout( SwatGamePlayerController SGPC )
{
    local int i;

    // If not bTravellingToNewRound, remove the player's item from the Repo.
    mplog( "SwatRepo::Logout(). bTravellingToNewRound="$bTravellingToNewRound$", SGPC="$SGPC );

    // Add code here to remove the player's item from the repo unless
    // travelling to new round is

    if ( !bTravellingToNewRound )
    {
        for ( i = 0; i < PlayerItems.Length; ++i )
        {
            if ( PlayerItems[i] != None && PlayerItems[i] == SGPC.SwatRepoPlayerItem )
            {
                // Remove the item
                mplog( "...removed PlayerItem from Repo at index="$i );
                PlayerItems.Remove( i, 1 );
            }
        }

        UpdateGameSpyStats();
    }
    else
    {
        // We're travelling to a new round and the player is logging out, so
        // leave the playeritem in the repo and mark the player as
        // bConnected=false.
        if( SGPC.SwatRepoPlayerItem != None )
            SGPC.SwatRepoPlayerItem.bConnected = false;
    }
}


function OnMissionStarted()
{
log("[dkaplan] >>> SwatRepo::MissionStarted() "$self);
    StateChange( GAMESTATE_MidGame );
    //should be called when the round actually starts

    if( Level.Game != None )
        SwatGameInfo(Level.Game).OnMissionStarted();
}

function OnMissionEnded()
{
log("[dkaplan] >>> SwatRepo::MissionEnded() "$self);
    if( GuiConfig.SwatGameState != GAMESTATE_PostGame )
		StateChange( GAMESTATE_PostGame );
    //should be called when the round ends
}

function PreClientTravel()
{
    log("[dkaplan] >>> SwatRepo::PreClientTravel() "$self);

    StateChange( GAMESTATE_ClientTravel );
}
//////////////////////////////////////////////////////////////////////////////////
// State & Role Changes
//////////////////////////////////////////////////////////////////////////////////

function StateChange( eSwatGameState newState, optional EMPMode CurrentGameMode )
{
    local eSwatGameState oldState;
    local string errStr;
    oldState = GuiConfig.SwatGameState;
    if( oldState == GAMESTATE_ConnectionFailed &&
        !( newState == GAMESTATE_EntryLoading && bFailedServerTransitionEnabled ) )
    {
log("[dkaplan] >>> NOT StateChanging from "$self$", newState == "$GetEnum(eSwatGameState,newState)$", to oldState == "$GetEnum(eSwatGameState,oldState)$", bFailedServerTransitionEnabled = "$bFailedServerTransitionEnabled);
        return;
    }

log("[dkaplan] >>> StateChange of "$self$", newState == "$GetEnum(eSwatGameState,newState)$", oldState == "$GetEnum(eSwatGameState,oldState));
    errStr = "[dkaplan]: Attempted to state change to "$GetEnum(eSwatGameState,newState)$", but the oldState was "$GetEnum(eSwatGameState,oldState);
    Switch (newState)
    {
        case GAMESTATE_None:
            AssertWithDescription( oldState == GAMESTATE_EntryLoading ||
                                   oldState == GAMESTATE_None, errStr);
            GuiConfig.FirstTimeThrough = true;
            break;
        case GAMESTATE_EntryLoading:
            AssertWithDescription( oldState != GAMESTATE_LevelLoading, errStr);
            break;
        case GAMESTATE_LevelLoading:
            //dkaplan- removed invalid assertion, can use "open <mapname>" at any time, except while entryloading
            //AssertWithDescription( oldState == GAMESTATE_PostGame ||
            //                       oldState == GAMESTATE_None, errStr);
            AssertWithDescription( oldState != GAMESTATE_EntryLoading, errStr);
            break;
        case GAMESTATE_PreGame:
            AssertWithDescription( oldState == GAMESTATE_LevelLoading ||
                                   oldState == GAMESTATE_ClientTravel, errStr );
            if( GuiConfig.SwatGameRole == GAMEROLE_MP_Host )
            {
                bDelayedFinish=false;
                GetSGRI().ServerCountdownTime=ServerSettings(Level.CurrentServerSettings).MPMissionReadyTime + PRECACHING_FUDGE;
                //Level.Game.SetPause( true, PlayerController );

                UpdateRoundsWon( 0 );
                UpdateRoundsWon( 1 );
            }
            break;
        case GAMESTATE_MidGame:
            AssertWithDescription( oldState == GAMESTATE_PreGame || oldState == GAMESTATE_PostGame, errStr);
            if( GuiConfig.SwatGameRole == GAMEROLE_MP_Host )
            {
                NetRoundInProgress = true;
                GetSGRI().ServerCountdownTime=ServerSettings(Level.CurrentServerSettings).RoundTimeLimit;
                //Level.Game.SetPause( false, PlayerController );
            }
            break;
        case GAMESTATE_PostGame:
            AssertWithDescription( oldState == GAMESTATE_MidGame, errStr);
            log( "......FirstTimeThrough="$GuiConfig.FirstTimeThrough );
            log( "......SwatGameRole="$GuiConfig.SwatGameRole );

            if( GuiConfig.SwatGameRole == GAMEROLE_MP_Client ||
                GuiConfig.SwatGameRole == GAMEROLE_MP_Host )
            {
                GuiConfig.FirstTimeThrough = false;
            }
            else
            {
                SwatGameInfo(Level.Game).MissionEnded();
            }

            if( GuiConfig.SwatGameRole == GAMEROLE_MP_Host )
            {
                GetSGRI().ServerCountdownTime=ServerSettings(Level.CurrentServerSettings).PostGameTimeLimit;
            }

            NetRoundInProgress = false;
            break;
        case GAMESTATE_ClientTravel:
            AssertWithDescription( oldState == GAMESTATE_None ||
                                   oldState == GAMESTATE_PreGame ||
                                   oldState == GAMESTATE_MidGame ||
                                   oldState == GAMESTATE_PostGame, errStr );
            break;
        case GAMESTATE_ConnectionFailed:
            bFailedServerTransitionEnabled=false;
            break;
    }

    //reset timeout vars on state changes
    if( GuiConfig.SwatGameRole == GAMEROLE_MP_Client )
    {
        LastServerTime = GetSGRI().ServerCountdownTime;
        CumulativeDelta=0;
    }

    GuiConfig.SwatGameState = newState;

    if( SwatGUIControllerBase(GUIController) != None )
        SwatGUIControllerBase(GUIController).OnStateChange( oldState, newState, CurrentGameMode );
    if( PlayerController != None )
        PlayerController.OnStateChange( oldState, newState );
}

function RoleChange( eSwatGameRole newRole )
{
    local eSwatGameRole oldRole;
    oldRole = GuiConfig.SwatGameRole;
log("[dkaplan] >>> RoleChange of "$self$", newRole == "$GetEnum(eSwatGameRole,newRole)$", oldRole == "$GetEnum(eSwatGameRole,oldRole));
    if( oldRole == newRole )
        return;

    GuiConfig.SwatGameRole = newRole;

    if( SwatGUIControllerBase(GUIController) != None )
        SwatGUIControllerBase(GUIController).OnRoleChange( oldRole, newRole );
    if( PlayerController != None )
        PlayerController.OnRoleChange( oldRole, newRole );
}

function Campaign GetCampaign()
{
  return SwatGUIControllerBase(GUIController).GetCampaign();
}

function UpdateCampaignPawnDied(Pawn Died) {
  if(GuiConfig.SwatGameRole == GAMEROLE_SP_Campaign) {
    SwatGUIControllerBase(GUIController).UpdateCampaignDeathInformation(Died);
  }
}

function bool CheckOfficerPermadeathInformation(int OfficerSpawnName) {
  return SwatGUIControllerBase(GUIController).CheckCampaignForOfficerSpawn(OfficerSpawnName);
}

function OnCriticalMoment()
{
log("[dkaplan] >>> SwatRepo::OnCriticalMoment() "$self$", GuiConfig.CriticalMomentDelay = "$GuiConfig.CriticalMomentDelay);
    if( GuiConfig.CriticalMomentDelay > 0 )
        CriticalMomentCountdown = GuiConfig.CriticalMomentDelay;
    else
        OnDelayedCriticalMoment();
}

function OnDelayedCriticalMoment()
{
log("[dkaplan] >>> SwatRepo::OnDelayedCriticalMoment() "$self);

    if( GuiConfig.CurrentMission.IsMissionTerminal() ||
        ( /*dkaplan: this should be done in both SP and MP...
            GuiConfig.SwatGameRole == GAMEROLE_MP_Host && */
          !MissionObjectives.AnyVisibleObjectivesInProgress() && Procedures.ProceduresMaxed() ) )
    {
        SwatGameInfo(Level.Game).GameAbort();
    }
}


function FailedServerConnection()
{
log( "[dkaplan] >>> SwatRepo::FailedServerConnection()");

    //ensure the pending connection gets killed now
    Level.ConsoleCommand("KILLNET");

    StateChange( GAMESTATE_ConnectionFailed );
}

function FailedConnectionAccepted()
{
log( "[dkaplan] >>> SwatRepo::FailedConnectionAccepted()");
    bFailedServerTransitionEnabled=true;
}


event NetworkClientLoading()
{
    log( self$"::NetworkClientLoading()" );

    RoleChange(GAMEROLE_MP_Client);

    NetworkPlayerLoading();
}

event NetworkHostLoading()
{
    log( self$"::NetworkHostLoading()" );

    RoleChange(GAMEROLE_MP_Host);

    NetworkPlayerLoading();
}

function NetworkPlayerLoading()
{
    log( self$"::NetworkPlayerLoading()" );

    //handle initial connection as a gamespy client
    if( SwatGUIControllerBase(GUIController) != None )
    {
        SwatGUIControllerBase(GUIController).OnNetworkPlayerLoading();
    }
    else
    {
        //if the GUIController does not exist at this point, we are initializing
        //  as a network client
        bInitAsNetPlayer = true;
    }
}

//called when a disconnect happens
event OnDisconnected()
{
    if( SwatGUIControllerBase(GUIController) != None )
    {
        SwatGUIControllerBase(GUIController).OnDisconnected();
    }
}


//////////////////////////////////////////////////////////////////////////////////
// Control functions
//////////////////////////////////////////////////////////////////////////////////

final function CheckAllPlayersReady()
{
    assert( GuiConfig.SwatGameRole == GAMEROLE_MP_Host );

//log("[dkaplan] >>> CheckAllPlayersReady()" );
    if( SwatGameReplicationInfo(Level.Game.GameReplicationInfo).AllPlayersAreReady() )
        AllPlayersReady();
}

final function AllPlayersReady()
{
    log("[dkaplan] >>> AllPlayersReady()" );

    SwatGameReplicationInfo(Level.Game.GameReplicationInfo).ResetPlayerReadyValues();

    if ( GuiConfig.SwatGameState == GAMESTATE_PreGame )
    {
        NetRoundStart();
    }
    else if ( GuiConfig.SwatGameState == GAMESTATE_PostGame )
    {
        NetNextRound();
    }
}


function SwapServerSettings()
{
    local Actor tempRef;

    //exchange pending & current settings for new round
    tempRef = Level.CurrentServerSettings;
    Level.CurrentServerSettings = Level.PendingServerSettings;
    Level.PendingServerSettings = tempRef;
}

///////////////////////////////////////////////////////////////////////////////
//
//  Determine whether or not to quick restart the next round
//
function NetNextRound()
{
    local SwatGameReplicationInfo SGRI;

    SGRI = GetSGRI();

    if(SwatGUIControllerBase(GUIController).coopcampaign && SGRI.NextMap == "")
    {
      // we CANNOT go to a next map until the host has picked a new map!
      return;
    }

    log("[dkaplan] >>> NetNextRound()" );

    SwapServerSettings();

    ServerSettings(Level.CurrentServerSettings).RoundNumber++;
    if( ServerSettings(Level.CurrentServerSettings).bDirty )
    {
        ServerSettings(Level.CurrentServerSettings).RoundNumber = 0;
        ClearRoundsWon();

        NetSwitchLevels();
    }
    else if( ServerSettings(Level.CurrentServerSettings).RoundNumber >= ServerSettings(Level.CurrentServerSettings).NumRounds )
    {
        ServerSettings(Level.CurrentServerSettings).RoundNumber = 0;
        ClearRoundsWon();

        NetSwitchLevels( true ); //advance to the next map
    }
    else if( !ServerSettings(Level.CurrentServerSettings).bQuickRoundReset )
    {
        NetSwitchLevels();
    }
    else
    {
        NetQuickStartNextRound();
    }

    log( "Advancing to the next round... ServerSettings(Level.CurrentServerSettings).RoundNumber="$ServerSettings(Level.CurrentServerSettings).RoundNumber$", ServerSettings(Level.CurrentServerSettings).NumRounds="$ServerSettings(Level.CurrentServerSettings).NumRounds$", ServerSettings(Level.CurrentServerSettings).MapIndex="$ServerSettings(Level.CurrentServerSettings).MapIndex );
}

function FinalizeStats()
{
    local SwatGameInfo SGI;

	SGI = SwatGameInfo(Level.Game);

    if( !ServerSettings(Level.CurrentServerSettings).bDirty && ServerSettings(Level.CurrentServerSettings).RoundNumber+1 >= ServerSettings(Level.CurrentServerSettings).NumRounds )
    {
		// send number of rounds played
		SGI.ServerStats.StatInt("rounds", ServerSettings(Level.CurrentServerSettings).NumRounds, None, '', '', true);

		// send game was complete
		SGI.ServerStats.StatInt("completed", 1, None, '', '', true);
	}
}

///////////////////////////////////////////////////////////////////////////////
// Perform a full SwitchLevel to the next Map
///////////////////////////////////////////////////////////////////////////////
function NetSwitchLevels( optional bool bAdvanceToNextMap )
{
    local SwatGameReplicationInfo SGRI;
    local int NextMapIndex;

    SGRI = GetSGRI();

    log("[dkaplan] >>> NetSwitchLevels()" );

    Assert( Level.NetMode != NM_Client );

    //don't advance to the next round if the server settings changed and a round was selected
    if(!SwatGuiControllerBase(GUIController).coopcampaign)
    {
      if( bAdvanceToNextMap )
      {
          ServerSettings(Level.CurrentServerSettings).MapIndex++;
          if( ServerSettings(Level.CurrentServerSettings).MapIndex >= ServerSettings(Level.CurrentServerSettings).NumMaps )
              ServerSettings(Level.CurrentServerSettings).MapIndex = 0;
      }
      NextMapIndex = ServerSettings(Level.CurrentServerSettings).MapIndex + 1;
      if(NextMapIndex >= ServerSettings(Level.CurrentServerSettings).NumMaps) {
        NextMapIndex = 0;
      }
      SGRI.NextMap = ServerSettings(Level.CurrentServerSettings).Maps[NextMapIndex];
    }

    ServerSettings(Level.CurrentServerSettings).SaveConfig();

    FlushBogusPlayerItems();
    SetTravellingToNewRound();

    log( "Beginning a new Map... ServerSettings(Level.CurrentServerSettings).RoundNumber="$ServerSettings(Level.CurrentServerSettings).RoundNumber$", ServerSettings(Level.CurrentServerSettings).NumRounds="$ServerSettings(Level.CurrentServerSettings).NumRounds$", ServerSettings(Level.CurrentServerSettings).MapIndex="$ServerSettings(Level.CurrentServerSettings).MapIndex );

    if(SwatGuiControllerBase(GUIController).coopcampaign)
    {
      Level.ServerTravel( SGRI.NextMap, false );
    }
    else
    {
      Level.ServerTravel( ServerSettings(Level.CurrentServerSettings).Maps[ServerSettings(Level.CurrentServerSettings).MapIndex], false );
    }
}

function NetSwitchLevelsFromMapVote( String URL )
{
    log("[ryan] >>> NetSwitchLevelsFromMapVote()" );

    Assert( Level.NetMode != NM_Client );

	FlushBogusPlayerItems();
    SetTravellingToNewRound();

    Level.ServerTravel( URL, false );
}

///////////////////////////////////////////////////////////////////////////////
// Perform a quick round reset on the current Map
///////////////////////////////////////////////////////////////////////////////
function NetQuickStartNextRound()
{
    local SwatGameInfo SGI;
	local ServerSettings CurrentSettings;
log("[dkaplan] >>> NetStartNextRound()" );

	CurrentSettings = ServerSettings(Level.CurrentServerSettings);

    //save the current server settings
    CurrentSettings.SaveConfig();
    //reset config on the pending settings to match the current settings
	ServerSettings(Level.PendingServerSettings).SetServerSettings(
		None,
		CurrentSettings.GameType,
		CurrentSettings.MapIndex,
		CurrentSettings.NumRounds,
		CurrentSettings.MaxPlayers,
		CurrentSettings.DeathLimit,
		CurrentSettings.PostGameTimeLimit,
		CurrentSettings.RoundTimeLimit,
		CurrentSettings.MPMissionReadyTime,
		CurrentSettings.bShowTeammateNames,
		CurrentSettings.bShowEnemyNames,
		CurrentSettings.bAllowReferendums,
		CurrentSettings.bNoRespawn,
		CurrentSettings.bQuickRoundReset,
		CurrentSettings.FriendlyFireAmount,
		CurrentSettings.EnemyFireAmount,
		CurrentSettings.ArrestRoundTimeDeduction,
		CurrentSettings.AdditionalRespawnTime,
		CurrentSettings.bNoLeaders,
		CurrentSettings.bUseStatTracking,
		CurrentSettings.bDisableTeamSpecificWeapons
	);
	ServerSettings(Level.PendingServerSettings).RoundNumber = CurrentSettings.RoundNumber;

    SGI = SwatGameInfo(Level.Game);

    SGI.PreQuickRoundRestart();

    //reset the GameMode
    SGI.InitializeGameMode();

    //Reset OnMissionStarted listeners
    SGI.OnMissionStarted();

    //start the next round
    NetRoundStart();
}


///////////////////////////////////////
function NetRoundStart()
{
    local Controller Controller;
    local SwatGamePlayerController SwatController;
    local SwatGameInfo SGI;
    local SwatGameReplicationInfo SGRI;
    local int NextMapIndex;

log("[dkaplan] >>> NetRoundStart()" );

    log( "SwatRepo::NetRoundStart() called." );

    SGRI = GetSGRI();

    if(!SwatGUIControllerBase(GUIController).coopcampaign)
    {
      NextMapIndex = ServerSettings(Level.CurrentServerSettings).MapIndex + 1;
      if(NextMapIndex >= ServerSettings(Level.CurrentServerSettings).NumMaps) {
        NextMapIndex = 0;
      }
      SGRI.NextMap = ServerSettings(Level.CurrentServerSettings).Maps[NextMapIndex];
    }
    else
    {
      SGRI.NextMap = "";
    }

    SGI = SwatGameInfo(Level.Game);
    assert( SGI != None );

    // If the reconnecting players haven't made it back in before the round
    // starts, they lose their spot. Flush the items here.
    FlushBogusPlayerItems();

    // Set the StartCluster to use for each team.
    SGI.SetStartClustersForRoundStart();

    // Do things like select the VIP...
    SGI.AssignPlayerRoles();

    if( Level.NetMode == NM_DedicatedServer )
    {
        //perform state change to MidGame now, since there will be no player
        OnMissionStarted();
    }

    // Restart players
    for (Controller = Level.ControllerList; Controller != None; Controller = Controller.NextController)
    {
        SwatController = SwatGamePlayerController(Controller);
        if (SwatController != None && SwatController.SwatRepoPlayerItem != None && SwatController.SwatRepoPlayerItem.IsReadyToSpawn() )
        {
            SGI.RestartPlayer(Controller);
            SwatController.SwatRepoPlayerItem.SetHasEnteredFirstRound();
            SwatController.ClientRoundStarted();
        }
    }
}

///////////////////////////////////////
function OnNetRoundFinished( ESwatRoundOutcome RoundOutcome )
{
    local string result;
    //local Controller Controller;

    log( "SwatRepo::OnNetRoundFinished() called." );

//log( "dkaplan ..... setting bDelayedFinish=true" );
    bDelayedFinish=true;
    SwatGameInfo(Level.Game).NetRoundTimeRemaining( 0 );
    SwatGameInfo(Level.Game).MissionEnded();

    GetSGRI().ServerCountdownTime = GuiConfig.MPPostMissionTime;

    switch (RoundOutcome)
    {
        case SRO_COOPCompleted:
            Level.Game.Broadcast( None, "", 'COOPCompleted' );
            break;
        case SRO_COOPFailed:
            Level.Game.Broadcast( None, "", 'COOPFailed' );
            break;

        case SRO_SuspectsVictoriousNormal:
            result = GuiConfig.MPSuspectsWinMessage;
            Level.Game.Broadcast( None, result, 'SuspectsWin' );
            break;
        case SRO_SwatVictoriousNormal:
            result = GuiConfig.MPSWATWinMessage;
            Level.Game.Broadcast( None, result, 'SwatWin' );
            break;

        case SRO_SwatVictoriousRapidDeployment:
            Level.Game.Broadcast( None, "", 'AllBombsDisarmed' );
            break;
        case SRO_SuspectsVictoriousRapidDeployment:
            Level.Game.Broadcast( None, "", 'BombExploded' );
            break;

        case SRO_SwatVictoriousVIPEscaped:
            Level.Game.Broadcast( None, "", 'VIPSafe' );
            break;
        case SRO_SuspectsVictoriousKilledVIPValid:
            Level.Game.Broadcast( None, "", 'WinSuspectsBadKill' );
            break;
        case SRO_SwatVictoriousSuspectsKilledVIPInvalid:
            Level.Game.Broadcast( None, "", 'WinSwatBadKill' );
            break;
        case SRO_SuspectsVictoriousSwatKilledVIP:
            Level.Game.Broadcast( None, "", 'WinSuspectsGoodKill' );
            break;
        case SRO_RoundEndedInTie:
            result = GuiConfig.MPTieMessage;
            Level.Game.Broadcast( None, result, 'GameTied' );
            break;

        case SRO_SuspectsVictoriousSmashAndGrab:
            result = GuiConfig.MPSuspectsWinMessage;
            Level.Game.Broadcast( None, result, 'SuspectsWinSmashAndGrab' );
            break;
        case SRO_SwatVictoriousSmashAndGrab:
            result = GuiConfig.MPSWATWinMessage;
            Level.Game.Broadcast( None, result, 'SwatWinSmashAndGrab' );
            break;

        default:
            AssertWithDescription( false, "Invalid RoundOutcome in SwatRepo::OnNetRoundFinished(). outcome="$RoundOutcome );
    }

    //for (Controller = Level.ControllerList; Controller != None; Controller = Controller.NextController)
    //{
    //    if (SwatGamePlayerController(Controller) != None)
    //    {
    //        SwatGamePlayerController(Controller).ClientNetGameCompleted();
    //    }
    //}
}

private function NetRoundDelayedFinish()
{
    local Controller Controller;
    local SwatGamePlayerController SGPC;

    log( "SwatRepo::NetRoundDelayedFinish() called." );

    if( Level.NetMode == NM_DedicatedServer )
    {
        //perform state change to PostGame now, since there will be no player
        StateChange( GAMESTATE_PostGame );
    }

    for (Controller = Level.ControllerList; Controller != None; Controller = Controller.NextController)
    {
        SGPC = SwatGamePlayerController(Controller);
        if (SGPC != None)
        {
            // If the client is still in pregame, then make sure its state is
			// correct (by telling it the round started) before notifying it
			// that the round ended. This is kind of hacky, but works.
            if( !SGPC.HasEnteredFirstRoundOfNetworkGame() )
            {
                SGPC.ClientRoundStarted();
                //SGPC.SwatRepoPlayerItem.SetHasEnteredFirstRound();
            }

			SwatPlayerReplicationInfo(SGPC.PlayerReplicationInfo).COOPPlayerStatus = STATUS_NotReady;
            SGPC.GameHasEnded();
            SGPC.ClientGameEnded();
        }
    }
}
///////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Other Stuff
//////////////////////////////////////////////////////////////////////////////////

simulated function AnimationSetManager GetAnimationSetManager()
{
    return AnimationSetManager;
}

function int GetNewSwatPlayerID()
{
    SwatPlayerIDCounter++;
    log( "in SwatRepo::GetNewSwatPlayerID(). new ID="$SwatPlayerIDCounter );
    return SwatPlayerIDCounter;
}


// Returns the SwatRepoPlayerItem corresponding to SwatPlayerID. If an item is
// not found with that ID, create a new one and set its ID to it.
function SwatRepoPlayerItem GetRepoPlayerItem( int SwatPlayerID )
{
    local SwatRepoPlayerItem newItem;
    local int i;

    log( "in SwatRepo::GetRepoPlayerItem(). ID="$SwatPlayerID );

    for ( i = 0; i < PlayerItems.Length; ++i )
    {
        if ( (PlayerItems[i] != None) && (PlayerItems[i].SwatPlayerID == SwatPlayerID) )
        {
            return PlayerItems[i];
        }
    }

    // If we got here, we need to create the new item.
    newItem = new class'SwatRepoPlayerItem';
    newItem.SwatPlayerID = SwatPlayerID;
    PlayerItems[ PlayerItems.Length ] = newItem;
    newItem.bIsAReconnectingClient = false;
    newItem.bHasEnteredFirstRound = false;

    UpdateGameSpyStats();

    return newItem;
}


function int NumberOfRepoPlayerItems()
{
    local int i;
    local int count;

    count = 0;
    for ( i = 0; i < PlayerItems.Length; ++i )
    {
        if ( PlayerItems[i] != None )
        {
            ++count;
        }
    }

    return count;
}

function int NumberOfPlayersWhoShouldReturn()
{
    local int i;
    local int count;

    count = 0;
    for ( i = 0; i < PlayerItems.Length; ++i )
    {
        if ( PlayerItems[i] != None && PlayerItems[i].bIsAReconnectingClient == true )
        {
            ++count;
        }
    }

    return count;
}

function SetTravellingToNewRound()
{
    local int i;

    mplog( "Setting bTravellingToNewRound to true." );
    bTravellingToNewRound = true;

    // For all the repoplayeritems, set their bIsAReconnectingClient variables
    // to true.
    for ( i = 0; i < PlayerItems.Length; ++i )
    {
        if ( PlayerItems[i] != None )
        {
            PlayerItems[i].bIsAReconnectingClient = true;
        }
    }
}

// Set whether the player and his team should start from the primary or
// secondary set of entry points in a single player mission.
final function SetDesiredEntryPoint(EEntryType EntrySet)
{
	GuiConfig.SetDesiredEntryPoint( EntrySet );
}

final function EEntryType GetDesiredEntryPoint()
{
    return GuiConfig.GetDesiredEntryPoint();
}

function bool GetTravellingToNewRound() { return bTravellingToNewRound; }

function bool IsLANOnlyGame()
{
    return ServerSettings(Level.CurrentServerSettings).bLAN;
}

function SetSGRI( SwatGameReplicationInfo SGRI )
{
    CachedSGRI = SGRI;
}


function SwatGameReplicationInfo GetSGRI()
{
    // Only use the PlayerController to get the GameReplicationInfo on the
    // server, since on clients the PlayerController is the one in the entry
    // level and doesn't have a GameReplicationInfo.
    if ( GuiConfig.SwatGameRole == GAMEROLE_MP_Host )
    {
        if ( CachedSGRI == None )
        {
            CachedSGRI = SwatGameReplicationInfo(Level.GetGameReplicationInfo());
        }
    }

    return CachedSGRI;
}

function EMPMode GetGameMode()
{
	return ServerSettings(Level.CurrentServerSettings).GameType;
}

function float GetExternalDamageModifier( Actor Damager, Actor Victim )
{
    //NetPlayers are damaged according to the appropriate server settings
    //  for enemy damage and team damage
    if( NetPlayer(Damager) != none && NetPlayer(Victim) != None )
    {
        if( NetPlayer(Damager).GetTeamNumber() == NetPlayer(Victim).GetTeamNumber() )
            return GetFriendlyFireModifier();
        else
            return GetEnemyFireModifier();
    }
    else
        return Super.GetExternalDamageModifier( Damager, Victim );
}

function float GetFriendlyFireModifier()
{
    if( ServerSettings(Level.CurrentServerSettings).EnemyFireAmount == 0.0 )
        return 0.0;

    return ServerSettings(Level.CurrentServerSettings).FriendlyFireAmount;
}

function float GetEnemyFireModifier()
{
    return ServerSettings(Level.CurrentServerSettings).EnemyFireAmount;
}

function TrainingTextManager GetTrainingTextManager()
{
    if (TrainingTextManager == None)
    {
        TrainingTextManager = Level.Spawn(class'TrainingTextManager');
        assertWithDescription(TrainingTextManager != None,
            "[tcohen] SwatRepo::GetTrainingTextManager() failed to Spawn() the TrainingTextManager.");
    }

    return TrainingTextManager;
}

function ConversationManager GetConversationManager()
{
    if (ConversationManager == None)
    {
        ConversationManager = Level.Spawn(class'ConversationManager');
        assertWithDescription(ConversationManager != None,
            "[tcohen] SwatRepo::GetConversationManager() failed to Spawn() the ConversationManager.");
    }

    return ConversationManager;
}

// Execute only on server.
function int NumberOfReturnedPlayers()
{
    local Controller Controller;
    local SwatGamePlayerController SwatController;
    local int count;

    // Count the number of playercontrollers whose are reconnecting clients.
    count = 0;
    for ( Controller = Level.ControllerList; Controller != None; Controller = Controller.NextController )
    {
        SwatController = SwatGamePlayerController(Controller);
        if (SwatController != None)
        {
            if ( SwatController.IsAReconnectingClient() )
            {
                ++count;
            }
        }
    }

    return count;
}

// Execute only on server. Return true if there are any active players on the server
function bool AnyPlayersOnServer()
{
    local Controller Controller;

    for ( Controller = Level.ControllerList; Controller != None; Controller = Controller.NextController )
    {
        if (SwatGamePlayerController(Controller) != None)
        {
            return true;
        }
    }

    return false;
}


function SetObjectiveVisibility( name ObjectiveName, bool Visible )
{
    local int i;

    for (i=0; i<MissionObjectives.Objectives.length; ++i)
    {
        if (MissionObjectives.Objectives[i].name == ObjectiveName)
        {
            MissionObjectives.Objectives[i].SetVisibility(Visible);
            return;
        }
    }

    assertWithDescription(false,
        "[tcohen] ActionSetObjectiveVisibility::Execute() The Objective named "$ObjectiveName
        $" was not found to be a current Objective.");
}

function ClearRoundsWon()
{
    local int i;

    for( i = 0; i < 2; i++ )
    {
        RoundsWon[i] = 0;
        UpdateRoundsWon( i );
    }
}

function IncrementRoundsWon( int teamID )
{
    RoundsWon[teamID]++;
    UpdateRoundsWon( teamID );
}

function UpdateRoundsWon( int teamID )
{
    NetTeam(GetSGRI().Teams[teamID]).NetScoreInfo.SetRoundsWon( RoundsWon[teamID] );
}


function PreLevelChangeCleanup()
{
    local Pawn P;

    if( SwatGUIControllerBase(GUIController) != None )
        SwatGUIControllerBase(GUIController).PreLevelChangeCleanup();

    mplog( "PreLevelChangeCleanup: destroying all pawns..." );

    // The audio system crashes if we do ragdolls after being told to
    // ClientTravel(). We'll just destroy all pawns here, since we will never
    // need them after this point anyway. The program will crash if Level ==
    // None, which it will be when starting up the program and going into the
    // entry level, so don't do anything unless Level is valid.
    if ( Level != None )
    {
        foreach Level.DynamicActors( class'Pawn', P )
        {
            P.Destroy();
        }
    }
}

function UpdateGameSpyStats()
{
    local GameSpyManager GSM;

    GSM = Level.GetGameSpyManager();
    if ( GSM != None )
        GSM.SendServerStateChanged();
}

#if IG_CAPTIONS //used for determining if captions should be displayed by the effects system
event bool ShouldShowSubtitles()
{
    return GuiConfig.bShowSubtitles;
}
#endif
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    PRECACHING_FUDGE=30.0
}
