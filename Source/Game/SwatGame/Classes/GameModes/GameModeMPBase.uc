// GameModeMPBase.uc

class GameModeMPBase extends GameMode
    implements IInterested_GameEvent_PlayerDied,
               IInterested_GameEvent_PawnDied,
               IInterested_GameEvent_PawnArrested,
               IInterested_GameEvent_MissionStarted
    abstract
    native
    dependsOn(SwatGameInfo);

import enum ESwatRoundOutcome from SwatGameInfo;

var private bool bIsRespawningEnabled;

// During initialization, cache references to the two teams here.
var NetTeam Teams[2];

var protected SwatMPStartCluster CurrentStartCluster[2];
var protected int HighestPointUsed[2];

var protected array<SwatMPStartCluster> Team0StartClusters; // SWAT
var protected array<SwatMPStartCluster> Team1StartClusters; // Suspects

var config int DefaultRespawnSecondsRemaining;
var protected int respawnSecondsRemaining[2];

var protected Actor InterestingViewTarget;
var private Timer EndRoundSequenceTimer;

var private bool NotifiedOneMinuteWarning;
var private bool NotifiedTenSecondsWarning;

// override in derived classes.
function OnMissionStarted();

function OnMissionEnded()
{
    SGI.gameEvents.playerDied.UnRegister(self);
    SGI.gameEvents.pawnDied.UnRegister(self);
    SGI.gameEvents.pawnArrested.UnRegister(self);
    SGI.gameEvents.MissionStarted.UnRegister(self);
}

//end game ends the round immediately - by default, do the same thing thats done when the timer expires
function EndGame()
{
    NetRoundTimerExpired();
}

function Initialize()
{
    local int i;
    local SwatMPStartCluster ClusterPoint;

 	if (Level.GetEngine().EnableDevTools)
		mplog( "Initialize() in GameModeMPBase." );

    Super.Initialize();

	SGI.gameEvents.playerDied.Register(self);
    SGI.gameEvents.pawnDied.Register(self);
    SGI.gameEvents.pawnArrested.Register(self);
    SGI.gameEvents.MissionStarted.Register(self);

    // Turn the no-respawn double-negative into a positive
    assert(Level != None);
    assert(Level.CurrentServerSettings != None);
    assert(ServerSettings(Level.CurrentServerSettings) != None);
    bIsRespawningEnabled = !ServerSettings(Level.CurrentServerSettings).bNoRespawn;

    if( !Level.IsCOOPServer )
    {
        for ( i = 0; i < 2; ++i )
        {
            Teams[i] = SGI.GetTeamFromID( i );
            Assert( Teams[i] != None );

            respawnSecondsRemaining[i] = DefaultRespawnSecondsRemaining;
        }
    }

	if (RequiresStartClustersCache())
	{
		// Cache the start clusters.
		foreach AllActors( class'SwatMPStartCluster', ClusterPoint )
		{
			if ( ValidSpawnClusterForMode( ClusterPoint ) )
			{
				//ensure all clusters are enabled at the start of the round
				ClusterPoint.IsEnabled = true;

				if ( ClusterPoint.ClusterTeam == MPT_Swat )
				{
					Team0StartClusters[Team0StartClusters.Length] = ClusterPoint;
				}
				else
				{
					Team1StartClusters[Team1StartClusters.Length] = ClusterPoint;
				}
			}
		}

		if( !Level.IsCOOPServer )
		{
			AssertWithDescription( Team0StartClusters.Length > 0, "Team 0 has no SwatMPStartClusters." );
			AssertWithDescription( Team1StartClusters.Length > 0, "Team 1 has no SwatMPStartClusters." );
		}
	}

	Level.GetGamespyManager().OnServerReceivedStatsResponse = OnServerReceivedStatsResponse;
}

// notify client of stats validation
function OnServerReceivedStatsResponse(PlayerController P, int statusCode)
{
	switch (statusCode)
	{
	case 0:
		SGI.Broadcast(None, "", 'StatsValidatedMessage', P);
		break;
	case 1:
		SGI.Broadcast(None, "", 'StatsBadProfileMessage', P);
		break;
	default:
	}
}

