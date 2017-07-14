class NextMapReferendum extends Voting.Referendum;

var() config localized string ReferendumDescriptionText;
var private bool bSwitchingMaps;

function ReferendumDecided(bool YesVotesWin)
{
  if (YesVotesWin)
	{
		mplog("The nextmap referendum was successful.");
		Level.Game.Broadcast(None, "", 'ReferendumSucceeded');

    bSwitchingMaps = true;

    SetTimer(3.0, false);
	}
	else
	{
		mplog("The nextmap referendum failed");
		Level.Game.Broadcast(None, "", 'ReferendumFailed');
	}
}

function Timer()
{
	bSwitchingMaps = false;

	// Travel to the new map
	SwatRepo(Level.GetRepo()).NetSwitchLevels(true);
}

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, CallerPRI.PlayerName);
}

defaultproperties
{
  ReferendumDescriptionText="%1 started a vote to go to the next map."
}
