// GameModeBS.uc

class GameModeBS extends GameModeMPBase
    dependsOn(SwatGUIConfig);

import enum eSwatGameState from SwatGame.SwatGUIConfig;

// Initial values for the arrays below
var private int DefaultNextRespawnTimerDuration;
var private int DefaultRespawnSecondsPenaltyIncrement;

// @TODO: Make these 2 config-diven
var private int nextRespawnTimerDuration[2];
var private int respawnSecondsPenaltyIncrement[2];

// MCJ-leave in
//var private Timer respawnTimer[2];
var private Timer respawnTimer;

// Get the value out of the server settings at the beginning of the round and
// cache it here.
var private int ScoreLimitForRound;


/////////////////////////////////////////
/////////////////////////////////////////
/////////////////////////////////////////

function OnMissionEnded()
{
    Super.OnMissionEnded();
    respawnTimer.StopTimer();
}

function Initialize()
{
    //local int i;

    mplog( "Initialize() in GameModeBS." );
    Super.Initialize();

// MCJ-leave in
//     for ( i = 0; i < 2; ++i )
//     {
//         nextRespawnTimerDuration[i] = DefaultNextRespawnTimerDuration;
//         respawnSecondsPenaltyIncrement[i] = DefaultRespawnSecondsPenaltyIncrement;
//     }

//     respawnTimer[0] = Spawn(class'Timer');
//     assert(respawnTimer[0] != None);
//     respawnTimer[0].timerDelegate = DecrementRespawnTimer0;

//     respawnTimer[1] = Spawn(class'Timer');
//     assert(respawnTimer[1] != None);
//     respawnTimer[1].timerDelegate = DecrementRespawnTimer1;

    respawnTimer = Spawn(class'Timer');
    assert(respawnTimer != None);
    respawnTimer.timerDelegate = DecrementRespawnTimers;

    ScoreLimitForRound = ServerSettings(Level.CurrentServerSettings).DeathLimit;
}


function OnMissionStarted()
{
    respawnTimer.StartTimer( 1.0, true );
}

function bool ValidSpawnClusterForMode( SwatMPStartCluster theCluster )
{
    return theCluster.UseInBarricadedSuspects;
}


function bool ClusterPointValidForRoundStart( SwatMPStartCluster thePoint )
{
    return thePoint.UseInBarricadedSuspects && thePoint.NeverFirstSpawnInBSRound == false;
}


function OnPawnArrested( Pawn player, Pawn Arrester )
{
    local SwatGamePlayerController pc;
    local int SWATScore;
    local int SuspectsScore;

    mplog( self$"---GameModeBS::OnPawnArrested(). player="$player$", Arrester="$Arrester );

    Super.OnPawnArrested( player, Arrester );

    // Check for end of round from ScoreLimit here.
    SwatScore = Teams[0].NetScoreInfo.GetScore();
    SuspectsScore = Teams[1].NetScoreInfo.GetScore();

    if ( SwatScore >= ScoreLimitForRound )
    {
        NetRoundFinished( SRO_SwatVictoriousNormal );
    }
    else if ( SuspectsScore >= ScoreLimitForRound )
    {
        NetRoundFinished( SRO_SuspectsVictoriousNormal );
    }
    else if( ServerSettings(Level.CurrentServerSettings).bNoRespawn )
    {
        pc = SwatGamePlayerController(player.Controller);
        if ( pc != None )
        {
            CheckIfRespawnIsNecessary( pc );
        }
    }
}


function OnPlayerDied(PlayerController player, Controller killer)
{
    local SwatGamePlayerController pc;
    local int SWATScore;
    local int SuspectsScore;

    mplog( self$"---GameModeBS::OnPlayerDied(). player="$player$", killer="$killer );

    Super.OnPlayerDied( player, killer );

    // Check for end of round from ScoreLimit here.
    SwatScore = Teams[0].NetScoreInfo.GetScore();
    SuspectsScore = Teams[1].NetScoreInfo.GetScore();

    if ( SwatScore >= ScoreLimitForRound )
    {
        NetRoundFinished( SRO_SwatVictoriousNormal );
    }
    else if ( SuspectsScore >= ScoreLimitForRound )
    {
        NetRoundFinished( SRO_SuspectsVictoriousNormal );
    }
    else if( ServerSettings(Level.CurrentServerSettings).bNoRespawn )
    {
        pc = SwatGamePlayerController(player);
        if ( pc != None )
        {
            CheckIfRespawnIsNecessary( pc );
        }
    }
}