function bool RequiresStartClustersCache()
{
	return true;
}

// Override in derived class.
function bool ValidSpawnClusterForMode( SwatMPStartCluster theCluster )
{
    Assert( false );
    return true;
}


// This is meant to do things like select which player is the VIP. Do nothing
// in BS and RD, but override in VIP mode.
function AssignPlayerRoles()
{
    local Controller Controller;
    local SwatGamePlayerController PlayerController;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---GameModeMPBase::AssignPlayerRoles()." );

    for (Controller = Level.ControllerList; Controller != none; Controller = Controller.NextController)
    {
        PlayerController = SwatGamePlayerController(Controller);

        if (PlayerController != None )
        {
            PlayerController.ThisPlayerIsTheVIP = false;
            SwatPlayerReplicationInfo(PlayerController.PlayerReplicationInfo).bIsTheVIP = false;
        }
    }
}


/////////////////////////////////////////////////////////////////////////////
// Select initial spawn clusters
/////////////////////////////////////////////////////////////////////////////
function SetStartClustersForRoundStart()
{
    local int i;
    local SwatMPStartCluster ClusterPoint;

 	if (Level.GetEngine().EnableDevTools)
	    log( self$"---GameModeMPBase::SetStartClustersForRoundStart()." );

	// Cluster.IsPrimary/SecondaryEntryPoint

    // If we're switching levels, we don't need to bother figuring out which
    // cluster is farthest away from enemies; we can just pick any of the
    // clusters. If we're respawning during a round, we should do the enemy
    // proximity test.

    for ( i = 0; i < 2; ++i )
    {
        // Set CurrentStartCluster to a StartCluster assigned to this team.
        HighestPointUsed[i] = -1;
        foreach AllActors( class'SwatMPStartCluster', ClusterPoint )
        {
		 	if (Level.GetEngine().EnableDevTools)
				mplog( "...Examining cluster: "$ClusterPoint );

            if ( (ClusterPoint.ClusterTeam == MPT_Swat && i == 0)
                 || (ClusterPoint.ClusterTeam == MPT_Suspects && i == 1) )
            {
                if ( ClusterPointValidForRoundStart( ClusterPoint ) )
                {
 					if (Level.GetEngine().EnableDevTools)
						log( "......setting CurrentStartCluster to "$ClusterPoint );

					CurrentStartCluster[i] = ClusterPoint;
					break;
				}
			}
		}
	}
}

// Override in derived classes
function bool ClusterPointValidForRoundStart( SwatMPStartCluster thePoint )
{
    Assert( false );
    return true;
}

/////////////////////////////////////////////////////////////////////////////
// Enable/Disable spawn clusters
/////////////////////////////////////////////////////////////////////////////
function SetSpawnClusterEnabled( name ClusterName, bool SetEnabled )
{
    SetSpawnClusterEnabledForArray( Team0StartClusters, ClusterName, SetEnabled );
    SetSpawnClusterEnabledForArray( Team1StartClusters, ClusterName, SetEnabled );
}

private function SetSpawnClusterEnabledForArray( array<SwatMPStartCluster> TeamStartClusters, name ClusterName, bool SetEnabled )
{
    local int i;

    for( i = 0; i < TeamStartClusters.Length; i++ )
    {
        if( TeamStartClusters[i].Label == ClusterName )
            TeamStartClusters[i].IsEnabled = SetEnabled;
    }
}

