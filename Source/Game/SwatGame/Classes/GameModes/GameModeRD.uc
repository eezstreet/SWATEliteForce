// GameModeRD.uc

class GameModeRD extends GameModeMPBase
    implements IInterested_GameEvent_BombDisabled;

////////////////////////////////////////////////////////////////////////////

// What are the differences between the BS mode and the RD mode?

// There are between one and three bombs in the map.
// The server sets the time limit for the bombs (they all have the same
// limit).

// I need bomb spawners.

//////////////////////////////////////////////////////////////////////////////

import enum eSwatGameState from SwatGame.SwatGUIConfig;

// There is a single respawn timer that is shared by both teams.
// The time amount is set by the server.
// It is always counting down and recycling.

// The docs say that there is a five second period between countdowns when if
// anyone dies, they respawn instantly. This sounds broken to me.


var private Timer respawnTimer;

var private int BombsInLevel;
var private int BombsDisabled;


/////////////////////////////////////////
/////////////////////////////////////////
/////////////////////////////////////////


function OnMissionEnded()
{
    Super.OnMissionEnded();
    respawnTimer.StopTimer();
    SGI.gameEvents.BombDisabled.UnRegister(self);
}

function Initialize()
{
    local BombBase Bomb;
    local SwatGameReplicationInfo SGRI;

    mplog( "Initialize() in GameModeRD." );
    Super.Initialize();

    SGI.gameEvents.BombDisabled.Register(self);

    respawnTimer = Spawn(class'Timer');
    assert(respawnTimer != None);
    respawnTimer.timerDelegate = DecrementRespawnTimers;

    // Spawn the bombs here. (before we count them)
    Level.SpawningManager.DoMPSpawning( SwatGameInfo(Level.Game), 'BombRoster' );

    BombsDisabled = 0;
    BombsInLevel = 0;
    foreach AllActors( class'BombBase', Bomb )
    {
        ++BombsInLevel;
    }
    mplog( "BombsInLevel="$BombsInLevel );
    AssertWithDescription( BombsInLevel > 0, "There are no bombs in the level!" );
    
    SGRI = SwatGameReplicationInfo(Level.Game.GameReplicationInfo);
    SGRI.DiffusedBombs = 0;
    SGRI.TotalNumberOfBombs = BombsInLevel;
}

function OnMissionStarted()
{
    respawnTimer.StartTimer( 1.0, true );
}


function bool ValidSpawnClusterForMode( SwatMPStartCluster theCluster )
{
    return theCluster.UseInRapidDeployment;
}


function bool ClusterPointValidForRoundStart( SwatMPStartCluster thePoint )
{
    return thePoint.UseInRapidDeployment && thePoint.NeverFirstSpawnInRDRound == false;
}

//dkaplan: removed totally random spawning by requests
// Overrides the method in GameModeMPBase, so that here we can select a spawn
// cluster randomly from that team's valid clusters.
//private function CalculateBestRespawnCluster( out SwatMPStartCluster outCluster,
//                                              array<SwatMPStartCluster> TeamStartClusters,
//                                              int EnemyTeamID )
//{
//    mplog( self$"---GameModeRD::CalculateBestRespawnCluster(). EnemyTeamID="$EnemyTeamID );
//
//    Assert( TeamStartClusters.length > 0 );
//
//    outCluster = TeamStartClusters[ Rand(TeamStartClusters.length) ];
//}


function OnPawnArrested( Pawn Arrestee, Pawn Arrester )
{
    mplog( self$"---GameModeRD::OnPlayerArrested(). Arrestee="$Arrestee$", Arrester="$Arrestee );

    Super.OnPawnArrested( Arrestee, Arrester );
}


function OnPlayerDied(PlayerController player, Controller killer)
{
    mplog( self$"---GameModeBS::OnPlayerDied(). player="$player$", killer="$killer );

    Super.OnPlayerDied( player, killer );
}


private function DecrementRespawnTimers()
{
    DecrementRespawnTimer( 0 );
    DecrementRespawnTimer( 1 );
}


