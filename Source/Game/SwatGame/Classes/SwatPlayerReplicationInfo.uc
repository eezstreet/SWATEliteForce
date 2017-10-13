///////////////////////////////////////////////////////////////////////////////

// Our custom PlayerReplicationInfo. This class is used to house variables and
// functions that, in a network game, clients may need to have access to when
// the owning player isn't relevant (being replicated to, nor existant on,
// that client).

class SwatPlayerReplicationInfo extends Engine.PlayerReplicationInfo
	dependsOn(SwatAdmin);

import enum AdminPermissions from SwatAdmin;

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

var int MyRights[AdminPermissions.Permission_Max];
var private SwatAdminPermissions MyPermissions;
var bool bIsAdmin;

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
        netScoreInfo, PlayerIsReady, bIsTheVIP, SwatPlayerID, RespawnTime, COOPPlayerStatus, bIsDead, IsLeader, MyRights;
}


///////////////////////////////////////////////////////////////////////////////

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

simulated function SetPermissions(SwatAdminPermissions Permissions)
{
	local int i;

	MyPermissions = Permissions;
	for(i = 0; i < AdminPermissions.Permission_Max; i++)
	{
		MyRights[i] = MyPermissions.AllowedPermissions[i];
		log("SetPermissions: "$MyRights[i]);
	}
}

// DO NOT call this on the client, MyPermissions is NOT replicated
simulated function SwatAdminPermissions GetPermissions()
{
	return MyPermissions;
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