/////////////////////////////////////////////////////////////////////////////
// Select the spawn cluster to be used for restart
/////////////////////////////////////////////////////////////////////////////
function SetStartClusterForRespawn( int TeamID )
{
 	if (Level.GetEngine().EnableDevTools)
		mplog( self$"---GameModeMPBase::SetStartClusterForRespawn(). TeamID="$TeamID );

    // Depending on the team. pass the proper parameters into
    // CalculateBestRespawnCluster, which does all the heavy lifting of
    // choosing a respawn cluster.
    HighestPointUsed[TeamID] = -1;
    if (TeamID == 0)
        CalculateBestRespawnCluster(CurrentStartCluster[0], Team0StartClusters, 1);
    else
        CalculateBestRespawnCluster(CurrentStartCluster[1], Team1StartClusters, 0);

 	if (Level.GetEngine().EnableDevTools)
		mplog("CurrentStartCluster for TeamID "$TeamID$" is now "$CurrentStartCluster[TeamID]);
}

// Calculates the best respawn cluster, that has the farthest path-based
// distance from any other pawn on the enemy team.
private function CalculateBestRespawnCluster(out SwatMPStartCluster outCluster,
                                             array<SwatMPStartCluster> TeamStartClusters,
                                             int EnemyTeamID)
{
    local bool  bFoundFirstDistance;
    local float BestClusterDistanceFromEnemy;
    local float ThisClusterDistanceFromEnemy;
    local int i;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---GameModeMPBase::CalculateBestRespawnCluster(). EnemyTeamID="$EnemyTeamID );

    outCluster = None;

    for (i = 0; i < TeamStartClusters.length; i++)
    {
        if( !TeamStartClusters[i].IsEnabled )
            continue;

        ThisClusterDistanceFromEnemy = CalculateClusterDistanceFromEnemyPawns(TeamStartClusters[i], EnemyTeamID);
        // The farther the better..
        if (!bFoundFirstDistance ||
            ThisClusterDistanceFromEnemy > BestClusterDistanceFromEnemy)
        {
            bFoundFirstDistance = true;
            outCluster = TeamStartClusters[i];
            BestClusterDistanceFromEnemy = ThisClusterDistanceFromEnemy;
        }
    }

    AssertWithDescription( outCluster != None, "There are no valid spawn clusters enabled for the current mode.  At least one spawn cluster must be made available for spawning!" );
}

// Helper function for the CalculateBestRespawnCluster function. Calculates
// the path-based distance from a spawn cluster to the closest enemy pawn.
private function float CalculateClusterDistanceFromEnemyPawns(SwatMPStartCluster TeamStartCluster, int EnemyTeamID)
{
    local Controller Controller;
    local SwatGamePlayerController PlayerController;

    local bool  bFoundFirstDistance;
    local float ClosestDistanceFromClusterToEnemyPawn;
    local float ThisDistanceFromClusterToEnemyPawn;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---GameModeMPBase::CalculateClusterDistanceFromEnemyPawns()." );

    for (Controller = Level.ControllerList; Controller != none; Controller = Controller.NextController)
    {
        PlayerController = SwatGamePlayerController(Controller);

        // If this player is not dead or cuffed, and his pawn is on the other
        // team, find the distance from the cluster to him.
        if (PlayerController != None && PlayerController.SwatPlayer != None &&
           !PlayerController.IsDead() && !PlayerController.IsCuffed() &&
            PlayerController.SwatRepoPlayerItem.TeamID == EnemyTeamID)
        {
            ThisDistanceFromClusterToEnemyPawn = CalculateClusterDistanceFromPawn(TeamStartCluster, PlayerController.SwatPlayer);
            if (!bFoundFirstDistance ||
                ThisDistanceFromClusterToEnemyPawn < ClosestDistanceFromClusterToEnemyPawn)
            {
                bFoundFirstDistance = true;
                ClosestDistanceFromClusterToEnemyPawn = ThisDistanceFromClusterToEnemyPawn;
            }
        }
    }

    return ClosestDistanceFromClusterToEnemyPawn;
}

// Helper function for the CalculateClusterDistanceFromEnemyPawns function.
// Calculates the path-based distance from a spawn cluster to a pawn.
private native function float CalculateClusterDistanceFromPawn(SwatMPStartCluster FromTeamStartCluster, Pawn ToPawn);