function CheckIfRespawnIsNecessary( SwatGamePlayerController player )
{
    local int TeamNumber;

    mplog( self$"---GameModeBS::CheckIfRespawnIsNecessary()." );

    TeamNumber = player.SwatRepoPlayerItem.TeamID;
    
    if ( IsTeamAllDead(player, TeamNumber) )
    {
        mplog( "...team is dead." );
        
        // @TODO: Should we create a notification connection point for this
        // rather than calling it directly?
        if ( TeamNumber == 0 )
            NetRoundFinished( SRO_SuspectsVictoriousNormal );
        else
            NetRoundFinished( SRO_SwatVictoriousNormal );
    }
    else
    {
        //AdjustRespawnTimerDueToDeath( TeamNumber );
    }
}


// The parameter i is the team's index (0 or 1).
private function bool IsTeamAllDead( SwatGamePlayerController playerWhoDied, int i )
{
    local Controller controller;
    local SwatGamePlayerController player;

    mplog( self$"---GameModeBS::IsTeamAllDead(). playerWhoDied="$playerWhoDied$", team="$i );

    for (controller = level.controllerList; controller != none; controller = controller.nextController)
    {
        player = SwatGamePlayerController(controller);
        if ( player == None )
            continue;

        // MCJ: At the point when the game event fires, the playercontroller
        // has not yet entered the dead state. So if the playerWhoDied looks
        // like he's still alive but everyone else on the team is dead, then
        // really the whole team is dead.
        if ( player == playerWhoDied )
            continue;

        //mplog( "...player="$player );
        //mplog( "...player.SwatRepoPlayerItem.TeamID="$player.SwatRepoPlayerItem.TeamID );
        //mplog( "...player.HasEnteredFirstRoundOfNetworkGame()="$player.HasEnteredFirstRoundOfNetworkGame() );
        //mplog( "...player.IsDead()="$player.IsDead() );
        //mplog( "...player.IsCuffed()="$player.IsCuffed() );

        // Skip players who are not on the playerWhoDied's team.
        if ( player.SwatRepoPlayerItem.TeamID != i )
            continue;

        // Skip players who are still at the MPDebriefing screen.
        if ( !player.HasEnteredFirstRoundOfNetworkGame() )
            continue;

        if ( !player.IsDead() && !player.IsCuffed() )
        {
            // We've found a non-dead, non-cuffed player on our team.
            mplog( "...returning false." );
            return false;
        }
    }
    
    // Everyone on the team is dead so return true.
    mplog( "...returning true." );
    return true;
}

// MCJ-leav in
// // The parameter i is the team's index (0 or 1).
// private function AdjustRespawnTimerDueToDeath( int i )
// {
// 	// Increment duration to use next time the timer is started
// 	nextRespawnTimerDuration[i] += respawnSecondsPenaltyIncrement[i];

// 	if ( !respawnTimer[i].IsRunning() )
// 	{
// 		// Respawn timer is not yet running.

// 		respawnSecondsRemaining[i] = nextRespawnTimerDuration[i];

//         // Update timer every second, pass in true for a looping timer
// 		respawnTimer[i].StartTimer( 1.0, true );
// 	}

// }

// MCJ-leave in
// private function DecrementRespawnTimer0()
// {
//     DecrementRespawnTimer( 0 );
// }

// private function DecrementRespawnTimer1()
// {
//     DecrementRespawnTimer( 1 );
// }

private function DecrementRespawnTimers()
{
    DecrementRespawnTimer( 0 );
    DecrementRespawnTimer( 1 );
}

// MCJ: leave in
// protected function OnRespawnTimerAtZero(int team)
// {
//     // In barricaded suspects, respawn the team's reinforcements, and stop the
//     // timer altogether. The timer will start again once the next player on
//     // this team dies.
//     RespawnReinforcements( team );
//     respawnTimer[team].StopTimer();
// }


function NetRoundTimerExpired()
{
    local int SWATScore;
    local int SuspectsScore;

    // If the round timer expired, we award the win to the team with the
    // higher score, unless both teams had the same score, in which case we
    // declare it a tie.

    SwatScore = Teams[0].NetScoreInfo.GetScore();
    SuspectsScore = Teams[1].NetScoreInfo.GetScore();

    if ( SwatScore > SuspectsScore )
    {
        NetRoundFinished( SRO_SwatVictoriousNormal );
    }
    else if ( SuspectsScore > SwatScore )
    {
        NetRoundFinished( SRO_SuspectsVictoriousNormal );
    }
    else
    {
        NetRoundFinished( SRO_RoundEndedInTie );
    }
}

simulated event Destroyed()
{
    if (respawnTimer != None)
    {
        respawnTimer.Destroy();
        respawnTimer = None;
    }

    Super.Destroyed();
}

defaultproperties
{
	// NextRespawnTimerDuration is incremented every time someone dies,
    // so 0 is the proper initial value
    DefaultNextRespawnTimerDuration = 0;
    DefaultRespawnSecondsPenaltyIncrement = 5;
}

// MCJ:Leave in
//    DefaultRespawnSecondsRemaining = 0