function OnBombDisabled( BombBase TheBomb, Pawn Disarmer )
{
    local Controller controller;
    local SwatGamePlayerController player;

    local SwatGamePlayerController DisarmerController;
    local SwatPlayerReplicationInfo DisarmerInfo;
    local NetTeam DisarmerTeam;

    DisarmerController = SwatGamePlayerController(Disarmer.Controller);
    DisarmerInfo = SwatPlayerReplicationInfo(DisarmerController.PlayerReplicationInfo);
    DisarmerTeam = NetTeam(DisarmerController.playerReplicationInfo.team);

    mplog( self$"---GameModeBS::OnBombDisabled(). TheBomb="$TheBomb );

    Level.Game.dispatchMessage( new class'MessageBombDisarmed'( TheBomb.Spawner.GetSpawnerGroup(), TheBomb.Spawner.Name ) );

    // If the final bomb was disabled, stop the timer and signal that the
    // round is over.
    for (controller = level.controllerList; controller != none; controller = controller.nextController)
    {
        player = SwatGamePlayerController(controller);
        if ( player != None )
        {
            // fixme: move this text to an ini file so we can localize it.
            player.ClientMessage( "", 'DisarmBomb' );
        }
    }

	if (DisarmerController != None)
		DisarmerController.Stats.DiffusedBomb();

	// Update scores
    DisarmerInfo.netScoreInfo.IncrementBombsDiffused();
    DisarmerTeam.netScoreInfo.IncrementBombsDiffused();


    ++BombsDisabled;
    mplog( "...BombsDisabled="$BombsDisabled$", BombsInLevel="$BombsInLevel );

    SwatGameReplicationInfo(Level.Game.GameReplicationInfo).DiffusedBombs++;

    if ( BombsDisabled == BombsInLevel )
    {
        mplog( "...Round ended." );

        InterestingViewTarget = Disarmer;
        NetRoundFinished( SRO_SwatVictoriousRapidDeployment );
    }
}


function NetRoundTimeRemaining( int TimeRemaining )
{
//    local Controller controller;
//    local SwatGamePlayerController player;

    Super.NetRoundTimeRemaining( TimeRemaining );

    //if we are not actually playing, don't do anything else
    if( SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState != GAMESTATE_MidGame )
        return;
        
    //dkaplan: broadcast time before bomb explodes  
    SwatGameReplicationInfo(SGI.GameReplicationInfo).SpecialTime = TimeRemaining;
}


function NetRoundTimerExpired()
{
    local Controller controller;
    local SwatGamePlayerController PlayerController;
    local SwatPlayerReplicationInfo SPRI;
    local NetTeam TheirTeam;

    mplog( self$"...The Suspects won the round." );

    // Award Crybaby points to each player on the suspects team.
    for (Controller = Level.ControllerList; Controller != none; Controller = Controller.NextController)
    {
        PlayerController = SwatGamePlayerController(Controller);

        if ( PlayerController != None
             && PlayerController.SwatRepoPlayerItem.TeamID == 1 ) // Suspects == 1
        {
            SPRI = SwatPlayerReplicationInfo(PlayerController.PlayerReplicationInfo);
            TheirTeam = NetTeam(SPRI.Team);

            SPRI.NetScoreInfo.IncrementRDCrybaby();
            TheirTeam.NetScoreInfo.IncrementRDCrybaby();
        }
    }

    InterestingViewTarget = findStaticByLabel(class'Actor','BombExplodedMarker');

    NetRoundFinished( SRO_SuspectsVictoriousRapidDeployment );
}

simulated event Destroyed()
{
    local BombBase Bomb;
    
    SGI.gameEvents.BombDisabled.UnRegister(self);

    foreach AllActors( class'BombBase', Bomb )
    {
        Bomb.Destroy();
    }

    if (respawnTimer != None)
    {
        respawnTimer.Destroy();
        respawnTimer = None;
    }
    
    Super.Destroyed();
}


defaultproperties
{
}