///////////////////////////////////////////////////////////////////////////////
//
// This function should find the first start point in player's team's current
// cluster that doesn't have something already on it.
//
function SwatMPStartPoint FindNetPlayerStart( Controller Player )
{
    local SwatMPStartPoint thePoint;
    local NetTeam TheNetTeam;
    local SwatGamePlayerController thePlayerController;
    local SwatMPStartCluster TheStartCluster;
    local int TeamID;
    local int i;

	if (Level.GetEngine().EnableDevTools)
	    mplog( "---GameModeMPBase::FindNetPlayerStart(). Player="$Player );

    thePlayerController = SwatGamePlayerController( Player );
    assert( thePlayerController != None );

    if (ServerSettings(Level.CurrentServerSettings).isCampaignCoop())
	{TeamID = SwatRepo(Level.GetRepo()).GuiConfig.GetDesiredEntryPoint() * 2;}
	else
	{TeamID = thePlayerController.SwatRepoPlayerItem.TeamID;}

    TheNetTeam = SGI.GetTeamFromID( TeamID );

    TheStartCluster = CurrentStartCluster[TeamID];
    assert( TheStartCluster != None );

    // Need to set bCollide on the SwatMPStartPoint class.

    // Search through the cluster's points and find the first one that doesn't
    // have a collision.
    for ( i = HighestPointUsed[TeamID] + 1; i < TheStartCluster.NumberOfStartPoints; ++i )
    {
	 	if (Level.GetEngine().EnableDevTools)
			log( "   testing point: "$i );

        thePoint = TheStartCluster.StartPoints[ i ];
        assert( thePoint != None );

        if ( SpawnPointCanBeUsed(thePoint) )
        {
            // Use this start point
		 	if (Level.GetEngine().EnableDevTools)
				mplog( "  using point: "$i );

            HighestPointUsed[TeamID] = i;
            break;
        }
    }
    if ( i == TheStartCluster.NumberOfStartPoints )
    {
	 	if (Level.GetEngine().EnableDevTools)
			mplog( " returning none." );
        return None;
    }
    else
    {
	 	if (Level.GetEngine().EnableDevTools)
			mplog( " returning thePoint. thePoint="$thePoint );

        return thePoint;
    }
}

private function bool SpawnPointCanBeUsed( Actor thePoint )
{
    local int j;

    for ( j = 0; j < thePoint.Touching.Length; ++j )
    {
	 	if (Level.GetEngine().EnableDevTools)
			mplog( ".......Touching["$j$"]="$thePoint.Touching[j] );

        if ( thePoint.Touching[j].bBlockActors )
        {
		 	if (Level.GetEngine().EnableDevTools)
		 	{
				mplog( "*** Spawn point failed!!! ***" );
				mplog( "...spawn point="$thePoint );
            }

            return false;
        }
    }

    return true;
}


