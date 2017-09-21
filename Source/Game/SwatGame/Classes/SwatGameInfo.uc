class SwatGameInfo extends Engine.GameInfo
    implements IInterested_GameEvent_EvidenceSecured,
               IInterested_GameEvent_ReportableReportedToTOC
    config(SwatGame)
    dependsOn(SwatStartPointBase)
	dependsOn(SwatOfficerStart)
    dependsOn(SwatGUIConfig)
    native;

import enum eDifficultyLevel from SwatGUIConfig;
import enum EEntryType from SwatGame.SwatStartPointBase;
import enum Pocket from Engine.HandheldEquipment;
import enum EOfficerStartType from SwatGame.SwatOfficerStart;
import enum EMPMode from Engine.Repo;

// Defines the multiplayer team
enum EMPTeam
{
    // @NOTE: The order of these is currently very important!! MPT_Swat must
    // be 0, and MPT_Suspects must be 1.
	MPT_Swat,    // The SWAT team
	MPT_Suspects // The "Bad Guys" team
};

// Used to indicate the outcome of a multiplayer round
enum ESwatRoundOutcome
{
	SRO_SwatVictoriousNormal,
	SRO_SuspectsVictoriousNormal,
	SRO_SwatVictoriousRapidDeployment,
	SRO_SuspectsVictoriousRapidDeployment,
	SRO_RoundEndedInTie,
	SRO_SwatVictoriousVIPEscaped,
	SRO_SuspectsVictoriousKilledVIPValid,
	SRO_SwatVictoriousSuspectsKilledVIPInvalid,
	SRO_SuspectsVictoriousSwatKilledVIP,
	SRO_COOPCompleted,
	SRO_COOPFailed,
	SRO_SwatVictoriousSmashAndGrab,
	SRO_SuspectsVictoriousSmashAndGrab
};

var private array<Mesh> PrecacheMeshes;
var private array<StaticMesh> PrecacheStaticMeshes;
var private array<Material> PrecacheMaterials;
var private bool LevelHasFemaleCharacters;

var bool bDebugFrames;
var array<DebugFrameData> DebugFrameData;
var DebugFrameData CurrentDebugFrameData;

var private SpawningManager SpawningManager;

// The Repo
var public SwatRepo Repo;


var GameEventsContainer GameEvents;

var private Timer ObjectiveTimer;

var private NavigationPoint LastPlayerStartSpot;    // last place player looking for start spot started from
var private NavigationPoint LastStartSpot;          // last place any player started from

var private array<PlayerStart> PlayerStartArray;
var private int NextPlayerStartPoint;

// Contains a reference to the current GameMode if our netmode is standalone
// or we are on the server. On network clients, there's no GameInfo anyway.
var private GameMode GameMode;

// Keep track of the last time we called NetRoundTimeRemaining() on the GameMode.
var private int PreviousNetRoundTimeRemaining;

// Global damage modifiers for Single Player games base on difficulty setting
var private config float SPDamageModifierEasy;
var private config float SPDamageModifierNormal;
var private config float SPDamageModifierHard;
var private config float SPDamageModifierElite;

// Global damage modifier for MultiPlayer games
var private config float MPDamageModifier;
var private config float COOPDamageModifier;

// Number of officers that were spawned
var private int NumSpawnedOfficers;

var config bool DebugObjectives;
var config bool DebugLeadership;
var config bool DebugLeadershipStatus;
var config bool DebugSpawning;

var private bool bAlreadyCompleted;
var private bool bAlreadyFailed;
var private bool bAlreadyEnded;

//Update interval for the objectives and procedures
var private config float ScoringUpdateInterval;
//Timer for objectives & procedures updates
var private Timer ScoringUpdateTimer;
var private Timer ReconnectionTimer;
var private config float ReconnectionTime;
var private bool bStatsNewGameStarted;

var string DefaultVoiceChannel; // default active channel for incoming players
var config bool	bAllowPrivateChat;	// Allow private chat channels on this server
var() string VoiceReplicationInfoType;

//admin feature management
var SwatAdmin Admin;

var config string MPStatsClass;
var StatsInterface ServerStats;

delegate MissionObjectiveTimeExpired();

///////////////////////////////////////////////////////////////////////////////

function PreBeginPlay()
{
    local SwatPlayerStart Point;

	ServerStats = new class<StatsInterface>(DynamicLoadObject(StatsClass(), class'class'));
	ServerStats.SetLevel(Level);

    label = 'Game';

    Repo = SwatRepo(Level.GetRepo());

    // ckline: Only debug objectives, leadership, and spawning if
    // EnableDevTools=true in [Engine.GameEngine] section
    // of Swat4.ini
    DebugObjectives = DebugObjectives && Level.GetEngine().EnableDevTools;
    DebugLeadership = DebugLeadership && Level.GetEngine().EnableDevTools;
    DebugLeadershipStatus = DebugLeadershipStatus && Level.GetEngine().EnableDevTools;
    DebugSpawning = DebugSpawning && Level.GetEngine().EnableDevTools;

    bAlreadyCompleted=false;
    bAlreadyFailed=false;
    bAlreadyEnded=false;
	bPostGameStarted=false;

    // GameEvents needs to exist before the call to Super.PreBeginPlay,
    // which in turn calls InitGameReplicationInfo, which creates the
    // team objects, which depend on GameEvents upon their creation.
    // @TODO: Write a lazy creation accessor for it, make the variable
    // private, and restrict access through that accessor only. [darren]
    GameEvents = new class'GameEventsContainer';

    // In a single player game, we want the player pawns to be spawned
    // immediately. In multiplayer, players start in limbo until choosing
    // their team. [darren]
    if (Level.NetMode != NM_Standalone)
    {
        bDelayedStart = true;
        bTeamGame = true;
    }

    Super.PreBeginPlay();

    Admin = Spawn( class'SwatAdmin' );
    Admin.SetAdminPassword( SwatRepo(Level.GetRepo()).GuiConfig.AdminPassword );

    RegisterNotifyGameStarted();

    if (bDebugFrames)
    {
        AddDebugFrameData();
    }

    // Initialize the array of player start points.
	foreach AllActors( class'SwatPlayerStart', Point )
	{
		// we don't want to spawn at Officer Start Points in single player mode
		if ((Level.NetMode != NM_Standalone) || (! Point.IsA('SwatOfficerStart')))
		{
			PlayerStartArray[PlayerStartArray.Length] = Point;
		}
	}

    if (PlayerStartArray.Length == 0)
    {
        // If we don't fatally assert here, the game will go into an infinite loop
        // spewing to the log. Which sucks.
        assertWithDescription(false , "Fatal Error: Failed to find any SwatPlayerStart points to spawn at -- make sure your start points are SwatPlayerStarts and not PlayerStarts!" );
        assert(false);
    }

    NextPlayerStartPoint = 0;

    InitializeGameMode();

    if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
    {
        SetAssertWithDescriptionShouldUseDialog( true );
	}
}


function PostBeginPlay()
{
    Super.PostBeginPlay();

    //create and initialize Mission Objectives
    if( Level.NetMode == NM_Standalone ||
        Level.IsCOOPServer )
    {
        if (GetCustomScenario() != None)
            log("[MISSION] Playing Custom Scenario");
        else
            log("[MISSION] Playing a Campaign or Multiplayer Mission (not a Custom Scenario)");

        Repo.MissionObjectives.Initialize( self );
        log("[MISSION] Mission Objectives Initialized for Mission "$Repo.GuiConfig.CurrentMission);

        SpawningManager = SpawningManager(Level.SpawningManager);
        if (SpawningManager == None)
            Warn("SKIPPING SPAWNING: This map has no SpawningManager in its LevelInfo.");
        else
        {
            SpawningManager.Initialize(Level);
            SpawningManager.DoSpawning(self);
        }

        MissionStatus();    //log initial mission status

        //initialize Leadership system
        Repo.Procedures.Init(self);


        ScoringUpdateTimer = Spawn(class'Timer');
        assert(ScoringUpdateTimer != None);
        ScoringUpdateTimer.timerDelegate = UpdateScoring;
        ScoringUpdateTimer.StartTimer( ScoringUpdateInterval, true );
    }

    Level.TickSpecialEnabled = false;

    if( Level.NetMode != NM_Standalone )
	{
		if ( Repo.NumberOfRepoPlayerItems() > GetNumPlayers() )
		{
	        ReconnectionTimer = Spawn(class'Timer');
			assert(ReconnectionTimer != None);
			ReconnectionTimer.timerDelegate = ReconnectionTimerExpired;
			ReconnectionTimer.StartTimer( ReconnectionTime );
		}
	}
}

function ReconnectionTimerExpired()
{
    //remove any bogus player items at this time
    Repo.FlushBogusPlayerItems();

    //update the waitingForPlayers flag after flushing the items
    TestWaitingForPlayersToReconnect();

    if( ReconnectionTimer != None )
        ReconnectionTimer.Destroy();
}

function TestWaitingForPlayersToReconnect()
{
    SwatGameReplicationInfo(GameReplicationInfo).SetWaitingForPlayers( Repo.NumberOfRepoPlayerItems() > GetNumPlayers() );
}

