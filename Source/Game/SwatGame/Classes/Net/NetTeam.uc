///////////////////////////////////////////////////////////////////////////////
//
// Common base for a network team. Extends engine's TeamInfo class, and stores
// which Controllers are a part of its team. Also manages the team's respawn
// timer.
//

class NetTeam extends Engine.TeamInfo
    dependsOn(SwatGameInfo);


///////////////////////////////////////////////////////////////////////////////

var NetScoreInfo	netScoreInfo;
var private int		respawnSecondsRemaining;

var bool			AIOnly; // dbeswick:
var string			ColorTag; // dbeswick:

// Contains references to pawns on this team who have died, but whose pawns
// need to be destroyed when the respawn timer goes off.
var private array<NetPlayer> PawnsToDestroy;

///////////////////////////////////////////////////////////////////////////////

replication
{
    // Variables the server should send to the client.
    reliable if (bNetDirty && (Role == ROLE_Authority))
        respawnSecondsRemaining, netScoreInfo;
}

///////////////////////////////////////////////////////////////////////////////

event PreBeginPlay()
{
    Super.PreBeginPlay();

    NetScoreInfo = Spawn(class'NetScoreInfo');
}


// override in derived class
simulated function int GetTeamNumber()
{
    return -1;
}


simulated function string GetHumanReadableName()
{
    return teamName;
}


simulated function int GetRespawnSecondsRemaining()
{
    return respawnSecondsRemaining;
}


// Called only on the server.
function SetRespawnSecondsRemaining( int Seconds )
{
    Assert( Level.NetMode == NM_ListenServer || Level.NetMode == NM_DedicatedServer );
    respawnSecondsRemaining = Seconds;
}

simulated function AddNetPlayerToDestroy( NetPlayer PawnToDestroy )
{
 	if (Level.GetEngine().EnableDevTools)
	    mplog( self$"---NetTeam::AddNetPlayerToDestroy(). PawnToDestroy="$PawnToDestroy );

    PawnsToDestroy[ PawnsToDestroy.Length ] = PawnToDestroy;
}

simulated function DestroyPawnsForRespawn()
{
    local int i;

 	if (Level.GetEngine().EnableDevTools)
 	{
		mplog( self$"---NetTeam::DestroyPawnsForRespawn()." );
		mplog( "...Number to destroy="$PawnsToDestroy.Length );
	}

    for ( i = 0; i < PawnsToDestroy.Length; ++i )
    {
 		if (Level.GetEngine().EnableDevTools)
			mplog( "......destroying: "$PawnsToDestroy[i] );
			
        PawnsToDestroy[i].Destroy();
    }
    PawnsToDestroy.Remove( 0, PawnsToDestroy.Length );
}

simulated function string ColorizeName(string Name)
{
	return "[c=" $ ColorTag $ "]" $ Name $ "[\\c]";
}

defaultproperties
{
    respawnSecondsRemaining = 0;
	ColorTag="ffffff"
}