///////////////////////////////////////////////////////////////////////////////
//
//
// The parameter is the team's index (0 or 1).
function RespawnReinforcements( int TeamID )
{
    local Controller i, controller;
    local SwatGamePlayerController current, SGPC;
    local SwatGamePlayerController theLocalPlayerController;
    local NetPlayer TheNetPlayer;
    local int NumberOfRespawningPlayers;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( "---GameModeMPBase::RespawnReinforcements(). TeamID="$TeamID );

    // This function is expected never to be called on the client.
    assert(role == ROLE_Authority);

    SetStartClusterForRespawn( TeamID );

    // Destroy the dead pawns before restarting the players.
    Teams[TeamID].DestroyPawnsForRespawn();

    // Notify all clients to DestroyPawnsForRespawn() locally.
    // Walk the controller list here to notify all clients about the
    // ThrowPrep, except don't make the call for the server and don't make it
    // for the client who is throwing.
    theLocalPlayerController = SwatGamePlayerController(Level.GetLocalPlayerController());
    for ( i = Level.ControllerList; i != None; i = i.NextController )
    {
        current = SwatGamePlayerController( i );
        if ( current != None && current != theLocalPlayerController )
        {
            current.ClientDestroyPawnsForRespawn( TeamID );
        }
    }

    NumberOfRespawningPlayers = 0;
    for (controller = level.controllerList; controller != none; controller = controller.nextController)
    {
        SGPC = SwatGamePlayerController(controller);
        TheNetPlayer = NetPlayer(SGPC.SwatPlayer);
        //mplog( "" );
        //mplog( "...controller="$SGPC );
        //mplog( "...NetPlayer="$TheNetPlayer );
        //mplog( "...TeamID="$SGPC.SwatRepoPlayerItem.TeamID );
        //mplog( "...IsDead()="$SGPC.IsDead() );
        //mplog( "...IsCuffed()="$SGPC.IsCuffed() );
        //mplog( "...IsTheVIP()="$TheNetPlayer.IsTheVIP() );

        if( SGPC != none
            && SGPC.HasEnteredFirstRoundOfNetworkGame()                             //only spawn if the player has clicked ready
            && SGPC.SwatRepoPlayerItem.TeamID == TeamID
            && ( SGPC.IsDead() || (SGPC.IsCuffed() && !TheNetPlayer.IsTheVIP()) ))
        {
            //mplog( "......restarting player!" );
            level.game.RestartPlayer(SGPC);
            NumberOfRespawningPlayers++;
        }
        else
        {
            //mplog( "......NOT restarting player." );
        }

        //ensure somebody is always available as last killer
        if( SGPC != None && InterestingViewTarget == None )
            InterestingViewTarget = SGPC.Pawn;
    }

 	if (Level.GetEngine().EnableDevTools)
		mplog( "*** DONE RESPAWNING ***" );

    if ( NumberOfRespawningPlayers > 0 )
    {
        if ( TeamID == 0 )
            SGI.Broadcast( None, "", 'SwatRespawnEvent' );
        else
            SGI.Broadcast( None, "", 'SuspectsRespawnEvent' );
    }
}



function NetRoundTimeRemaining( int TimeRemaining )
{
    //broadcast the time remaining in the round
    SwatGameReplicationInfo(SGI.GameReplicationInfo).RoundTime = TimeRemaining;

    if( SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState != GAMESTATE_MidGame )
        return;

    if( TimeRemaining <= 0 )
        return;

    if ( TimeRemaining <= 60 && !NotifiedOneMinuteWarning )
    {
        NotifiedOneMinuteWarning = true;

        //dkaplan: this can be done as a broadcast to all players
        SGI.Broadcast( None, "", 'OneMinWarning' );
    }

    if ( TimeRemaining <= 10 && !NotifiedTenSecondsWarning )
    {
        NotifiedTenSecondsWarning = true;

        //dkaplan: this can be done as a broadcast to all players
        SGI.Broadcast( None, "", 'TenSecWarning' );
    }
}


function OnPawnArrested( Pawn player, Pawn Arrester )
{
    local SwatGamePlayerController  swatVictim;
    local SwatGamePlayerController  swatArrester;
    local SwatPlayerReplicationInfo swatVictimInfo;
    local SwatPlayerReplicationInfo swatArresterInfo;
    local NetTeam swatVictimTeam;
    local NetTeam swatArresterTeam;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---GameModeMPBase::OnPawnArrested(). player="$player$", Arrester="$Arrester );

    swatVictim = SwatGamePlayerController(player.Controller);

    // In Coop, we don't want to do any of this stuff. In Coop, swatVictim
    // will be None because the arrestee is an AI.
    if ( swatVictim != None )
    {
    swatArrester = SwatGamePlayerController(Arrester.Controller);
    swatVictimInfo = SwatPlayerReplicationInfo(swatVictim.PlayerReplicationInfo);
    swatVictimTeam = NetTeam(swatVictim.playerReplicationInfo.team);
    swatArresterInfo = SwatPlayerReplicationInfo(swatArrester.PlayerReplicationInfo);
    swatArresterTeam = NetTeam(swatArrester.playerReplicationInfo.team);

    // Increment victim arrest stat
    swatVictimInfo.netScoreInfo.IncrementTimesArrested();
    swatVictimTeam.netScoreInfo.IncrementTimesArrested();

    // Increment arrester's stat
    if ( NetPlayer(player).IsTheVIP() )
    {
        swatArresterInfo.netScoreInfo.IncrementArrestedVIP();
        swatArresterTeam.netScoreInfo.IncrementArrestedVIP();
    }
    else
    {
        swatArresterInfo.netScoreInfo.IncrementArrests();
        swatArresterTeam.netScoreInfo.IncrementArrests();
    }

    SGI.BroadcastArrestedMessage( swatArrester, swatVictim );
    }

    InterestingViewTarget = Arrester;
}