final function UpdateScoring()
{
    local int i;
    local SwatGameReplicationInfo SGRI;

    SGRI = SwatGameReplicationInfo(GameReplicationInfo);

    for( i = 0; i < SGRI.MAX_PROCEDURES; i++ )
    {
        if( i < Repo.Procedures.Procedures.Length &&
            ( Repo.GuiConfig.SwatGameState != GAMESTATE_MidGame ||
              Repo.Procedures.Procedures[i].IsShownInObjectivesPanel ) ) //Dont update PostGame only procedures during the game
        {
            SGRI.ProcedureCalculations[i] = Repo.Procedures.Procedures[i].Status();
            SGRI.ProcedureValue[i] = Repo.Procedures.Procedures[i].GetCurrentValue();
        }
    }

    for( i = 0; i < SGRI.MAX_OBJECTIVES; i++ )
    {
        if( i < Repo.MissionObjectives.Objectives.Length )
        {
			if (Repo.MissionObjectives.Objectives[i].IsHidden)
				SGRI.ObjectiveHidden[i] = 1;
			else
				SGRI.ObjectiveHidden[i] = 0;

			SGRI.ObjectiveNames[i] = String(Repo.MissionObjectives.Objectives[i].Name);
            SGRI.ObjectiveStatus[i] = Repo.MissionObjectives.Objectives[i].GetStatus();
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////////
// Special triggers
//////////////////////////////////////////////////////////////////////////////////////
function BombExploded()
{
    //broadcast the event to all clients
    Broadcast( None, "", 'BombExploded' );
    }

//////////////////////////////////////////////////////////////////////////////////////
// Mission Objectives
//////////////////////////////////////////////////////////////////////////////////////
final function ClearTimedMissionObjective()
{
    local SwatGameReplicationInfo SGRI;

    SGRI = SwatGameReplicationInfo(GameReplicationInfo);
    SGRI.SpecialTime = 0;
    SGRI.TimedObjectiveIndex = -1;

    MissionObjectiveTimeExpired = None;

    if( ObjectiveTimer != None )
	{
		ObjectiveTimer.timerDelegate = None;
        ObjectiveTimer.Destroy();
	}
}

final function SetTimedMissionObjective(Objective Objective)
{
    local SwatGameReplicationInfo SGRI;
    local int i;

	SGRI = SwatGameReplicationInfo(GameReplicationInfo);
    SGRI.SpecialTime = Objective.Time;

    for( i = 0; i < Repo.MissionObjectives.Objectives.Length; i++ )
    {
        if( Repo.MissionObjectives.Objectives[i] == Objective )
        {
            SGRI.TimedObjectiveIndex = i;
            break;
        }
	}

    MissionObjectiveTimeExpired = Objective.OnTimeExpired;

	if (ObjectiveTimer != None)
		ObjectiveTimer.StopTimer();

    ObjectiveTimer = Spawn(class'Timer');
    assert(ObjectiveTimer != None);
    ObjectiveTimer.timerDelegate = UpdateTimedMissionObjective;
    ObjectiveTimer.StartTimer( 1.0, true );
}

final function UpdateTimedMissionObjective()
{
    local SwatGameReplicationInfo SGRI;

	if (Level.IsCOOPServer && Level.NetMode != NM_Standalone && Repo.GuiConfig.SwatGameState <= GAMESTATE_PreGame)
		return;

	SGRI = SwatGameReplicationInfo(GameReplicationInfo);

    SGRI.SpecialTime--;
    if( SGRI.SpecialTime <= 0 )
        MissionObjectiveTimeExpired();
}

function SendGlobalMessage(string Message, name Type)
{
  local SwatGamePlayerController PC;

  ForEach AllActors(class'SwatGamePlayerController', PC)
  {
    PC.IssueMessage(Message, Type);
  }
}

final function OnMissionObjectiveCompleted(Objective Objective)
{
    if (DebugObjectives)
        log("[OBJECTIVES] "$Objective.name$" ("$Objective.Description$") Completed");

    //TODO/COOP: Broadcast message to all clients, have the clients internally dispatchMessage
    dispatchMessage(new class'MessageMissionObjectiveCompleted'(Objective.name));

    log("Repo("$Repo$").GuiConfig("$Repo.GuiConfig$").CurrentMission("$Repo.GuiConfig.CurrentMission$").Objectives("$Repo.GuiConfig.CurrentMission.Objectives$")");
    log("Repo("$Repo$").MissionObjectives("$Repo.MissionObjectives$")");

    if( Repo.GuiConfig.CurrentMission.IsMissionCompleted(Repo.MissionObjectives) )
    {
        if( !bAlreadyCompleted && !bAlreadyFailed )
            MissionCompleted();
        OnCriticalMoment();
    }
    else {
      SendGlobalMessage("Objective Complete!", 'ObjectiveCompleted');
    }
}

final function OnMissionObjectiveFailed(Objective Objective)
{
    if (DebugObjectives)
        log("[OBJECTIVES] "$Objective.name$" ("$Objective.Description$") Failed");

    //TODO/COOP: Broadcast message to all clients, have the clients internally dispatchMessage
    dispatchMessage(new class'MessageMissionObjectiveFailed'(Objective.name));

    if( Repo.GuiConfig.CurrentMission.IsMissionFailed() )
    {
        if( !bAlreadyFailed )
            MissionFailed();
        OnCriticalMoment();
    }
}

final function MissionCompleted()
{
    log("[dkaplan] >>> MissionCompleted" );
    bAlreadyCompleted=true;
    Broadcast( None, "", 'MissionCompleted' );

    GameEvents.ReportableReportedToTOC.Register(self);
    GameEvents.EvidenceSecured.Register(self);

    GameEvents.MissionCompleted.Triggered();
}

final function MissionFailed()
{
    log("[dkaplan] >>> MissionFailed" );
    bAlreadyFailed=true;
    Broadcast( None, "", 'MissionFailed' );

    GameEvents.ReportableReportedToTOC.Register(self);
    GameEvents.EvidenceSecured.Register(self);

    GameEvents.MissionFailed.Triggered();
}

final function MissionEnded()
{
    local SwatPlayerReplicationInfo PlayerInfo;
	local PlayerController C;
	local int i;

	log("[dkaplan] >>> MissionEnded" );

	// save stats of each player's final score
    ForEach AllActors(class'PlayerController', C)
    {
		C.Stats.Score(SwatPlayerReplicationInfo(C.PlayerReplicationInfo).NetScoreInfo.GetScore());
	}

	Repo.FinalizeStats();

	//dont trigger game ended twice
    if( bAlreadyEnded )
        return;

    //for the case where the mission ends before a mission completed/mission ended is triggered
    if( !bAlreadyCompleted && !bAlreadyFailed &&
        Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Client &&
        Repo.GuiConfig.SwatGameRole != GAMEROLE_MP_Host )
    {
        if( Repo.GuiConfig.CurrentMission.IsMissionCompleted(Repo.MissionObjectives) )
            MissionCompleted();
        else
        MissionFailed();
    }

    bAlreadyEnded=true;
    Broadcast( None, "", 'MissionEnded' );
    GameEvents.MissionEnded.Triggered();
}

//////////////////////////////////////////////////////////////////////////////////////
// Mission Termination
//////////////////////////////////////////////////////////////////////////////////////

function GameAbort()
{
    if( Repo.GuiConfig.SwatGameState != GAMESTATE_MidGame )
        return;

    if( bAlreadyEnded )
        return;

    if( Level.NetMode == NM_Standalone )
        Repo.OnMissionEnded();
    else
        GameMode.EndGame();

    //update scoring once more
    UpdateScoring();

    bAlreadyEnded=true;
}

final function OnCriticalMoment()
{
    log( "[dkaplan] in SwatGameinfo OnCriticalMoment()");
    Repo.OnCriticalMoment();
}

//interface IInterested_GameEvent_EvidenceSecured implementation
function OnEvidenceSecured(IEvidence Secured)
{
    if( bAlreadyCompleted || bAlreadyFailed )
        OnCriticalMoment();
}

//interface IInterested_GameEvent_EvidenceDestroyed implementation
function OnEvidenceDestroyed(IEvidence Destroyed)
{
	if( bAlreadyCompleted || bAlreadyFailed )
		OnCriticalMoment();
}

// IInterested_GameEvent_ReportableReportedToTOC implementation
function OnReportableReportedToTOC(IAmReportableCharacter ReportableCharacter, Pawn Reporter)
{
    if( bAlreadyCompleted || bAlreadyFailed )
        OnCriticalMoment();
}

function InitGameReplicationInfo()
{
    local SwatRepo theRepo;
    local EMPMode currentGameMode;
    local SwatGameReplicationInfo SGRI;
	local int i;

    // Do this before calling Super.InitGameReplicationInfo().
    theRepo = SwatRepo(Level.GetRepo());

	// dbeswick: commandline game mode
	if (theRepo.CommandLineGameMode != "")
	{
		for (i = 0; i < EMPMode.EnumCount; ++i)
			if (theRepo.CommandLineGameMode == string(GetEnum(enum'EMPMode', i)))
			{
				ServerSettings(Level.CurrentServerSettings).GameType = EMPMode(i);
				ServerSettings(Level.PendingServerSettings).GameType = EMPMode(i);
				log("CurrentGameMode set from commandline -"@GetEnum(enum'EMPMode', ServerSettings(Level.CurrentServerSettings).GameType));
				break;
			}
	}

	currentGameMode = ServerSettings(Level.CurrentServerSettings).GameType;

    if ( currentGameMode == MPM_BarricadedSuspects )
        GameModeString = "0";
    else if ( currentGameMode == MPM_RapidDeployment )
        GameModeString = "1";
    else if ( currentGameMode == MPM_VIPEscort )
        GameModeString = "2";
	else if ( currentGameMode == MPM_SmashAndGrab )
		GameMOdeString = "3";
    else
        GameModeString = "4";

    mplog( self$"...GameModeString="$GameModeString );

    Super.InitGameReplicationInfo();

	// We store all the fun stuff in the SwatRepo, but parts of the engine
    // would like the values stored in the appropriate placed in the
    // engine. Copy those values to the right places here.
    SGRI = SwatGameReplicationInfo(GameReplicationInfo);
    GameReplicationInfo.ServerName = ServerSettings(Level.CurrentServerSettings).ServerName;

    // Level.Title is the name was should display in the ServerBrowser
    // listings. It should be set by the designers.
    mplog( "---SwatGameInfo::InitGameReplicationInfo(). Level.Title="$Level.Title );
	SetupNameDisplay();
}

function SetupNameDisplay()
{
    local SwatGameReplicationInfo SGRI;
	local PlayerTagInterface PTI;

    SGRI = SwatGameReplicationInfo(GameReplicationInfo);
	if ( ServerSettings(Level.CurrentServerSettings).bShowTeammateNames )
        SGRI.ShowTeammateNames = 2;
    else
        SGRI.ShowTeammateNames = 1;

	mplog( "...ShowTeammateNames="$SGRI.ShowTeammateNames );
}

function InitializeGameMode()
{
    local EMPMode GUIGameMode;

    bAlreadyEnded=false;

    log( "Initializing GameMode." );

    // The game mode should be destroyed if it already exists - this will clean up the game state
    //   This allows for quick restarts
    if( GameMode != None )
    {
        GameMode.OnMissionEnded();
        GameMode.Destroy();
        GameMode = None;
    }

    Assert( GameMode == None );

    if ( Level.NetMode == NM_Standalone )
    {
        GameMode = Spawn( class'GameModeStandalone', self );
    }
    else
    {
        Assert( ServerSettings(Level.CurrentServerSettings) != None );

        GUIGameMode = ServerSettings(Level.CurrentServerSettings).GameType;

        if ( GUIGameMode == MPM_VIPEscort )
            GameMode = Spawn( class'GameModeVIP', self );
        else if ( GUIGameMode == MPM_RapidDeployment )
            GameMode = Spawn( class'GameModeRD', self );
        else if ( GUIGameMode == MPM_COOP )
            GameMode = Spawn( class'GameModeCOOP', self );
		else if ( GUIGameMode == MPM_SmashAndGrab )
			GameMode = Spawn( class'GameModeSmashAndGrab', self );
		else if ( GUIGameMode == MPM_COOPQMM )
			GameMode = Spawn( class'GameModeCOOPQMM', self );
        else
        {
            AssertWithDescription( GUIGameMode == MPM_BarricadedSuspects,
                                   "GameType was not set by GUI; defaulting to Barricaded Suspects" );
            GameMode = Spawn( class'GameModeBS', self );
        }
    }
    GameMode.Initialize();
}

function GameMode GetGameMode()
{
    return GameMode;
}

// This returns the _nonlocalized_ name of the game mode. We need it to be
// nonlocalized for sending it to the GameSpy master servers.
//
function string GetGameModeName()
{
    local EMPMode GUIGameMode;

    Assert( ServerSettings(Level.CurrentServerSettings) != None );

    GUIGameMode = ServerSettings(Level.CurrentServerSettings).GameType;

    if ( GUIGameMode == MPM_VIPEscort )
        return "VIP Escort";
    else if ( GUIGameMode == MPM_RapidDeployment )
        return "Rapid Deployment";
    else if ( GUIGameMode == MPM_COOP )
	{
		if (SwatRepo(Level.GetRepo()).GuiConfig.CurrentMission.CustomScenario != None)
			return "CO-OP QMM";
		else
			return "CO-OP";
	}
	else if ( GUIGameMode == MPM_COOPQMM )
		return "CO-OP QMM";
	else if ( GUIGameMode == MPM_SmashAndGrab )
		return "Smash And Grab";
    else
    {
        AssertWithDescription( GUIGameMode == MPM_BarricadedSuspects,
                               "We need to get the name of the GameMode, but it hasn't been set yet; defaulting to Barricaded Suspects" );
        return "Barricaded Suspects";
    }
}

//////////////////////////////////////////////////////////
//overridden from GameInfo
function GetServerInfo( out ServerResponseLine ServerState )
{
	ServerState.ServerName		= ServerSettings(Level.CurrentServerSettings).ServerName;
	ServerState.MapName			= Level.Title;
	ServerState.GameType		= GetGameModeName();
	ServerState.CurrentPlayers	= NumberOfPlayersForServerBrowser();
	ServerState.MaxPlayers		= MaxPlayersForServerBrowser();
	ServerState.IP				= ""; // filled in at the other end.
	ServerState.Port			= GetServerPort();

	ServerState.ModName			= Level.ModName;
	ServerState.GameVersion		= Level.BuildVersion;

	ServerState.ServerInfo.Length = 0;
	ServerState.PlayerInfo.Length = 0;
}

function GetServerDetails( out ServerResponseLine ServerState )
{
	local int i;
	local Mutator M;
	local GameRules G;

	i = ServerState.ServerInfo.Length;

	// servermode
	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "servermode";
	if( Level.NetMode==NM_ListenServer )
		ServerState.ServerInfo[i++].Value = "non-dedicated";
    else
		ServerState.ServerInfo[i++].Value = "dedicated";

	// adminemail
	ServerState.ServerInfo.Length = i+1;
	ServerState.ServerInfo[i].Key = "ServerVersion";
	ServerState.ServerInfo[i++].Value = level.EngineVersion;

	// has password
	if( AccessControl.RequiresPassword() )
	{
		ServerState.ServerInfo.Length = i+1;
		ServerState.ServerInfo[i].Key = "password";
		ServerState.ServerInfo[i++].Value = "true";
	}

	// Ask the mutators if they have anything to add.
	for (M = BaseMutator.NextMutator; M != None; M = M.NextMutator)
		M.GetServerDetails(ServerState);

	// Ask the gamerules if they have anything to add.
	for ( G=GameRulesModifiers; G!=None; G=G.NextGameRules )
		G.GetServerDetails(ServerState);
}

function GetServerPlayers( out ServerResponseLine ServerState )
{
    local Mutator M;
	local Controller C;
	local SwatPlayerReplicationInfo PRI;
	local int i;

#if 1 //dkaplan: we currently don't use any of this player information in the server browser
    return;
#endif

	i = ServerState.PlayerInfo.Length;

	for( C=Level.ControllerList;C!=None;C=C.NextController )
    {
		PRI = SwatPlayerReplicationInfo(C.PlayerReplicationInfo);
		if( (PRI != None) && !PRI.bBot && MessagingSpectator(C) == None )
        {
			ServerState.PlayerInfo.Length = i+1;
			ServerState.PlayerInfo[i].PlayerNum  = PRI.SwatPlayerID;
			ServerState.PlayerInfo[i].PlayerName = PRI.PlayerName;
			ServerState.PlayerInfo[i].Score		 = PRI.netScoreInfo.GetScore();
			ServerState.PlayerInfo[i].Ping		 = PRI.Ping;
			i++;
		}
	}

	// Ask the mutators if they have anything to add.
	for (M = BaseMutator.NextMutator; M != None; M = M.NextMutator)
		M.GetServerPlayers(ServerState);
}
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

function SpawningManager GetSpawningManager()
{
    return SpawningManager;
}

function CustomScenario GetCustomScenario()
{
    if( Repo.GuiConfig.CurrentMission == None )
        return None;

    return Repo.GuiConfig.CurrentMission.CustomScenario;
}

function bool UsingCustomScenario()
{
    return GetCustomScenario() != None;
}

function bool CampaignObjectivesAreInEffect()
{
    if (GetCustomScenario() == None)
        return true;    //its a campaign mission

    return GetCustomScenario().UseCampaignObjectives;
}

// TODO: change incapacitations to death for swat officers
function CheckForCampaignDeath(Pawn Incapacitated)
{
  Repo.UpdateCampaignPawnDied(Incapacitated);
}

///////////////////////////////////////////////////////////////////////////


function PostGameStarted()
{
	bPostGameStarted = true;

    GameEvents.PostGameStarted.Triggered();
}

function OnGameStarted()
{
    local SwatRepo RepoObj;
    log("[dkaplan] >>> SwatGameInfo::OnGameStarted()");
    if (bDebugFrames) Enable('Tick');

    GameEvents.GameStarted.Triggered();

    //if we are in a SP mission, start the Mission now
    RepoObj = Repo;
    Assert( RepoObj != None );
    if( RepoObj.GuiConfig.SwatGameRole == GAMEROLE_None ||
        RepoObj.GuiConfig.SwatGameRole == GAMEROLE_SP_Campaign ||
        RepoObj.GuiConfig.SwatGameRole == GAMEROLE_SP_Custom ||
        RepoObj.GuiConfig.SwatGameRole == GAMEROLE_SP_Other )
        RepoObj.OnMissionStarted();

//    TestHook(); //perform any tests
}

//this is the actual start of the mission
function OnMissionStarted()
{
    Level.TickSpecialEnabled = true;

    GameEvents.MissionStarted.Triggered();

	// send a message that the level has started
	dispatchMessage(new class'Gameplay.MessageLevelStart'(GetCustomScenario() != None));
}

function bool GameInfoShouldTick() { return bDebugFrames || Level.GetGameSpyManager().bTrackingStats; }

function Tick(float DeltaTime)
{
	local SwatGamePlayerController PC;

    Super.Tick(DeltaTime);

    if ( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer )
    {
		if (!bStatsNewGameStarted && Level.GetGameSpyManager().bStatsInitalised)
		{
			bStatsNewGameStarted = Level.GetGameSpyManager().StatsNewGameStarted();
			if (bStatsNewGameStarted)
			{
				log("[STATS] New game started");

				// stats
				ServerStats.StatStr("hostname", GameReplicationInfo.ServerName);
				ServerStats.StatStr("gamever", Level.BuildVersion);
				ServerStats.StatStr("mapname", string(Level.Outer.Name));
				ServerStats.StatStr("gametype", string(GameMode.class.name));

				// do all player names
				ForEach AllActors(class'SwatGamePlayerController', PC)
				{
					PC.Stats.StatStr("player", PC.PlayerReplicationInfo.PlayerName);
					PC.Stats.TeamChange(PC.PlayerReplicationInfo.TeamID);
				}
			}
		}
	}

	if (bDebugFrames)
    {
    	//record the last frame time
    	CurrentDebugFrameData.DeltaTime = DeltaTime;
        //prepare a new DebugFrameData for the current frame
    	AddDebugFrameData();
    }
}

function bool AllowRoundStart()
{
	return GameMode.AllowRoundStart();
}

function NetRoundTimeRemaining( float TimeRemaining )
{
    local int IntTimeRemaining;

    Assert( Level.NetMode != NM_Standalone );

    IntTimeRemaining = TimeRemaining;
    if ( IntTimeRemaining != PreviousNetRoundTimeRemaining )
    {
        PreviousNetRoundTimeRemaining = IntTimeRemaining;
        GameMode.NetRoundTimeRemaining( IntTimeRemaining );
    }
}


function NetRoundTimerExpired()
{
    Assert( Level.NetMode != NM_Standalone );
    GameMode.NetRoundTimerExpired();
}


#if IG_EFFECTS
// Dump the state of the SoundEffectsSubsystem to the log
//
// SystemName should be one of "VISUAL" or "SOUND"
exec function DumpEffects(Name SystemName)
{
    local EffectsSystem FX;
    local EffectsSubsystem SubSys;
    local Name ClassName;

    FX = EffectsSystem(Level.EffectsSystem);
    assert(FX != None);

    if (SystemName == 'SOUND')
    {
        ClassName = 'SoundEffectsSubsystem';
    }
    else if (SystemName == 'VISUAL')
    {
        ClassName = 'VisualEffectsSubsystem';
    }

    Subsys = FX.GetSubsystem(ClassName);
    if (Subsys == None)
    {
        Warn("WARNING: Cannot dump effects; subsystem not found: "$ClassName);
        return;
    }
    Subsys.LogState();
}
#endif

exec function DebugFrames(Name Option, String Param)
{
    //calculate the frame-time mean and standard deviation
    local float Mean;
    local float Variance;
    local float StandardDeviation;
    local int i;
    local bool QualifiedFrame;  //is the current frame qualified to be logged according to the user's request

    //mean
    for (i=0; i<DebugFrameData.length; ++i)
    	Mean += DebugFrameData[i].DeltaTime;
    Mean = Mean / DebugFrameData.length;

    //add squared deviations
    for (i=0; i<DebugFrameData.length; ++i)
        Variance += Square(DebugFrameData[i].DeltaTime - Mean);
    Variance = Variance / DebugFrameData.length;

    //standard deviation
    StandardDeviation = Sqrt(Variance);

    log("DebugFrames: NumFrames="$DebugFrameData.length$", MeanTime="$Mean$", StandardDeviation="$StandardDeviation);
    switch (Option)
    {
        case 'hitches':
            log("                Hitches - Frames with time > a standard deviation from the mean:");
            break;

        case 'keyword':
            log("                Keyword - Frames with the string '"$param$"' found in GuardString:");
            break;

        case 'all':
            log("                All - all frame data:");
            break;

        default:
            log("DebugFrames Usage: debugframes [name Option] [string Param]");
            log("             Options: 'hitches' (string Param ignored), 'keyword' (specified in string Param), 'all' (string param ignored)");
            return;
    }

    for (i=0; i<DebugFrameData.length; ++i)
    {
        switch (Option)
        {
            case 'hitches':
                QualifiedFrame = (DebugFrameData[i].DeltaTime > (Mean + StandardDeviation));
                break;

            case 'keyword':
                QualifiedFrame = (Instr(DebugFrameData[i].GetGuardString(), param) != -1);
                break;

            case 'all':
                QualifiedFrame = true;
                break;

            default:
                assert(false);  //unexpected option
        }

        if (QualifiedFrame)
            log("    -> Frame #"$i$": EndTime="$DebugFrameData[i].EndTimeSeconds$", DeltaTime="$DebugFrameData[i].DeltaTime$" ("$1.f/DebugFrameData[i].DeltaTime$"fps, "$abs(DebugFrameData[i].DeltaTime - Mean) / StandardDeviation$" s.d.(s) from mean), GuardString="$DebugFrameData[i].GetGuardString());
    }
}

//add a new entry to the array of DebugFrameData to represent the current frame
function AddDebugFrameData()
{
    if (CurrentDebugFrameData != None)
        CurrentDebugFrameData.EndTimeSeconds = Level.TimeSeconds;

    CurrentDebugFrameData = new class'DebugFrameData';
    DebugFrameData[DebugFrameData.length] = CurrentDebugFrameData;
}

function GuardSlow(String GuardString)
{
    CurrentDebugFrameData.AddGuardString(GuardString);
}

//override GameInfo::AddDefaultInventory() to give the player his/her LoadOut
function AddDefaultInventory(Pawn inPlayerPawn)
{
    local OfficerLoadOut LoadOut;
    local SwatPlayer PlayerPawn;
    local SwatRepoPlayerItem RepoPlayerItem;
    local NetPlayer theNetPlayer;
    local int i;
    local DynamicLoadOutSpec LoadOutSpec;
	local bool IsSuspect;

    log( "In SwatGameInfo::AddDefaultInventory(). Pawn="$inPlayerPawn);

    PlayerPawn = SwatPlayer(inPlayerPawn);
    assert(PlayerPawn != None);

    if ( Level.NetMode == NM_Standalone )
    {
        if( Level.IsTraining )
        {
            LoadOut = Spawn(class'OfficerLoadOut', PlayerPawn, 'TrainingLoadOut');
            LoadOutSpec = Spawn(class'DynamicLoadOutSpec', PlayerPawn, 'TrainingLoadOut');
        }
        else
        {
            LoadOut = Spawn(class'OfficerLoadOut', PlayerPawn, 'DefaultPlayerLoadOut');
            LoadOutSpec = Spawn(class'DynamicLoadOutSpec', PlayerPawn, 'CurrentPlayerLoadOut');
        }
        assert(LoadOut != None);

		IsSuspect = false;
    }
    else
    {
        assert( Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer );

        theNetPlayer = NetPlayer( inPlayerPawn );
        if ( theNetPlayer.IsTheVIP() )
        {
            mplog( "...this player is the VIP." );

            // The VIP must always be on the SWAT team.
            Assert( NetPlayer(PlayerPawn).GetTeamNumber() == 0 );

            LoadOut = Spawn( class'OfficerLoadOut', PlayerPawn, 'VIPLoadOut' );
            LoadOutSpec = Spawn(class'DynamicLoadOutSpec', None, 'DefaultVIPLoadOut');
            Assert( LoadOutSpec != None );

            // Copy the items from the loadout to the netplayer.
            for( i = 0; i < Pocket.EnumCount; ++i )
            {
                theNetPlayer.SetPocketItemClass( Pocket(i), LoadOutSpec.LoadOutSpec[ Pocket(i) ] );
            }

			theNetPlayer.SetCustomSkinClassName( "SwatGame.DefaultCustomSkin" );

            theNetPlayer.SwitchToMesh( theNetPlayer.VIPMesh );
        }
        else
        {
            mplog( "...this player is NOT the VIP." );

            if ( NetPlayer(PlayerPawn).GetTeamNumber() == 0 )
                LoadOut = Spawn(class'OfficerLoadOut', PlayerPawn, 'EmptyMultiplayerOfficerLoadOut' );
            else
                LoadOut = Spawn(class'OfficerLoadOut', PlayerPawn, 'EmptyMultiplayerSuspectLoadOut' );

            log( "...In AddDefaultInventory(): loadout's owner="$LoadOut.Owner );
            assert(LoadOut != None);

            // First, set all the pocket items in the NetPlayer loadout spec, so
            // that remote clients (ones who don't own the pawn) can locally spawn
            // the loadout items.
            RepoPlayerItem = SwatGamePlayerController(PlayerPawn.Controller).SwatRepoPlayerItem;

            //RepoPlayerItem.PrintLoadOutSpecToMPLog();

            // Copy the items from the loadout to the netplayer.
            for( i = 0; i < Pocket.EnumCount; ++i )
            {
                theNetPlayer.SetPocketItemClass( Pocket(i), RepoPlayerItem.RepoLoadOutSpec[ Pocket(i) ] );
            }

			if ( RepoPlayerItem.CustomSkinClassName != "" )
				theNetPlayer.SetCustomSkinClassName( RepoPlayerItem.CustomSkinClassName );
			else
				theNetPlayer.SetCustomSkinClassName( "SwatGame.DefaultCustomSkin" );

            LoadOutSpec = theNetPlayer.GetLoadoutSpec();

            // Alter it *ex post facto* to have the correct ammo counts
            LoadOutSpec.SetPrimaryAmmoCount(RepoPlayerItem.GetPrimaryAmmoCount());
            LoadOutSpec.SetSecondaryAmmoCount(RepoPlayerItem.GetSecondaryAmmoCount());
        }

		IsSuspect = theNetPlayer.GetTeamNumber() == 1;
    }

    LoadOut.Initialize( LoadOutSpec, IsSuspect );

    PlayerPawn.ReceiveLoadOut(LoadOut);

    // We have to do this after ReceiveLoadOut() because that's what sets the
    // Replicated Skins.
    if ( Level.NetMode != NM_Standalone )
        theNetPlayer.InitializeReplicatedCounts();

    //TMC TODO do this stuff in the PlayerPawn (legacy support)
	SetPlayerDefaults(PlayerPawn);
}

exec function MissionStatus()
{
    local int i;
    local Objective CurrentObjective;

    log("[MISSION STATUS]");

    for (i=0; i<Repo.MissionObjectives.Objectives.length; ++i)
    {
        CurrentObjective = Repo.MissionObjectives.Objectives[i];

        log("... Objective '"$CurrentObjective.name
        $"': "$CurrentObjective.Description
        $".  Status: "$CurrentObjective.GetStatusString());
    }
}

//returns the current leadership score for the mission
exec function int LeadershipStatus()
{
    local int i;
    local int Score;
    local Procedure CurrentProcedure;

    log("[LEADERSHIP STATUS]");

    for (i=0; i<Repo.Procedures.Procedures.length; ++i)
    {
        CurrentProcedure = Repo.Procedures.Procedures[i];

        log("... Procedure '"$CurrentProcedure.name
        $"': "$CurrentProcedure.Description
        $".  Status: "$CurrentProcedure.Status());

        Score += CurrentProcedure.GetCurrentValue();
    }

    Score = Max( 0, Score );

    log("-> Mission Score: "$Score);

    return Score;
}

// returns the 'best' player start for this player to start from.
//
// FIXME: move this to a subclass based on game type, a la UT2K3's
// game-specific GameInfo subclasses
function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string incomingName)
{
    local PlayerStart PointToUse;
	local EEntryType DesiredEntryType;
	local int IndexOfFirstCheckedPoint;

	Log("SwatGameInfo.FindPlayerStart() ");

	// Take into account whether the team should use the primary or
	// secondary entry point.

    // In a coop game, its possible for the server's desired entry point to be
    // secondary, yet be playing a map that only has a primary spawn point.
    // Since this FindPlayerStart function really only provides a temporary
    // spot, and the real multiplayer spawning happens in
    // GameMode::FindNetPlayerStart, coop servers should just look for primary
    // starts.
    if ( Level.IsCOOPServer )
	    DesiredEntryType = ET_Primary;
    else
	    DesiredEntryType = Repo.GetDesiredEntryPoint();

	// Remember the first point we checked, to avoid infinite loops
	IndexOfFirstCheckedPoint = NextPlayerStartPoint;

	// Keep looking until we find a SwatPlayerStart that is not touching any
	// other players and (if this is a single-player game) has the correct
	// entry type.
    PointToUse = PlayerStartArray[ IndexOfFirstCheckedPoint ];
    while ( PointToUse.Touching.Length > 0 ||
			!PointToUse.IsA('SwatPlayerStart') ||
			( ( Level.NetMode == NM_Standalone || Level.IsCOOPServer )
			    && SwatPlayerStart(PointToUse).EntryType != DesiredEntryType ) )
    {
        if (PointToUse.Touching.Length > 0)
			log( " FindPlayerStart(): Skipping "$PointToUse$" because it is touching "$PointToUse.Touching.Length$" actors" );
        else if (!PointToUse.IsA('SwatPlayerStart'))
			log( " FindPlayerStart(): Skipping "$PointToUse$" because it is not of class SwatPlayerStart");
        else if( ( Level.NetMode == NM_Standalone || Level.IsCOOPServer )
                 && SwatPlayerStart(PointToUse).EntryType != DesiredEntryType )
			log( " FindPlayerStart(): Skipping "$PointToUse$" because we're in a single-player or coop game and its entry type ("$GetEnum(EEntryType,SwatPlayerStart(PointToUse).EntryType)$") does not match the desired entry type ("$GetEnum(EEntryType,DesiredEntryType)$")");

		// try the next point
		NextPlayerStartPoint = NextPlayerStartPoint + 1;
        if ( NextPlayerStartPoint == PlayerStartArray.Length )
        {
            NextPlayerStartPoint = 0;
        }

		// See if we've exhausted all the possible start points
		if (NextPlayerStartPoint == IndexOfFirstCheckedPoint)
		{
			PointToUse = None;
			break;
		}
		else
		{
			PointToUse = PlayerStartArray[ NextPlayerStartPoint ];
		}
    }

	// Increment the start point so the next player to spawn won't choose the
	// same point.
    NextPlayerStartPoint = NextPlayerStartPoint + 1;
    if ( NextPlayerStartPoint == PlayerStartArray.Length )
    {
        NextPlayerStartPoint = 0;
    }

	AssertWithDescription(PointToUse != None, "Failed to find any usable SwatPlayerStart points!");

	log(" FindPlayerStart(): returning  "$PointToUse);

    return PointToUse;
}

// Override default spawning so that you don't spawn on the point another
// player has spawned on.
//
// FIXME: move this to a subclass based on game type, a la UT2K3's
// game-specific GameInfo subclasses
function float RatePlayerStart(NavigationPoint N, byte Team, Controller Player)
{
    local PlayerStart P;
    local float Score;
	//local float NextDist;
    //local Controller OtherPlayer;

    P = PlayerStart(N);

	// only log this if we're not in single player
	if (Level.NetMode != NM_Standalone)
	{
		Log("SwatGameInfo.RatePlayerStart() rating NavigationPoint "$N);
	}

    if ( (P == None) || !P.bEnabled || P.PhysicsVolume.bWaterVolume || ((Level.NetMode == NM_Standalone || Level.IsCOOPServer) && ! P.bSinglePlayerStart) )
	{
		//Log("   Final rating is -1000 because start spot is none, not enabled, or water");
        return -1000;
	}

	Log("   Base Rating is 1000");
	Score = 1000;

	if (P.TimeOfLastSpawn >= 0) // TimeOfLastSpawn is -1 if nothing has spawned there yet
	{
		Score -= Max(Level.TimeSeconds - P.TimeOfLastSpawn, 0);
  		Log("   Decreasing base to "$Score$" because someone spawned here "$
			(Level.TimeSeconds - P.TimeOfLastSpawn)$" seconds ago ("$Level.TimeSeconds$"-"$P.TimeOfLastSpawn$")");
	}

	Score = FMax(Score, 1);
	Log("   Final rating is "$Score$" after clamping to minimum of 1");
	return Score;
}


///////////////////////////////////////////////////////////////////////////////
//
//
//
function SetStartClustersForRoundStart()
{
    Assert( Role == ROLE_Authority );
    GameMode.SetStartClustersForRoundStart();
}


function AssignPlayerRoles()
{
    Assert( Role == ROLE_Authority );
    GameMode.AssignPlayerRoles();
}


// Can only be called on the server. Respawns all dead players
exec function RespawnAll()
{
    Assert( Role == ROLE_Authority );
    GameMode.RespawnAll();
}


function bool AtCapacity(bool bSpectator)
{
    local int MaxPlayerSetting;
    local int CurrentPlayers;

    if ( Level.NetMode == NM_Standalone )
		return false;

    // Find max players right now for this server.
	MaxPlayerSetting = ServerSettings(Level.CurrentServerSettings).MaxPlayers;

    // Find number of players connected to the server by counting repo
    // items. This should give us the right value whether we're in the round
    // or doing the switch level thing.
    CurrentPlayers = SwatRepo(Level.GetRepo()).NumberOfRepoPlayerItems();

    return ( (MaxPlayerSetting>0) && (CurrentPlayers>=MaxPlayerSetting) );
}

///////////////////////////////////////////////////////////////////////////////
//
// Login-related overridden functions
//

//
// Log a player in.
// Fails login if you set the Error string.
// PreLogin is called before Login, but significant game time may pass before
// Login is called, especially if content is downloaded.
//
event PlayerController Login(string Portal, string Options, out string Error)
{
    local NavigationPoint    StartSpot;
    local PlayerController   NewPlayer;
    local Pawn               TestPawn;
    local string             InName, InAdminName, InPassword, InChecksum, InClass, InCharacter;
    local byte               InTeam;
    local class<Security>    MySecurityClass;
    local int                InSwatPlayerID, NewSwatPlayerID;
    local SwatRepoPlayerItem theSwatRepoPlayerItem;

    BaseMutator.ModifyLogin(Portal, Options);

    // Get URL options.
    InName     = Left(ParseOption ( Options, "Name"), 20);
    InTeam     = GetIntOption( Options, "Team", 255 ); // default to "no team"
    InAdminName= ParseOption ( Options, "AdminName");
    InPassword = ParseOption ( Options, "Password" );
    InChecksum = ParseOption ( Options, "Checksum" );
    InSwatPlayerID = GetIntOption( Options, "SwatPlayerID", 0 ); // zero means we are
                                                                 // a new connector.

    // Make sure there is capacity except for returning players (denoted by a non-0 player id)
    if ( InSwatPlayerID == 0 && AtCapacity( false ) )
    {
        Error=GameMessageClass.Default.MaxedOutMessage;
        return None;
    }

    log( "Login:" @ InName );
    log( "  SwatPlayerID: "$InSwatPlayerID );

    if ( Level.NetMode != NM_Standalone )
    {
        // Fix up the playerID and find the repo item. Create a new one if ID is
        // zero.
        if ( InSwatPlayerID == 0 )
        {
            // The player didn't have a repo item.
            NewSwatPlayerID = Repo.GetNewSwatPlayerID();
            theSwatRepoPlayerItem = Repo.GetRepoPlayerItem( NewSwatPlayerID );
            InTeam = GetAutoJoinTeamID();
            theSwatRepoPlayerItem.SetTeamID( InTeam );
        }
        else
        {
            // The player already had a repo item.
            NewSwatPlayerID = InSwatPlayerID;
            theSwatRepoPlayerItem = Repo.GetRepoPlayerItem( NewSwatPlayerID );

			if (GetTeamFromID(theSwatRepoPlayerItem.GetPreferredTeamID()) != None)
			{
				InTeam = theSwatRepoPlayerItem.GetPreferredTeamID();

				// If the player was previously on the suspect team but we're now playing coop put the player on the red team
				if (InTeam == 1 && Level.IsCOOPServer)
					InTeam = 2;
			}
			else
			{
				InTeam = GetAutoJoinTeamID();
				theSwatRepoPlayerItem.SetTeamID( InTeam );
			}
        }
        theSwatRepoPlayerItem.bConnected = true;
    }

    // Find a start spot.

    // ckline: Note, from what I can tell, this finds a "potential" spot to
    // spawn; it's only checking the controller, not the pawn. Later, in
    // RestartPlayer, starting points will be checked again.
    StartSpot = FindPlayerStart( None, InTeam, Portal );

    if( StartSpot == None )
    {
        // Login will fail because no place could be found to spawn the player
        Error = GameMessageClass.Default.FailedPlaceMessage;
        return None;
    }

    if ( PlayerControllerClass == None )
        PlayerControllerClass = class<PlayerController>(DynamicLoadObject(PlayerControllerClassName, class'Class'));

    NewPlayer = Spawn(PlayerControllerClass,,,StartSpot.Location,StartSpot.Rotation);

    // Handle spawn failure.
    if( NewPlayer == None )
    {
        log("Couldn't spawn player controller of class "$PlayerControllerClass);
        Error = GameMessageClass.Default.FailedSpawnMessage;
        return None;
    }
    log("Spawned player "$NewPlayer$" at "$StartSpot); // ckline

    NewPlayer.StartSpot = StartSpot;

    SwatGamePlayerController(NewPlayer).SwatPlayerID = NewSwatPlayerID;
    if ( Level.NetMode != NM_Standalone )
    SwatGamePlayerController(NewPlayer).SwatRepoPlayerItem = theSwatRepoPlayerItem;

    //auto set the local PC's admin PW to be correct
    if( Level.GetLocalPlayerController() == NewPlayer )
        theSwatRepoPlayerItem.LastAdminPassword = SwatRepo(Level.GetRepo()).GuiConfig.AdminPassword;

    //attempt to log the new player in as an admin (based on their last entered password)
    Admin.AdminLogin( NewPlayer, theSwatRepoPlayerItem.LastAdminPassword );

    // Init player's replication info
    NewPlayer.GameReplicationInfo = GameReplicationInfo;

    // Apply security to this controller
    MySecurityClass=class<Security>(DynamicLoadObject(SecurityClass,class'class'));
    if (MySecurityClass!=None)
    {
        NewPlayer.PlayerSecurity = spawn(MySecurityClass,NewPlayer);
        if (NewPlayer.PlayerSecurity==None)
            log("Could not spawn security for player "$NewPlayer,'Security');
    }
    else
        log("Unknown security class ["$SecurityClass$"] -- System is no secure.",'Security');

    // Init player's name
    if( InName=="" )
        InName=DefaultPlayerName;

    newPlayer.StartSpot = StartSpot;

    // Set the player's ID.
    NewPlayer.PlayerReplicationInfo.PlayerID = CurrentID++;
    SwatPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).SwatPlayerID = NewSwatPlayerID;
    SwatPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).COOPPlayerStatus = STATUS_NotReady;

    if( Level.NetMode!=NM_Standalone || NewPlayer.PlayerReplicationInfo.PlayerName==DefaultPlayerName )
        SwatGamePlayerController(NewPlayer).SetName( InName );

	InClass = ParseOption( Options, "Class" );

    if (InClass == "")
        InClass = DefaultPlayerClassName;
    InCharacter = ParseOption(Options, "Character");
    NewPlayer.SetPawnClass(InClass, InCharacter);

    NumPlayers++;
    bWelcomePending = true;

    SetPlayerTeam( SwatGamePlayerController(NewPlayer), InTeam );

	// Marc VOIP: from Epic's UnrealMPGameInfo
	if ( Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer )
	{
		NewPlayer.VoiceReplicationInfo = VoiceReplicationInfo;
		if ( Level.NetMode == NM_ListenServer && Level.GetLocalPlayerController() == NewPlayer )
			NewPlayer.InitializeVoiceChat();
	}

    // If a multiplayer game, set playercontroller to limbo state
    if ( Level.NetMode != NM_Standalone )
    {
        if ( bDelayedStart && !SwatGamePlayerController(NewPlayer).IsAReconnectingClient() )
        {
            NewPlayer.GotoState('NetPlayerLimbo');
            return NewPlayer;
        }
    }

    // Try to match up to existing unoccupied player in level,
    // for savegames and coop level switching.
    ForEach DynamicActors(class'Pawn', TestPawn )
    {
        if ( (TestPawn!=None) && (PlayerController(TestPawn.Controller)!=None) && (PlayerController(TestPawn.Controller).Player==None) && (TestPawn.Health > 0)
            &&  (TestPawn.OwnerName~=InName) )
        {
            NewPlayer.Destroy();
            TestPawn.SetRotation(TestPawn.Controller.Rotation);
            TestPawn.bInitializeAnimation = false; // FIXME - temporary workaround for lack of meshinstance serialization
            TestPawn.PlayWaiting();
            return PlayerController(TestPawn.Controller);
        }
    }

    TestWaitingForPlayersToReconnect();

    return newPlayer;
}

