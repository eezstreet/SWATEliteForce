class StartMapReferendum extends Voting.Referendum;

var() config localized string ReferendumDescriptionText;

function ReferendumDecided(bool YesVotesWin)
{
  if (YesVotesWin)
	{
		mplog("The startmap referendum was successful.");
		Level.Game.Broadcast(None, "", 'ReferendumSucceeded');

    	SetTimer(3.0, false);
	}
	else
	{
		mplog("The startmap referendum failed");
		Level.Game.Broadcast(None, "", 'ReferendumFailed');
	}
}

function Timer()
{
	// Start the mission!
	SwatRepo(Level.GetRepo()).AllPlayersReady();
}

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, CallerPRI.PlayerName);
}

defaultproperties
{
  ReferendumDescriptionText="%1 started a vote to start the mission."
}