// I think that this will work fine for all MP GameModes. Make sure the
// derived classes call it from their OnPlayerDied() handler.
function OnPlayerDied( PlayerController player, Controller killer )
{
    local SwatGamePlayerController  swatVictim;
    local SwatGamePlayerController  swatKiller;
    local SwatPlayerReplicationInfo swatVictimInfo;
    local SwatPlayerReplicationInfo swatKillerInfo;
    local NetTeam swatVictimTeam;
    local NetTeam swatKillerTeam;
    local SwatPlayer ThePlayer;

    swatVictim = SwatGamePlayerController(player);
    swatKiller = SwatGamePlayerController(killer);

    // Return and do nothing if the player who died was already arrested and
    // was not the VIP.
    ThePlayer = swatVictim.SwatPlayer;
    Assert( ThePlayer != None );
    if ( ThePlayer.IsArrested() && !ThePlayer.IsTheVIP() )
        return;

    swatVictimInfo = SwatPlayerReplicationInfo(swatVictim.PlayerReplicationInfo);
    swatVictimTeam = NetTeam(swatVictim.playerReplicationInfo.team);
    if (swatKiller != none)
    {
        swatKillerInfo = SwatPlayerReplicationInfo(swatKiller.PlayerReplicationInfo);
        swatKillerTeam = NetTeam(swatKiller.playerReplicationInfo.team);
    }

    // Increment victim death
    swatVictimInfo.netScoreInfo.IncrementTimesDied();
    swatVictimTeam.netScoreInfo.IncrementTimesDied();

    // Increment killer's kill; dkaplan: only if it wasn't a suicide
    if (swatKiller != none && swatKiller != swatVictim )
    {
        if (swatVictimTeam != swatKillerTeam)
        {
            // Killed an enemy
            swatKillerInfo.netScoreInfo.IncrementEnemyKills();
            swatKillerTeam.netScoreInfo.IncrementEnemyKills();
        }
        else
        {
            // Killed a teammate
            swatKillerInfo.netScoreInfo.IncrementFriendlyKills();
            swatKillerTeam.netScoreInfo.IncrementFriendlyKills();
        }
    }

    //also updated by OnPawnDied
    InterestingViewTarget = swatKiller.Pawn;
}

// I think that this will work fine for all MP GameModes. Make sure the
// derived classes call it from their OnPawnDied() handler.
function OnPawnDied( Pawn Pawn, Actor Killer, bool WasAThreat )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"::OnPawnDied() ... setting InterestingViewTarget to "$Killer );
    InterestingViewTarget = Killer;
}


//called when a player joins a team
// subclasses should implement if mode-specific functionality is needed.
function PlayerJoinedTeam( SwatGamePlayerController Player, NetTeam OldTeam, NetTeam CurrentTeam )
{
}


// We used to use this command, but aren't currently. I'm leaving the code
// here in case we need it again.
function RespawnAll()
{
//     local int i;
//     local NetTeam NetTeam;

//     if (Role == ROLE_Authority)
//     {
//         for (i = 0; i < ArrayCount(Level.Game.GameReplicationInfo.Teams); ++i)
//         {
//             NetTeam = NetTeam(Level.Game.GameReplicationInfo.Teams[i]);
//             NetTeam.RespawnReinforcements();
//         }
//     }
}

protected function bool IsRespawningEnabled()
{
	if (SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState == GAMESTATE_PreGame && !SwatGameReplicationInfo(SGI.GameReplicationInfo).AllPlayersAreReady())
		return false;

    return bIsRespawningEnabled;
}

