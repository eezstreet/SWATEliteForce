class MapChangeReferendum extends Voting.Referendum;

import enum EMPMode from Engine.Repo;

var() config localized string ReferendumDescriptionText;
var bool bSwitchingMaps;

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, CallerPRI.PlayerName, TargetStr);
}

function ReferendumDecided(bool YesVotesWin)
{
	if (YesVotesWin)
	{
		mplog("The map change referendum was successful. Changing map to " $ TargetStr);

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
	ServerSettings(Level.CurrentServerSettings).MapChangingByVote(EMPMode.MPM_COOP);

	// Travel to the new map
	SwatRepo(Level.GetRepo()).NetSwitchLevelsFromMapVote(TargetStr);
}

defaultproperties
{
	ReferendumDescriptionText="%1 has started a vote to change the map to %2"
}
