class GameModeCOOP extends GameModeMPBase implements IInterested_GameEvent_MissionCompleted, IInterested_GameEvent_MissionFailed;

var private bool bMissionCompleted;

function OnMissionEnded()
{
    Super.OnMissionEnded();
    SGI.gameEvents.MissionFailed.UnRegister(self);
    SGI.gameEvents.MissionCompleted.UnRegister(self);
    SGI.gameEvents.PlayerDied.UnRegister(self);
}

function OnMissionCompleted()
{
    bMissionCompleted = true;
}

function OnMissionFailed()
{
    bMissionCompleted = false;
}

function EndGame()
{
    if( bMissionCompleted )
        NetRoundFinished( SRO_COOPCompleted );
    else
        NetRoundFinished( SRO_COOPFailed );
}


function Initialize()
{
	mplog( "Initialize() in GameModeCOOP." );
    Super.Initialize();

    SGI.gameEvents.MissionCompleted.Register(self);
    SGI.gameEvents.MissionFailed.Register(self);
    SGI.gameEvents.PlayerDied.Register(self);
}

// This is meant to do things like select which player has which voice set
function AssignPlayerRoles()
{
	local ServerSettings Settings;

	Settings = ServerSettings(Level.CurrentServerSettings);

	if (Settings != None && Settings.bNoLeaders)
	{
		// Ensure there are no leaders
		ClearLeader(NetTeam(SGI.GameReplicationInfo.Teams[0]));
		ClearLeader(NetTeam(SGI.GameReplicationInfo.Teams[2]));
	}
	else
	{
		// select leaders if needed

		if (GetLeader(NetTeam(SGI.GameReplicationInfo.Teams[0])) == None)
			SelectLeader(NetTeam(SGI.GameReplicationInfo.Teams[0]));

		if (GetLeader(NetTeam(SGI.GameReplicationInfo.Teams[2])) == None)
			SelectLeader(NetTeam(SGI.GameReplicationInfo.Teams[2]));
	}
}

// return a start point from the selected entry spawn cluster 
function SwatMPStartPoint FindNetPlayerStart( Controller Player )
{
    return Super.FindNetPlayerStart( Player );
}

// not used in COOP
function NetRoundTimeRemaining( int TimeRemaining ) 
{
    //coop mid-game is untimed
    if( SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState == GAMESTATE_MidGame )
        TimeRemaining = 0;
        
    Super.NetRoundTimeRemaining( TimeRemaining );
}

// not used in COOP
function NetRoundTimerExpired() {}

// not used in COOP
function SetSuspectsSpawnCluster( name NewSuspectsSpawnCluster ) {}

// not used in COOP
function RespawnAll() {}

//called when a player joins a team
// not used in COOP
function PlayerJoinedTeam( SwatGamePlayerController Player, NetTeam OldTeam, NetTeam CurrentTeam ) 
{
	Super.PlayerJoinedTeam(Player, OldTeam, CurrentTeam);

	// don't reselect leaders before the game has started
	if (SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState != GAMESTATE_MidGame)
		return;

	// if player was a leader, demote him
	if (SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).IsLeader)
	{
		SwatPlayerReplicationInfo(Player.PlayerReplicationInfo).IsLeader = false;
	}

	// if player's old team has no leader, then reselect leader
	if (GetLeader(OldTeam) == None)
		SelectLeader(OldTeam);

	// if player's new team has no leader, then reselect leader
	if (GetLeader(CurrentTeam) == None)
		SelectLeader(CurrentTeam);
}

function SwatGamePlayerController GetLeader( NetTeam Team )
{
    local Controller Controller;
    local SwatGamePlayerController SwatController;

	for ( Controller = SGI.Level.ControllerList; Controller != None; Controller = Controller.NextController )
	{
        SwatController = SwatGamePlayerController(Controller);
        if (SwatController != None)
        {
            if (SwatController.PlayerReplicationInfo.Team == Team && SwatPlayerReplicationInfo(SwatController.PlayerReplicationInfo).IsLeader)
				return SwatController;
        }
	}

	return None;
}