protected function DecrementRespawnTimer( int team )
{
    //mplog( "---GameModeMPBase::DecrementRespawnTimer(). TeamID="$team );

    // This function is expected never to be called on the client.
    assert(role == ROLE_Authority);

    // Only decrement & display the timer, and respawn players, if respawning
    // is enabled.
    if (IsRespawningEnabled())
    {
        respawnSecondsRemaining[team]--;

		if (respawnSecondsRemaining[team] < 0)
			respawnSecondsRemaining[team] = 0;

        Teams[team].SetRespawnSecondsRemaining( respawnSecondsRemaining[team] );

        DisplayRespawnTimer( team );

        // When the remaining seconds falls to 0, stop the timer and respawn
        // all dead players
        if (respawnSecondsRemaining[team] <= 0)
        {
            OnRespawnTimerAtZero( team );
        }
    }

    UpdatePlayerDeathFlags( team );
}

// The parameter is the team's index (0 or 1).
protected function UpdatePlayerDeathFlags( int team )
{
    local Controller controller;
    local SwatGamePlayerController player;

    // Restart players
    for (controller = level.controllerList; controller != none; controller = controller.nextController)
    {
        player = SwatGamePlayerController(controller);
        if (player != none && player.SwatRepoPlayerItem.TeamID == team)
        {
            SwatPlayerReplicationInfo(player.PlayerReplicationInfo).bIsDead = player.IsDead();
        }
    }
}

protected function OnRespawnTimerAtZero(int team)
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( "---GameModeMPBase::OnRespawnTimerAtZero(). TeamID="$team );

    // By default, respawn the team's reinforcements, and cycle the respawn
    // timer back to the default length.
    RespawnReinforcements( team );

	// dbeswick: set respawn wave time
 	if (Level.GetEngine().EnableDevTools)
	    mplog( "...setting respawn timer for team "$team$" to: "$DefaultRespawnSecondsRemaining + ServerSettings(Level.CurrentServerSettings).AdditionalRespawnTime);

    respawnSecondsRemaining[team] = DefaultRespawnSecondsRemaining + ServerSettings(Level.CurrentServerSettings).AdditionalRespawnTime;
}

// The parameter is the team's index (0 or 1).
protected function DisplayRespawnTimer( int team )
{
    local Controller controller;
    local SwatGamePlayerController player;

    // Restart players
    for (controller = level.controllerList; controller != none; controller = controller.nextController)
    {
        player = SwatGamePlayerController(controller);
        if (player != none && player.SwatRepoPlayerItem.TeamID == team)
        {
            if (respawnSecondsRemaining[team] > 0)
            {
                //only send respawn timer to dead players
                if( player.IsDead() )
                    SwatPlayerReplicationInfo(player.PlayerReplicationInfo).RespawnTime = respawnSecondsRemaining[team];
                else
                    SwatPlayerReplicationInfo(player.PlayerReplicationInfo).RespawnTime = 0;
            }
        }
    }
}

protected final function NetRoundFinished( ESwatRoundOutcome RoundOutcome )
{
    OnMissionEnded();
    SetAllPawnsRelevent();
    StartEndRoundSequence();

    EndRoundSequenceTimer = Spawn(class'Timer');
    assert(EndRoundSequenceTimer != None);
    EndRoundSequenceTimer.timerDelegate = SetEndRoundTarget;
    EndRoundSequenceTimer.StartTimer( SwatRepo(Level.GetRepo()).GuiConfig.MPPostMissionTime / 3.0 );

    SwatRepo(Level.GetRepo()).OnNetRoundFinished( RoundOutcome );

    SwatGameReplicationInfo(SGI.GameReplicationInfo).OnMissionEnded();
}

