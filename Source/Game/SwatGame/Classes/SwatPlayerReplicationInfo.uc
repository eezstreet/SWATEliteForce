///////////////////////////////////////////////////////////////////////////////

// Our custom PlayerReplicationInfo. This class is used to house variables and
// functions that, in a network game, clients may need to have access to when
// the owning player isn't relevant (being replicated to, nor existant on,
// that client).

class SwatPlayerReplicationInfo extends Engine.PlayerReplicationInfo;


enum COOPStatus
{
    STATUS_NotReady,
    STATUS_Ready,
    STATUS_Healthy,
    STATUS_Injured,
    STATUS_Incapacitated,
};

///////////////////////////////////////////////////////////////////////////////

var NetScoreInfo netScoreInfo;
var private bool PlayerIsReady;
var bool bIsTheVIP;
var int SwatPlayerID; // the unique ID for each player

//respawn time remaining for this player
var int RespawnTime;
var bool bIsDead;

var private bool bIsAdmin;

var COOPStatus COOPPlayerStatus;

// true if we're the leader of an element
var bool IsLeader;

// set to true once the server has sent a stats auth request to the client
var bool bStatsRequestSent;
var bool bStatsNewPlayer;

///////////////////////////////////////////////////////////////////////////////

replication
{
    reliable if (bNetDirty && (Role == ROLE_Authority))
        netScoreInfo, PlayerIsReady, bIsTheVIP, SwatPlayerID, RespawnTime, COOPPlayerStatus, bIsAdmin, bIsDead, IsLeader;
}


///////////////////////////////////////////////////////////////////////////////

function SetAdmin( bool bAdmin )
{
    bIsAdmin = bAdmin;
}

simulated function bool IsAdmin()
{
    return bIsAdmin;
}

// Execute only on server.
function TogglePlayerIsReady()
{
    assert( Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer );
    PlayerIsReady = !PlayerIsReady;
}


simulated function bool GetPlayerIsReady()
{
    return PlayerIsReady;
}


// Execute only on server.
function ResetPlayerIsReady()
{
    PlayerIsReady = false;
}

function OnMissionEnded()
{
    RespawnTime = 0;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    PlayerIsReady=false
    bIsTheVIP=false
    bIsAdmin=false
}