// gets a random leader for a team
function SwatGamePlayerController GetRandomLeader(NetTeam Team)
{
    local Controller Controller;
    local SwatGamePlayerController SwatController;
	local Array<SwatGamePlayerController> Choices;

	// get potential list of leaders
	for ( Controller = SGI.Level.ControllerList; Controller != None; Controller = Controller.NextController )
	{
        SwatController = SwatGamePlayerController(Controller);
        if (SwatController != None)
        {
            if (SwatController.PlayerReplicationInfo.Team == Team && 
				!SwatPlayerReplicationInfo(SwatController.PlayerReplicationInfo).IsLeader)
			{
				// only allow leader set midgame if player is not dead or spectating
				if (SwatRepo(Level.GetRepo()).GuiConfig.SwatGameState != GAMESTATE_MidGame
					|| (SwatController.Pawn != None && SwatController.Pawn.Health > 0))
					Choices[Choices.Length] = SwatController;
			}
        }
	}

	if (Choices.Length > 0)
	{
		return Choices[RandRange(0, Choices.Length - 1)];
	}
	else
	{
		return None;
	}
}

// finds the best leader for a team
function SwatGamePlayerController FindBestLeader(NetTeam Team)
{
	return GetRandomLeader(Team);
}

// removes leader flags for a team
// returns the old leader
function SwatGamePlayerController ClearLeader(NetTeam Team)
{
    local Controller Controller;
    local SwatGamePlayerController SwatController;
    local SwatGamePlayerController OldLeader;

	for ( Controller = SGI.Level.ControllerList; Controller != None; Controller = Controller.NextController )
	{
        SwatController = SwatGamePlayerController(Controller);
        if (SwatController != None)
        {
            if (SwatController.PlayerReplicationInfo.Team == Team)
			{
				if (SwatPlayerReplicationInfo(SwatController.PlayerReplicationInfo).IsLeader)
				{
					OldLeader = SwatController; 
					SwatPlayerReplicationInfo(SwatController.PlayerReplicationInfo).IsLeader = false;
				}
			}
        }
	}

	return OldLeader;
}

// chooses a leader for the given team
function SelectLeader(NetTeam Team)
{
	SetLeader(Team, FindBestLeader(Team));
}

function SetLeader(NetTeam Team, SwatGamePlayerController SwatController)
{
	local SwatGamePlayerController OldLeader;
	local ServerSettings Settings;

	Settings = ServerSettings(Level.CurrentServerSettings);

	if (Settings != None && Settings.bNoLeaders)
		return;

	OldLeader = ClearLeader(Team);

	if (SwatController != None)
	{
		SwatPlayerReplicationInfo(SwatController.PlayerReplicationInfo).IsLeader = true;

		// broadcast new leader message to players
		if (OldLeader != SwatController)
		{
			log("GameModeCOOP::SelectLeader - selected"@SwatController.PlayerReplicationInfo.PlayerName@"as leader.");
			SGI.Broadcast(None, Team.ColorizeName(SwatController.PlayerReplicationInfo.PlayerName), 'CoopLeaderPromoted');
		}
	}
}

// Override in derived class.
function bool ValidSpawnClusterForMode( SwatMPStartCluster theCluster )
{
    //only swat spawns allowed in coop
    return theCluster.ClusterTeam == MPT_Swat;
}

// Override in derived classes
function bool ClusterPointValidForRoundStart( SwatMPStartCluster thePoint )
{
    return true;
}

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

	// Coop modification -- team 0 starts at primary points, team 1 at secondary points

    for ( i = 0; i < 2; ++i )
    {
        // Set CurrentStartCluster to a StartCluster assigned to this team.
        HighestPointUsed[i] = -1;
        foreach AllActors( class'SwatMPStartCluster', ClusterPoint )
        {
		 	if (Level.GetEngine().EnableDevTools)
				mplog( "...Examining cluster: "$ClusterPoint );
				
            if ( (ClusterPoint.IsPrimaryEntryPoint && i == 0)
                 || (ClusterPoint.IsSecondaryEntryPoint && i == 1) )
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

// you can change teams in new coop without dying
function bool ShouldKillOnChangeTeam()
{
	return false;
}

// new coop requires three teams -- red, blue and suspects
function SetupTeams(GameReplicationInfo GRI)
{
    GRI.Teams[0] = Spawn(class'NetTeamCoopBlue');
    GRI.Teams[1] = Spawn(class'NetTeamCoopSuspects');
	GRI.Teams[2] = Spawn(class'NetTeamCoopRed');
}
 
// OnPlayerDied -- must reselect leader if leader dies
function OnPlayerDied( PlayerController player, Controller killer )
{
	Super.OnPlayerDied(player, killer);

	if (SwatPlayerReplicationInfo(player.PlayerReplicationInfo).IsLeader)
		SelectLeader(NetTeam(player.PlayerReplicationInfo.Team));
}