///////////////////////////////////////
//
// Called after a successful login. This is the first place
// it is safe to call replicated functions on the PlayerPawn.
//
event PostLogin( PlayerController NewPlayer )
{
    local class<HUD> HudClass;
    local class<Scoreboard> ScoreboardClass;
    local String SongName;

    // If single player, start player in level immediately
    // MCJ: Also start player immediately if we've just reconnected to the
    // server because the round is starting.

	if ( !bDelayedStart ) //|| SwatGamePlayerController(NewPlayer).CreatePawnOponLogin() )
    {
        // start match, or let player enter, immediately
        bRestartLevel = false;	// let player spawn once in levels that must be restarted after every death
        bKeepSamePlayerStart = true;
        if ( bWaitingToStartMatch )
            StartMatch();
        else
            RestartPlayer(newPlayer);
        bKeepSamePlayerStart = false;
        bRestartLevel = Default.bRestartLevel;
    }

    // Start player's music.
    SongName = Level.Song;
    if( SongName != "" && SongName != "None" )
        NewPlayer.ClientSetMusic( SongName, MTRAN_Fade );

    // tell client what hud and scoreboard to use
    if( HUDType != "" )
        HudClass = class<HUD>(DynamicLoadObject(HUDType, class'Class'));

    if( ScoreBoardType != "" )
        ScoreboardClass = class<Scoreboard>(DynamicLoadObject(ScoreBoardType, class'Class'));
    NewPlayer.ClientSetHUD( HudClass, ScoreboardClass );

    if ( NewPlayer.Pawn != None )
        NewPlayer.Pawn.ClientSetRotation(NewPlayer.Pawn.Rotation);

    PlayerLoggedIn(NewPlayer);
}


