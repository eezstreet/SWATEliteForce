class SwatReferendumManager extends Voting.ReferendumManager;

import enum EMPMode from Engine.Repo;

var private LeaderReferendum LeaderReferendumType;
var private MapChangeReferendum MapChangeReferendumType;

// Start a referendum to promote a player to leader
function bool StartLeaderReferendum(PlayerReplicationInfo PRI, PlayerController LeaderTarget)
{
	if (LeaderReferendumType == None)
		LeaderReferendumType = Spawn(class'LeaderReferendum');

	LeaderReferendumType.Initialise(PRI, LeaderTarget);

	return StartReferendum(PRI, LeaderReferendumType);
}

// Start a referendum to change the map
function bool StartMapChangeReferendum(PlayerReplicationInfo PRI, String MapName, EMPMode GameType)
{
	if (MapChangeReferendumType == None)
		MapChangeReferendumType = Spawn(class'MapChangeReferendum');

	if (MapChangeReferendumType.bSwitchingMaps)
		return false;

	MapChangeReferendumType.Initialise(PRI, MapName, GameType);

	return StartReferendum(PRI, MapChangeReferendumType, true);
}