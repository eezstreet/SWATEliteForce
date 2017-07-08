// GameMode.uc

class GameMode extends Engine.Actor
    abstract
    config(SwatGame)
    native;

var SwatGameInfo SGI;

//Force game over
function EndGame()
{
    Assert( false );
}

function Initialize()
{
    mplog( self$"---GameMode::Initialize()." );
    SGI = SwatGameInfo(Owner);
    Assert( SGI != None ); 

    if ( Level.NetMode != NM_Standalone )
    {
		SetupTeams(SGI.GameReplicationInfo);
    }
}

// Override in derived class.
function OnMissionEnded();

// Override in derived class.
function SetStartClustersForRoundStart()
{
    Assert( false );
}


// This is meant to do things like select which player is the VIP.
function AssignPlayerRoles()
{
    Assert( false );
}


// Override in derived class.
function SwatMPStartPoint FindNetPlayerStart( Controller Player )
{
    Assert( false );
    return None;
}


function bool AllowRoundStart()
{
	return true;
}


// Override in derived class.
function NetRoundTimeRemaining( int TimeRemaining )
{
    Assert( false );
}


// Override in derived class.
function NetRoundTimerExpired()
{
    Assert( false );
}

// Override in derived class.
function SetSpawnClusterEnabled( name ClusterName, bool SetEnabled )
{
    Assert( false );
}

// Override in derived class.
function RespawnAll()
{
    Assert( false );
}


//called when a player joins a team
// subclasses should implement
function PlayerJoinedTeam( SwatGamePlayerController Player, NetTeam OldTeam, NetTeam CurrentTeam ) 
{
    Assert( false );
}

// return false to allow players to change team without being killed
function bool ShouldKillOnChangeTeam()
{
	return true;
}

// sets up teams for game modes
function SetupTeams(GameReplicationInfo GRI)
{
    GRI.Teams[0] = Spawn(class'NetTeamA');
    GRI.Teams[1] = Spawn(class'NetTeamB');
    GRI.Teams[2] = None;
}

defaultproperties
{
    bHidden=true
}