///////////////////////////////////////////////////////////////////////////////
//
//
function PlayerLoggedIn(PlayerController NewPlayer)
{
    local SwatGamePlayerController PC;

    //dkaplan: when finished logging in,
    //
    // if this is not a remote client (is the Local PlayerController) or is the first time
    //   goto pregame state
    // else
    //   the client's gamestate should be set to the same as the server's
    //
    //NOTE: this looks like it can be optimized better, but doing so may break
    //  the natural progression of gamestate (Pregame->Midgame->Postgame)

    log( "[dkaplan] >>>  PlayerLoggedIn(), NewPlayer = "$NewPlayer);
    log( "[dkaplan]    ...  Level.GetLocalPlayerController() = "$Level.GetLocalPlayerController());
    log( "[dkaplan]    ...  Repo.GuiConfig.SwatGameState = "$Repo.GuiConfig.SwatGameState);

    PC = SwatGamePlayerController(NewPlayer);
    if (PC != None )
    {
        if ( Level.NetMode != NM_Standalone )
            log( "[dkaplan]    ...  SwatGamePlayerController(NewPlayer).IsAReconnectingClient() = "$PC.IsAReconnectingClient() );

        if( Level.IsCOOPServer )
            PrecacheOnClient( PC );

        if( NewPlayer == Level.GetLocalPlayerController()
            || Repo.GuiConfig.SwatGameState == GAMESTATE_PreGame
            || (Level.NetMode != NM_Standalone && !PC.IsAReconnectingClient()) )
        {
            PC.ClientOnLoggedIn(ServerSettings(Level.CurrentServerSettings).GameType);

            //notify of newly joined player
            if ( Level.NetMode != NM_Standalone )
            {
            if( !PC.IsAReconnectingClient())
                Broadcast( NewPlayer, NewPlayer.PlayerReplicationInfo.PlayerName, 'PlayerConnect');
            }

            //notify of pre-game waiting state
            //if( Repo.GuiConfig.SwatGameState == GAMESTATE_PreGame )
                //NewPlayer.ClientMessage( "Waiting for round to start!", 'SwatGameEvent' );
        }
        else if ( Repo.GuiConfig.SwatGameState == GAMESTATE_MidGame )
        {
            PC.ClientOnLoggedIn();
            PlayerLateStart( PC );
        }
        else if ( Repo.GuiConfig.SwatGameState == GAMESTATE_PostGame )
        {
            PC.ClientOnLoggedIn();
            PC.ClientRoundStarted();
            PC.ClientGameEnded();
        }
    }

	// This call may need to be moved at some point so that the entry point for the spawned officers
	// is the same as the player.  For now I will just leave it here.  [crombie]
	if ( Level.NetMode == NM_Standalone )
    {
        SpawnOfficers();
    }
	log( "[dkaplan] <<<  PlayerLoggedIn(), NewPlayer = "$NewPlayer);
}