// Distributes ViewFromActor to all playercontrollers.
protected function SetAllPawnsRelevent()
{
    local Controller Controller;
    local SwatGamePlayerController PlayerController;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---GameModeMPBase::SetAllPawnsRelevent()." );

    for (Controller = Level.ControllerList; Controller != none; Controller = Controller.NextController)
    {
        PlayerController = SwatGamePlayerController(Controller);

        if (PlayerController != None && PlayerController.Pawn != None)
        {
            PlayerController.Pawn.bAlwaysRelevant = true;
        }
    }
}

// Distributes ViewFromActor to all playercontrollers.
protected function StartEndRoundSequence()
{
    local Controller Controller;
    local SwatGamePlayerController PlayerController;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---GameModeMPBase::StartEndRoundSequence()." );

    for (Controller = Level.ControllerList; Controller != none; Controller = Controller.NextController)
    {
        PlayerController = SwatGamePlayerController(Controller);

        if (PlayerController != None )
        {
            PlayerController.DoStartEndRoundSequence();
            if ( PlayerController.SwatPlayer != None )
                PlayerController.SwatPlayer.ServerEndFiringWeapon();
        }
    }
}

// Distributes ViewFromActor to all playercontrollers.
protected function SetEndRoundTarget()
{
    local Controller Controller;
    local SwatGamePlayerController PlayerController;
    local string TargetName;
    local bool TargetOnSWAT;

    if( NetPlayer(InterestingViewTarget) != None )
    {
        TargetName = InterestingViewTarget.GetHumanReadableName();
        TargetOnSWAT = NetPlayer(InterestingViewTarget).GetTeamNumber() == 0;
    }

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---GameModeMPBase::SetEndRoundTarget(). InterestingViewTarget = "$InterestingViewTarget );

    for (Controller = Level.ControllerList; Controller != none; Controller = Controller.NextController)
    {
        PlayerController = SwatGamePlayerController(Controller);

        if (PlayerController != None )
        {
            PlayerController.DoSetEndRoundTarget( InterestingViewTarget, TargetName, TargetOnSWAT );
        }
    }
}

////////////////////////////////////////////////////////////////////
// When destroyed, the GameMode should reset all of the applicable
//   game state data - required for Quick Restart
////////////////////////////////////////////////////////////////////
simulated event Destroyed()
{
    local int i;
    local TriggerVolume TV;

    SGI.gameEvents.playerDied.UnRegister(self);
    SGI.gameEvents.pawnDied.UnRegister(self);
    SGI.gameEvents.pawnArrested.UnRegister(self);

    //get rid of all the pawns on all the clients
    DestroyAllPawns();

    //reset spawning
    Level.SpawningManager.ResetForMPQuickRestart(Level);

    //clear team scores
    for( i = 0; i < 2; i++ )
    {
        Teams[i].NetScoreInfo.ResetForMPQuickRestart();
    }

    //clear the player scores
    SwatGameReplicationInfo(Level.Game.GameReplicationInfo).ResetPlayerScoresForMPQuickRestart();

    //reset all trigger volumes to initial states
    foreach AllActors( class'TriggerVolume', TV )
    {
        TV.ResetForMPQuickRestart();
    }

    if (EndRoundSequenceTimer != None)
    {
        EndRoundSequenceTimer.Destroy();
        EndRoundSequenceTimer = None;
    }

    Super.Destroyed();
}

////////////////////////////////////////////////////////////////////
// Clean out all Pawn on all clients - required for Quick Restart
////////////////////////////////////////////////////////////////////
protected final function DestroyAllPawns()
{
    local Pawn P;
    local Controller Controller;
    local SwatGamePlayerController PlayerController;

 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---GameModeMPBase::DestroyAllPawns()." );

    for (Controller = Level.ControllerList; Controller != none; Controller = Controller.NextController)
    {
        PlayerController = SwatGamePlayerController(Controller);

        if (PlayerController != None )
        {
            PlayerController.ClientDestroyAllPawns();
        }
    }

    foreach AllActors( class'Pawn', P )
    {
        P.Destroy();
    }
}

defaultproperties
{
    DefaultRespawnSecondsRemaining = 30
    NotifiedOneMinuteWarning = false
    NotifiedTenSecondsWarning = false
}
