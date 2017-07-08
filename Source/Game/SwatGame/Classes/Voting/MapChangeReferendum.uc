class MapChangeReferendum extends Engine.Actor implements Voting.IReferendum;

import enum EMPMode from Engine.Repo;

var() config localized string ReferendumDescriptionText;
var private PlayerReplicationInfo ReferendumInstigatorPRI;
var private String NewMapName;
var private EMPMode NewGameType;
var bool bSwitchingMaps;

replication
{
	reliable if (bNetDirty && (Role == ROLE_Authority))
		ReferendumInstigatorPRI, NewMapName, NewGameType;
}

function Initialise(PlayerReplicationInfo InitReferendumInstigatorPRI, String MapName, EMPMode GameType)
{
	ReferendumInstigatorPRI = InitReferendumInstigatorPRI;
	NewMapName = MapName;
	NewGameType = GameType;
}

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, ReferendumInstigatorPRI.PlayerName, NewMapName,
		SwatRepo(Level.GetRepo()).GuiConfig.GetGameModeName(NewGameType));
}

function ReferendumDecided(bool YesVotesWin)
{
	if (YesVotesWin)
	{
		mplog("The map change referendum was successful. Changing map to " $ NewMapName);

		Level.Game.Broadcast(None, "", 'ReferendumSucceeded');

		bSwitchingMaps = true;

		SetTimer(3.0, false);
	}
	else
	{
		mplog("The map change referendum was unsuccessful. The current map will not be changed");
		Level.Game.Broadcast(None, "", 'ReferendumFailed');
	}
}

function Timer()
{
	bSwitchingMaps = false;

	// Modify the server settings for the new game type
	ServerSettings(Level.CurrentServerSettings).MapChangingByVote(NewGameType);

	// Travel to the new map
	SwatRepo(Level.GetRepo()).NetSwitchLevelsFromMapVote(NewMapName);
}

defaultproperties
{
	ReferendumDescriptionText="%1 has started a vote to change the map to %2, %3"

	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bOnlyDirtyReplication=true
	bSkipActorPropertyReplication=true

	bHidden=true
}