function Logout( Controller Exiting )
{
    local SwatGamePlayerController SGPC;
	local SwatPlayerController PC;
	local Controller i;

    mplog( "---SwatGameInfo::Logout(). ControllerLeaving="$Exiting );

    SGPC = SwatGamePlayerController( Exiting );
    if ( SGPC != None && SGPC.SwatPlayer != None )
    {
        //broadcast this player's disconnection to all players
        Broadcast( SGPC, SGPC.PlayerReplicationInfo.PlayerName, 'PlayerDisconnect');

        //log the player out: remove their RepoItem
        Repo.Logout( SGPC );

        mplog( "......triggering game event." );
        GameEvents.PlayerDied.Triggered( SGPC, SGPC );

		// dbeswick: stats
		// notify stats of logout
		assert(SwatPlayerReplicationInfo(SGPC.PlayerReplicationInfo) != None);
		if (SwatPlayerReplicationInfo(SGPC.PlayerReplicationInfo).bStatsNewPlayer)
			Level.GetGameSpyManager().StatsRemovePlayer(SGPC.PlayerReplicationInfo.PlayerID);

		// remove leaving player from all VOIP ignore lists
		for (i = Level.ControllerList; i != None; i = i.NextController)
		{
			PC = SwatPlayerController(i);
			if (PC != None)
				PC.VOIPUnIgnore(SGPC.PlayerReplicationInfo.PlayerID);
		}
	}

    TestWaitingForPlayersToReconnect();

	// call this *after* the code above.
    Super.Logout( Exiting );
}

function InitVoiceReplicationInfo()
{
	local class<VoiceChatReplicationInfo> VRIClass;
	local int i;

	if (Level.NetMode == NM_StandAlone || Level.NetMode == NM_Client)
		return;

	if ( VoiceReplicationInfoType != "" )
	{
		VRIClass = class<VoiceChatReplicationInfo>(DynamicLoadObject(VoiceReplicationInfoType,class'Class'));
		if ( VRIClass != None )
			VoiceReplicationInfoClass = VRIClass;
	}

    if (VoiceReplicationInfoClass != None && VoiceReplicationInfo == None)
	    VoiceReplicationInfo = Spawn(VoiceReplicationInfoClass);

	Super.InitVoiceReplicationInfo();
	VoiceReplicationInfo.bPrivateChat = bAllowPrivateChat;

	i = VoiceReplicationInfo.GetChannelIndex(DefaultVoiceChannel);
	if ( i != -1 && i != VoiceReplicationInfo.DefaultChannel )
		VoiceReplicationInfo.DefaultChannel = i;
}

private function bool ShouldSpawnOfficerRedOne()  {
  if(Repo.GuiConfig.CurrentMission.CustomScenario == None) {
    return Repo.CheckOfficerPermadeathInformation(0);
  } else return Repo.GuiConfig.CurrentMission.CustomScenario.HasOfficerRedOne;
}

private function bool ShouldSpawnOfficerRedTwo()  {
  if(Repo.GuiConfig.CurrentMission.CustomScenario == None) {
    return Repo.CheckOfficerPermadeathInformation(1);
  } else return Repo.GuiConfig.CurrentMission.CustomScenario.HasOfficerRedTwo;
}

private function bool ShouldSpawnOfficerBlueOne() {
  if(Repo.GuiConfig.CurrentMission.CustomScenario == None) {
    return Repo.CheckOfficerPermadeathInformation(2);
  } else return Repo.GuiConfig.CurrentMission.CustomScenario.HasOfficerBlueOne;
}

private function bool ShouldSpawnOfficerBlueTwo() {
  if(Repo.GuiConfig.CurrentMission.CustomScenario == None) {
    return Repo.CheckOfficerPermadeathInformation(3);
  } else return Repo.GuiConfig.CurrentMission.CustomScenario.HasOfficerBlueTwo;
}

private function bool ShouldSpawnOfficerAtStart(SwatOfficerStart OfficerStart, EEntryType DesiredEntryType)
{
	assert(OfficerStart != None);

	if (OfficerStart.EntryType == DesiredEntryType)
	{
		switch (OfficerStart.OfficerStartType)
		{
			case RedOneStart:
				return ShouldSpawnOfficerRedOne();
			case RedTwoStart:
				return ShouldSpawnOfficerRedTwo();
			case BlueOneStart:
				return ShouldSpawnOfficerBlueOne();
			case BlueTwoStart:
				return ShouldSpawnOfficerBlueTwo();
		}
	}

	return false;
}

// Goes through all of the SwatOfficerStart points and tells it to spawn the officer
private function SpawnOfficers()
{
	local int i;
	local NavigationPoint Iter;
	local EEntryType DesiredEntryType;
	local SwatOfficerStart OfficerStart;
	local array<SwatOfficerStart> OfficerSpawnPoints;

	// find out if we should use the primary or secondary entry points
	DesiredEntryType = Repo.GetDesiredEntryPoint();

	NumSpawnedOfficers = 0;

	// first go through and figure out where we will spawn the officers, as well as how many will spawn
	// at this point we do not spawn because we need to know how many will spawn first
	Log("SPAWNING OFFICERS:");
	for (Iter = Level.NavigationPointList; Iter != None; Iter = Iter.nextNavigationPoint)
	{
		if (Iter.IsA('SwatStartPointBase'))
		{
			if(Iter.IsA('SwatOfficerStart'))
            {
                OfficerStart = SwatOfficerStart(Iter);
				if (ShouldSpawnOfficerAtStart(OfficerStart, DesiredEntryType))
				{
		            log("  Will *Spawn* officer at "$OfficerStart$" with entry type "$GetEnum(EEntryType,DesiredEntryType));
			        OfficerSpawnPoints[OfficerStart.OfficerStartType] = OfficerStart;
			        ++NumSpawnedOfficers;
		        }
		        else
		        {
			        log("  Not spawning officer at "$OfficerStart$" because its entry type ("$GetEnum(EEntryType,OfficerStart.EntryType)$") doesn't match desired entry "$GetEnum(EEntryType,DesiredEntryType)$")");
		        }
            }
            else
            {
                log("  Not spawning officer at "$Iter$" because it is not a SwatOfficerStart");
            }
        }
	}

	// now go through and spawn the officers
	for(i=0; i<OfficerSpawnPoints.Length; ++i)
	{
		if (OfficerSpawnPoints[i] != None)
			OfficerSpawnPoints[i].SpawnOfficer();
	}

	Log("  TOTAL OFFICERS SPAWNED: "$NumSpawnedOfficers);
}

function int GetNumSpawnedOfficers()
{
	return NumSpawnedOfficers;
}

function bool ShouldKillOnChangeTeam()
{
	return GameMode.ShouldKillOnChangeTeam();
}

//
// Restart a player.
//
function RestartPlayer( Controller aPlayer )
{
	local NavigationPoint startSpot;
    local SwatMPStartPoint MPStartSpot;
	local int TeamNum;

    mplog( "---SwatGameInfo::RestartPlayer(). PlayerController="$aPlayer );

	if( bRestartLevel && Level.NetMode!=NM_DedicatedServer && Level.NetMode!=NM_ListenServer )
    {
        mplog( "...1" );
		return;
    }

    if ( Level.NetMode == NM_Standalone )
    {
        if ( (aPlayer.PlayerReplicationInfo == None) || (aPlayer.PlayerReplicationInfo.Team == None) )
            TeamNum = 255;
        else
            TeamNum = aPlayer.PlayerReplicationInfo.Team.TeamIndex;

        // Spawn the player's pawn at an appropriate starting spot
        startSpot = SpawnPlayerPawn(aPlayer, TeamNum); // ckline: refactored code out of this function into SpawnPlayerPawn
        if( startSpot == None )
        {
            log(" Player pawn start not found!!!");
            return;
        }

        log("Setting TimeOfLastSpawn to "$Level.TimeSeconds$" for "$StartSpot);
        StartSpot.TimeOfLastSpawn = Level.TimeSeconds; // ckline added

        aPlayer.Pawn.Anchor = startSpot;
        aPlayer.Pawn.LastStartSpot = PlayerStart(startSpot);
        aPlayer.Pawn.LastStartTime = Level.TimeSeconds;
        aPlayer.PreviousPawnClass = aPlayer.Pawn.Class;

        aPlayer.Possess(aPlayer.Pawn);
        aPlayer.PawnClass = aPlayer.Pawn.Class;

        aPlayer.Pawn.PlayTeleportEffect(true, true);
        aPlayer.ClientSetRotation(aPlayer.Pawn.Rotation);
        AddDefaultInventory(aPlayer.Pawn);
        TriggerEvent( StartSpot.Event, StartSpot, aPlayer.Pawn);
    }
    else
    {
        // We're in a network game.

        // Spawn the player's pawn at an appropriate starting spot
        MPStartSpot = SpawnNetPlayerPawn( aPlayer );
        if( MPstartSpot == None )
        {
            log("...Net player pawn start not found!!! returning from RestartPlayer()...");
            return;
        }

        NetPlayer(aPlayer.Pawn).SwatPlayerID = SwatGamePlayerController(aPlayer).SwatPlayerID;

        if ( SwatGamePlayerController(aPlayer).ThisPlayerIsTheVIP )
        {
            mplog( "...setting that the player is the VIP" );
            NetPlayer(aPlayer.Pawn).SetIsVIP();
        }

        //log("Setting TimeOfLastSpawn to "$Level.TimeSeconds$" for "$StartSpot);
        //StartSpot.TimeOfLastSpawn = Level.TimeSeconds; // ckline added

        //aPlayer.Pawn.Anchor = startSpot;
        //aPlayer.Pawn.LastStartSpot = PlayerStart(startSpot);
        aPlayer.Pawn.LastStartTime = Level.TimeSeconds;
        aPlayer.PreviousPawnClass = aPlayer.Pawn.Class;

        mplog( "...about to Possess the pawn." );
        mplog( "......controller="$aPlayer );
        mplog( "......pawn="$aPlayer.Pawn );
        aPlayer.Possess(aPlayer.Pawn);
        aPlayer.PawnClass = aPlayer.Pawn.Class;

		// dbeswick: needed for coop
		SetPlayerTeam( SwatGamePlayerController(aPlayer), NetTeam(aPlayer.PlayerReplicationInfo.Team).GetTeamNumber(), true );

        aPlayer.Pawn.PlayTeleportEffect(true, true);
        aPlayer.ClientSetRotation(aPlayer.Pawn.Rotation);
        AddDefaultInventory(aPlayer.Pawn);
        TriggerEvent( MPStartSpot.Event, MPStartSpot, aPlayer.Pawn);

        SwatPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).COOPPlayerStatus = STATUS_Healthy;
    }
    mplog( "...Leaving RestartPlayer()." );

	// dbeswick: stats
	// send stats auth challenge to client
	if (Level.NetMode != NM_Standalone && !SwatPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).bStatsRequestSent)
	{
		LOG("[Stats] Initial stats request for"@aPlayer);
		Level.GetGamespyManager().ServerSendStatChallenge(PlayerController(aPlayer));
		SwatPlayerReplicationInfo(aPlayer.PlayerReplicationInfo).bStatsRequestSent = true;
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// MCJ: This is a copy of SpawnPlayerPawn(). I needed a copy for net games,
// since start points for net players are not NavigationPoints, which is what
// SpawnPlayerPawn returns.
//
function SwatMPStartPoint SpawnNetPlayerPawn(Controller aPlayer )
{
    local class<Pawn> DefaultPlayerClass;
    local SwatMPStartPoint startSpot;
    local bool SuccessfullySpawned;

    mplog( "In SwatGameInfo::SpawnNetPlayerPawn(). Controller="$aPlayer$", aPlayer.PlayerReplicationInfo="$aPlayer.PlayerReplicationInfo$", aPlayer.PlayerReplicationInfo.Team="$aPlayer.PlayerReplicationInfo.Team );

    // If in multiplayer game, and the controller is on a team, use the team's
    // default player class
    if (Level.NetMode != NM_Standalone && aPlayer.PlayerReplicationInfo.Team != None)
    {
        aPlayer.PawnClass = aPlayer.PlayerReplicationInfo.Team.DefaultPlayerClass;
    }
	if (aPlayer.PreviousPawnClass!=None && aPlayer.PawnClass != aPlayer.PreviousPawnClass)
    {
		BaseMutator.PlayerChangedClass(aPlayer);
    }

    SuccessfullySpawned = false;
    while ( !SuccessfullySpawned )
    {
        startSpot = GameMode.FindNetPlayerStart( aPlayer );
        mplog( "...startSpot="$startSpot );
        if ( startSpot == None )
        {
            break;
        }

        if ( aPlayer.PawnClass != None )
        {
            mplog( "...1" );
            //TMC tagged player pawn 'Player'; needed for pulling loadout info from ini file
            aPlayer.Pawn = Spawn( aPlayer.PawnClass, , 'Player', startSpot.Location, StartSpot.Rotation );
        }

        if( aPlayer.Pawn == None )
        {
            mplog( "...2" );
            DefaultPlayerClass = GetDefaultPlayerClass(aPlayer);
            //TMC tagged player pawn 'Player'; needed for pulling loadout info from ini file
            aPlayer.Pawn = Spawn( DefaultPlayerClass, , 'Player', startSpot.Location, StartSpot.Rotation );
        }

        if ( aPlayer.Pawn != None )
        {
            // We successfully spawned the player.
            log("Spawned *pawn* for player "$aPlayer$" at "$StartSpot); // ckline
            SuccessfullySpawned = true;
        }
    }

    // If startSpot == None here, we failed to spawn because all of the
    // possible start spots were already used. Log it and return.
    if ( startSpot == None )
    {
        log( "Couldn't spawn pawn of class for player "$aPlayer$" because we ran out of start spots." );
#if IG_SHARED
        AssertWithDescription(false, "Couldn't spawn pawn for player "$aPlayer$" because we ran out of start spots." );
#endif
        log( "...sending controller to state Dead" );
        aPlayer.GotoState('Dead');
    }

    return startSpot;
}


function NetTeam GetTeamFromID( int TeamID )
{
    return NetTeam(GameReplicationInfo.Teams[TeamID]);
}

///////////////////////////////////////////////////////////////////////////////
//overridden from Engine.GameInfo
event Broadcast( Actor Sender, coerce string Msg, optional name Type, optional PlayerController Target, optional string Location )
{
//log( self$"::Broadcast( "$Msg$" "$Location$" )" );
	BroadcastHandler.Broadcast(Sender,Msg,Type,Target,Location);
}

//overridden from Engine.GameInfo
function BroadcastTeam( Controller Sender, coerce string Msg, optional name Type, optional string Location )
{
//log( self$"::BroadcastTeam( "$Sender$", "$Msg$" ), sender.statename = "$Sender.GetStateName() );
    if( Sender.IsInState( 'ObserveTeam' ) ||
        Sender.IsInState( 'Dead' ) )
        BroadcastObservers( Sender, Msg, Type );

	BroadcastHandler.BroadcastTeam(Sender,Msg,Type,Location);
}

function BroadcastObservers( Controller Sender, coerce string Msg, optional name Type )
{
	local Controller C;
	local PlayerController P;
//log( self$"::BroadcastObservers( "$Msg$" )" );

	// see if allowed (limit to prevent spamming)
	if ( !BroadcastHandler.AllowsBroadcast(Sender, Len(Msg)) )
		return;

	if ( Sender != None )
	{
		For ( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			P = PlayerController(C);
			if ( ( P != None )
			    && ( P.PlayerReplicationInfo.Team == Sender.PlayerReplicationInfo.Team )
				&& ( P.IsInState( 'ObserveTeam' )
				  || P.IsInState( 'Dead' ) ) )
				P.TeamMessage( Sender.PlayerReplicationInfo, Msg, Type );
		}
	}
}

function BroadcastDeathMessage(Controller Killer, Controller Other, class<DamageType> damageType)
{
    local String KillerName;
    local String VictimName;
    local String WeaponName;
    local int VictimTeam, KillerTeam;
    local SwatPlayer OtherPlayer;
	local PlayerController KillerPC;
	local PlayerController VictimPC;

    //dont send death messages for generic deaths
    if( damageType == class'GenericDamageType' )
        return;

    KillerName = Killer.GetHumanReadableName();
    VictimName = Other.GetHumanReadableName();
    WeaponName = string(damageType.Outer.name) $ "." $ string(damageType.name);
    if( NetPlayer(Killer.Pawn) != None )
        KillerTeam = NetPlayer(Killer.Pawn).GetTeamNumber();
    if( NetPlayer(Other.Pawn) != None )
        VictimTeam = NetPlayer(Other.Pawn).GetTeamNumber();

    // Don't send a death message if someone shot a non-VIP after he was
    // arrested.
    OtherPlayer = SwatPlayer(Other.Pawn);
    if ( OtherPlayer != None && !OtherPlayer.IsTheVIP() && OtherPlayer.IsArrested() )
        return;

    // Note: VictimName might be None if Controller's Pawn is destroyed before this
    // this method is called. Hopefully that won't happen, but try to do something
    // semi-intelligent in this situation.

	if( Other.IsA('PlayerController') && NetPlayer(Other.Pawn) != None &&
	    Killer.IsA('PlayerController') && NetPlayer(Killer.Pawn) != None )
	{
	    if ( (Killer == Other) || (Killer == None) )
	    {
	        if( KillerTeam != 0 )
    		    Broadcast(Other, VictimName, 'SuspectsSuicide');
	        else
    		    Broadcast(Other, VictimName, 'SwatSuicide');
		}
	    else if( KillerTeam == VictimTeam )
	    {
	        if( KillerTeam != 0 )
    		    Broadcast(Other, KillerName$"\t"$VictimName$"\t"$WeaponName, 'SuspectsTeamKill');
	        else
    		    Broadcast(Other, KillerName$"\t"$VictimName$"\t"$WeaponName, 'SwatTeamKill');

			// dbeswick: stats
			KillerPC = PlayerController(Killer);
			if (KillerPC != None)
			{
				VictimPC = PlayerController(Other);
				KillerPC.Stats.TeamKilled(damageType.name, VictimPC);
			}
		}
		else
		{
	        if( KillerTeam != 0 )
    		    Broadcast(Other, KillerName$"\t"$VictimName$"\t"$WeaponName, 'SuspectsKill');
	        else
    		    Broadcast(Other, KillerName$"\t"$VictimName$"\t"$WeaponName, 'SwatKill');

			// dbeswick: stats
			KillerPC = PlayerController(Killer);
			if (KillerPC != None)
			{
				VictimPC = PlayerController(Other);
				KillerPC.Stats.Killed(damageType.name, VictimPC);
			}
		}
	}
	else // someone killed a non-player (e.g., an AI was killed)
	{
		Broadcast(Other, KillerName$"\t"$VictimName$"\t"$WeaponName, 'AIDeath');	// TODO: should this be a 'PlayerDeath' Message Type?
	}
}

function BroadcastArrestedMessage(Controller Killer, Controller Other)
{
    local String KillerName;
    local String VictimName;
    local int VictimTeam;
	local PlayerController KillerPC;
	local PlayerController OtherPC;

    KillerName = Killer.Pawn.GetHumanReadableName();
    VictimName = Other.Pawn.GetHumanReadableName();
    VictimTeam = NetPlayer(Other.Pawn).GetTeamNumber();

	AssertWithDescription( Killer != Other, KillerName $ " somehow arrested himself.  That really shouldn't ever happen!" );
	if( Other.IsA('PlayerController') && NetPlayer(Other.Pawn) != None &&
	    Killer.IsA('PlayerController') && NetPlayer(Killer.Pawn) != None )
	{
	if( VictimTeam == 1 )
    	Broadcast(Other, KillerName$"\t"$VictimName, 'SwatArrest');
	else
    	Broadcast(Other, KillerName$"\t"$VictimName, 'SuspectsArrest');
	}

	// dbeswick: stats
	KillerPC = PlayerController(Killer);
	if (KillerPC != None)
	{
		OtherPC = PlayerController(Other);
		KillerPC.Stats.Arrested(OtherPC);
	}
}

function Killed( Controller Killer, Controller Killed, Pawn KilledPawn, class<DamageType> damageType )
{
    Super.Killed( Killer, Killed, KilledPawn, damageType );

    SwatPlayerReplicationInfo(Killed.PlayerReplicationInfo).COOPPlayerStatus = STATUS_Incapacitated;
}


// SetPlayerTeam
// Set NonInteractive to false if the call is not due to user input
function SetPlayerTeam(SwatGamePlayerController Player, int TeamID, optional bool NonInteractive)
{
	//local SwatGameReplicationInfo SGRI;
	local TeamInfo CurrentTeam;
	local TeamInfo NewTeam;

    // Set the preferred team to the team that was requested. However, if
    // we're in COOP, this will be overridden for the current round in the
    // following code.
    Player.SwatRepoPlayerItem.SetPreferredTeamID( TeamID );

    CurrentTeam = Player.PlayerReplicationInfo.Team;

    NewTeam = GameReplicationInfo.Teams[TeamID];

	// If the TeamID corresponds to an AI team join the next best team.
	if (NetTeam(NewTeam) != None && NetTeam(NewTeam).AIOnly)
		NewTeam = GameReplicationInfo.Teams[GetAutoJoinTeamID()];

    log( self$"::SetPlayerTeam( "$Player$", "$TeamID$" ) ... CurrentTeam = "$CurrentTeam$", NewTeam = "$NewTeam );

    // If a new team, remove from current team, kill off pawn, add to new
    // team, and restart the player
    if (NewTeam != None && CurrentTeam != NewTeam)
    {
		if (CurrentTeam != None)
        {
            CurrentTeam.RemoveFromTeam(Player);
        }

		if (!NonInteractive)
		{
			if (ShouldKillOnChangeTeam())
			{
				if (Player.Pawn != None)
				{
					Player.Pawn.Died( None, class'GenericDamageType', Player.Pawn.Location, vect(0,0,0) );
					//Player.Pawn.Destroy();
				}
			}
		}

		if (NetPlayer(Player.Pawn) != None)
			NetPlayer(Player.Pawn).OnTeamChanging(NewTeam);

        NewTeam.AddToTeam(Player);

		Repo.GetRepoPlayerItem( Player.SwatPlayerID ).SetTeamID( TeamID );

        //notify the game mode that a new player has joined the team
        GetGameMode().PlayerJoinedTeam( Player, NetTeam(CurrentTeam), NetTeam(NewTeam) );

		if (bStatsNewGameStarted)
		{
			Player.Stats.TeamChange(TeamID);
		}
    }
	else
	{
		if (NetPlayer(Player.Pawn) != None)
			NetPlayer(Player.Pawn).OnTeamChanging(NewTeam);
	}

	// Stop a new team member from stating a referendum straight away
  // ??? why --eez
	//SGRI = SwatGameReplicationInfo(GameReplicationInfo);
	//if (SGRI != None && SGRI.RefMgr != None)
	//	SGRI.RefMgr.AddVoterToCooldownList(Player.PlayerReplicationInfo.PlayerId);

	Player.PlayerReplicationInfo.Team = NewTeam;
}

///////////////////////////////////////

// This function used to be called from ClientOnLoggedIn() on an individual
// client. I've changed it to join the team designated in the Repo item rather
// than selecting a team automatically. All of this will change when we delay
// creation of the pawn; this is just a hack for the current milestone.
//
function AutoSetPlayerTeam(SwatGamePlayerController Player)
{
//     local int TeamToJoin;

//     TeamToJoin = Repo.GetRepoPlayerItem( Player.SwatPlayerID ).GetTeamID();
//     SetPlayerTeam( Player, TeamToJoin );
}


function int GetAutoJoinTeamID()
{
    local int i;
    local int lowestTeamID;
    local int lowestTeamSize;

    if (Level.NetMode == NM_Standalone)
    {
        return 0;
    }

    // Find team with lowest number of players
    lowestTeamID   = 0;
    lowestTeamSize = GameReplicationInfo.Teams[lowestTeamID].Size;
    for (i = 1; i < ArrayCount(GameReplicationInfo.Teams); i++)
    {
        if (GameReplicationInfo.Teams[i] != None && GameReplicationInfo.Teams[i].Size < lowestTeamSize && !NetTeam(GameReplicationInfo.Teams[i]).AIOnly)
        {
            lowestTeamID   = i;
            lowestTeamSize = GameReplicationInfo.Teams[i].Size;
        }
    }

    return lowestTeamID;
}


function ChangePlayerTeam( SwatGamePlayerController Player )
{
    local int CurrentTeam, NewTeam;
    local SwatRepoPlayerItem RepoItem;
	local int i;

    RepoItem = Repo.GetRepoPlayerItem( Player.SwatPlayerID );
    CurrentTeam = RepoItem.GetTeamID();

	// dbeswick:
	// cycle teams until an appropriate one is found
	NewTeam = -1;

	for (i = CurrentTeam + 1; i < 3; ++i)
	{
		if (NetTeam(GameReplicationInfo.Teams[i]) != None && !NetTeam(GameReplicationInfo.Teams[i]).AIOnly)
		{
			NewTeam = i;
			break;
		}
	}

	if (NewTeam == -1)
	{
		for (i = 0; i < 3; ++i)
		{
			if (NetTeam(GameReplicationInfo.Teams[i]) != None && !NetTeam(GameReplicationInfo.Teams[i]).AIOnly)
			{
				NewTeam = i;
				break;
			}
		}
	}

    SetPlayerTeam( Player, NewTeam );

    if( Repo.GuiConfig.SwatGameState == GAMESTATE_MidGame )
        Broadcast( Player, Player.PlayerReplicationInfo.PlayerName, 'SwitchTeams');
}


function SetPlayerReady( SwatGamePlayerController Player )
{
    log("[dkaplan] >>> SetPlayerReady()"  );

    if( !SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).GetPlayerIsReady() )
        TogglePlayerReady( Player );
}

function SetPlayerNotReady( SwatGamePlayerController Player )
{
    log("[dkaplan] >>> SetPlayerNotReady()"  );

    if( SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).GetPlayerIsReady() )
        TogglePlayerReady( Player );
}

function TogglePlayerReady( SwatGamePlayerController Player )
{
    log("[dkaplan] >>> TogglePlayerReady(): Player.HasEnteredFirstRoundOfNetworkGame() = "$Player.HasEnteredFirstRoundOfNetworkGame() );

    if( SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).COOPPlayerStatus == STATUS_NotReady )
        SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).COOPPlayerStatus = STATUS_Ready;
    else if(SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).COOPPlayerStatus == STATUS_Ready)
        SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).COOPPlayerStatus = STATUS_NotReady;
    SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).TogglePlayerIsReady();

#if !IG_THIS_IS_SHIPPING_VERSION
    logPlayerReadyValues();
#endif

    // Do the following if the player is a late joiner.
    if( Player != Level.GetLocalPlayerController() && (! Player.HasEnteredFirstRoundOfNetworkGame())
        && !bChangingLevels )
    {
        if ( Repo.GuiConfig.SwatGameState == GAMESTATE_MidGame )
        {
            PlayerLateStart( Player );
        }
        else if ( Repo.GuiConfig.SwatGameState == GAMESTATE_PostGame )
        {
            Player.ClientRoundStarted();
            Player.ClientGameEnded();
        }
    }

    TestWaitingForPlayersToReconnect();
}

function logPlayerReadyValues()
{
    local SwatGameReplicationInfo SGRI;
    local int i;

    SGRI = SwatGameReplicationInfo(GameReplicationInfo);
    if( SGRI == None )
        return;

    log( "The SwatGameReplicationInfo's PRIStaticArray is:" );

    for (i = 0; i < ArrayCount(SGRI.PRIStaticArray); ++i)
    {
        if (SGRI.PRIStaticArray[i] == None)
        {
            Log( "  ...PRIStaticArray["$i$"] = None " );
        }
        else
        {
            Log( "  ...PRIStaticArray["$i$"] = "$SGRI.PRIStaticArray[i]$", PlayerIsReady = "$SGRI.PRIStaticArray[i].GetPlayerIsReady() );
        }
    }
}

function PlayerLateStart( SwatGamePlayerController Player )
{
    // This function gets called if the player connects and the round is in
    // progress. The player should be put in the respawn queue for their team
    // and wait to respawn with the rest of their teammates.

    // Puts the client in midgame gamestate.
    Player.ClientRoundStarted();

    // Don't restart here...
    //RestartPlayer( Player );

	// player has entered the round (and thus had its pawn created)
	Player.SwatRepoPlayerItem.SetHasEnteredFirstRound();

    // Send them into observercam.
    Player.ForceObserverCam();
}

///////////////////////////////////////////////////////////////////////////////


function int NumberOfPlayersForServerBrowser()
{
    return Max( SwatRepo(Level.GetRepo()).NumberOfPlayersWhoShouldReturn(), GetNumPlayers() );
}

function int MaxPlayersForServerBrowser()
{
    return ServerSettings(Level.CurrentServerSettings).MaxPlayers;
}

function bool GameIsPasswordProtected()
{
    local SwatRepo RepoObj;

    RepoObj = SwatRepo(Level.GetRepo());
    Assert( RepoObj != None );

	if( ServerSettings(Level.CurrentServerSettings).bPassworded )
        return true;
    else
        return false;
}

function string GetPlayerName( PlayerController PC )
{
    local SwatPlayerReplicationInfo SPRI;

    SPRI = SwatPlayerReplicationInfo(PC.PlayerReplicationInfo);
    if ( SPRI == None )
        return "";

    return SPRI.PlayerName;
}

function int GetPlayerScore( PlayerController PC )
{
    local SwatPlayerReplicationInfo SPRI;

    SPRI = SwatPlayerReplicationInfo(PC.PlayerReplicationInfo);
    if ( SPRI == None )
        return 0;

    return SPRI.NetScoreInfo.GetScore();
}

function int GetPlayerPing( PlayerController PC )
{
    local SwatPlayerReplicationInfo SPRI;

    SPRI = SwatPlayerReplicationInfo(PC.PlayerReplicationInfo);
    if ( SPRI == None )
        return 999;

    return SPRI.Ping;
}


function int ReduceDamage( int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType )
{
    local int ModifiedDamage;
    local float Modifier;

    Modifier = 1;

    if( Level.IsCOOPServer && ClassIsChildOf(Injured.Class, class'NetPlayer') )
    {
        // In COOP, reduce damage based on MP damage modifier
        Modifier = COOPDamageModifier;
    }
    else if ( (Level.NetMode == NM_StandAlone ) &&
        (ClassIsChildOf(Injured.Class, class'SwatPlayer') || ClassIsChildOf(Injured.Class, class'SwatOfficer')))
    {
        // In single-player, reduce damage based on difficulty
        Switch(Repo.GuiConfig.CurrentDifficulty)
        {
            case DIFFICULTY_Easy:   Modifier = SPDamageModifierEasy;    break;
            case DIFFICULTY_Normal: Modifier = SPDamageModifierNormal;  break;
            case DIFFICULTY_Hard:   Modifier = SPDamageModifierHard;    break;
            case DIFFICULTY_Elite:  Modifier = SPDamageModifierElite;   break;
            default:
                Modifier = 1;
                AssertWithDescription(false, "Invalid setting ("$Repo.GuiConfig.CurrentDifficulty$") for SwatGUIConfig.CurrentDifficulty");
        }
    }
    else if (ClassIsChildOf(Injured.Class, class'NetPlayer'))
    {
        // In multiplayer, reduce damage based on MP damage modifier
        Modifier = MPDamageModifier;
    }

    ModifiedDamage = Damage * Modifier;

    if (Level.AnalyzeBallistics)
    {
        if (Level.NetMode == NM_StandAlone || Level.IsCOOPServer)
            log("[BALLISTICS]   ... SP Difficulty Damage Modifier = "$
                    Modifier$" (difficulty="$Repo.GuiConfig.CurrentDifficulty$")");
        else
            log("[BALLISTICS]   ... MP Difficulty Damage Modifier = "$Modifier);

        log("[BALLISTICS]   ... Modified Damage = "$Damage$" * "$Modifier$" = "$ModifiedDamage);
    }

    return Super.ReduceDamage(ModifiedDamage, Injured, InstigatedBy, HitLocation, Momentum, DamageType);
}

event DetailChange()
{
	local SwatOfficer officer;
	Super.DetailChange();
	foreach DynamicActors(class'SwatOfficer', officer)
	{
       officer.UpdateOfficerLOD(); // update visibility of gratuitous attachments on officers
    }
}

// Execute only on server.
function PreQuickRoundRestart()
{
    local Controller Controller;
    local SwatGamePlayerController SwatController;

    // Count the number of playercontrollers whose are reconnecting clients.
    for ( Controller = Level.ControllerList; Controller != None; Controller = Controller.NextController )
    {
        SwatController = SwatGamePlayerController(Controller);
        if (SwatController != None)
        {
            SwatController.ClientPreQuickRoundRestart();
        }
    }

	SetupNameDisplay();

   // Clean up garbage when quick restarting.
    //
    // The clients also do this in SwatGamePlayerController.ClientPreQuickRoundRestart()
    Log("Server in PreQuickRoundRestart: Collecting garbage.");
    ConsoleCommand( "obj garbage" );
}

function OnServerSettingsUpdated( Controller Admin )
{
    Broadcast(Admin, Admin.GetHumanReadableName(), 'SettingsUpdated');
}

simulated event Destroyed()
{
	MissionObjectiveTimeExpired = None;

    Super.Destroyed();
}



////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
function SetLevelHasFemaleCharacters()
{
    LevelHasFemaleCharacters = true;
}

function AddMesh( Mesh inMesh )
{
    local int i;

    for( i = 0; i < PrecacheMeshes.Length; i++ )
    {
        if( inMesh == PrecacheMeshes[i] )
            return;
    }

    PrecacheMeshes[PrecacheMeshes.Length] = inMesh;
}

function AddMaterial( Material inMaterial )
{
    local int i;

    for( i = 0; i < PrecacheMaterials.Length; i++ )
    {
        if( inMaterial == PrecacheMaterials[i] )
            return;
    }

    PrecacheMaterials[PrecacheMaterials.Length] = inMaterial;
}

function AddStaticMesh( StaticMesh inStaticMesh )
{
    local int i;

    for( i = 0; i < PrecacheStaticMeshes.Length; i++ )
    {
        if( inStaticMesh == PrecacheStaticMeshes[i] )
            return;
    }

    PrecacheStaticMeshes[PrecacheStaticMeshes.Length] = inStaticMesh;
}

function PrecacheOnClient( SwatGamePlayerController SGPC )
{
    local int i;

    for( i = 0; i < PrecacheMaterials.Length; i++ )
    {
        SGPC.ClientAddPrecacheableMaterial( PrecacheMaterials[i].outer.name $ "." $ PrecacheMaterials[i].name );
    }

    for( i = 0; i < PrecacheMeshes.Length; i++ )
    {
        SGPC.ClientAddPrecacheableMesh( PrecacheMeshes[i].outer.name $ "." $ PrecacheMeshes[i].name );
    }

    for( i = 0; i < PrecacheStaticMeshes.Length; i++ )
    {
        SGPC.ClientAddPrecacheableStaticMesh( PrecacheStaticMeshes[i].outer.name $ "." $ PrecacheStaticMeshes[i].name );
    }

    SGPC.ClientPrecacheAll( LevelHasFemaleCharacters );
}

////////////////////////////////////////////////////////////////////////////////////

function ChangeName( Controller Other, coerce string S, bool bNameChange )
{
	local SwatGamePlayerController C;

	if( S == "" )
		return;

	Super.ChangeName(Other, S, bNameChange);

	// notify stat tracking of name change
	if (bStatsNewGameStarted)
	{
		C = SwatGamePlayerController(Other);
		if (C != None)
			C.Stats.StatStr("player", S);
	}
}

////////////////////////////////////////////////////////////////////////////////////

function string StatsClass()
{
	if (Level.NetMode == NM_Standalone || !Level.GetGameSpyManager().bTrackingStats)
		return "Engine.StatsInterface";
	else
		return MPStatsClass;
}

function ProcessServerTravel(string URL, bool bItems)
{
	Super.ProcessServerTravel(URL, bItems);

	Level.GetGamespyManager().OnLevelChange();
}

////////////////////////////////////////////////////////////////////////////////////
// Campaign stat interface

function bool ShouldTrackCampaignStats() {
  local bool OutValue;

  OutValue = Level.NetMode == NM_Standalone &&
         GetCustomScenario() == None &&
         Repo.GuiConfig.SwatGameRole == GAMEROLE_SP_Campaign;

  if(OutValue == false) {
    log("ShouldTrackCampaignStats() returned false, won't track campaign stats for this session.");
  }
  return OutValue;
}

function CampaignStats_TrackMissionCompleted()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.MissionsCompleted++;
}

function CampaignStats_TrackPlayerIncapacitation()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.TimesIncapacitated++;
}

function CampaignStats_TrackPlayerInjury()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.TimesInjured++;
}

function CampaignStats_TrackOfficerIncapacitation()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.OfficersIncapacitated++;
}

function CampaignStats_TrackPenaltyIssued()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.PenaltiesIssued++;
}

function CampaignStats_TrackSuspectRemoved()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.SuspectsRemoved++;
}

function CampaignStats_TrackSuspectNeutralized()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.SuspectsNeutralized++;

  CampaignStats_TrackSuspectRemoved(); // Also add to the "Threats Removed" stat
}

function CampaignStats_TrackSuspectIncapacitated()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.SuspectsIncapacitated++;

  CampaignStats_TrackSuspectRemoved(); // Also add to the "Threats Removed" stat
}

function CampaignStats_TrackSuspectArrested()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.SuspectsArrested++;

  CampaignStats_TrackSuspectRemoved(); // Also add to the "Threats Removed" stat
}

function CampaignStats_TrackCivilianRestrained()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.CiviliansRestrained++;
}

function CampaignStats_TrackTOCReport()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.TOCReports++;
}

function CampaignStats_TrackEvidenceSecured()
{
  local Campaign Campaign;

  if(!ShouldTrackCampaignStats()) {
    return;
  }

  Campaign = Repo.GetCampaign();
  Campaign.EvidenceSecured++;
}

////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////


defaultproperties
{
    PlayerControllerClassName="SwatGame.SwatGamePlayerController"
    HUDType="SwatGame.SwatHUD"
    MutatorClass="SwatGame.SwatMutator"
    GameReplicationInfoClass=class'SwatGame.SwatGameReplicationInfo'
    bDelayedStart=false
    bDebugFrames=false

    SPDamageModifierEasy=0.75;
    SPDamageModifierNormal=1;
    SPDamageModifierHard=1.25;
    SPDamageModifierElite=1.5;
    MPDamageModifier=1;
    COOPDamageModifier=1;

	VoiceReplicationInfoClass=class'SwatGame.SwatVoiceReplicationInfo'
	bAllowPrivateChat=True
    ScoringUpdateInterval=1.0

    ReconnectionTime=60.0

	MPStatsClass = "SwatGame.StatsGamespy"

	CurrentID = 1;
}
