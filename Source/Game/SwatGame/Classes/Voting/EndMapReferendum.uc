class EndMapReferendum extends Voting.Referendum;

var() config localized string ReferendumDescriptionText;
var private bool bEndingMap;

function ReferendumDecided(bool YesVotesWin)
{
  if (YesVotesWin)
	{
		mplog("The endmap referendum was successful.");
		Level.Game.BroadcastTeam(None, "", 'ReferendumSucceeded');

    bEndingMap = true;

    SetTimer(3.0, false);
	}
	else
	{
		mplog("The endmap referendum failed");
		Level.Game.BroadcastTeam(None, "", 'ReferendumFailed');
	}
}

function Timer()
{
	bEndingMap = false;

	// End the current mission
	SwatGameInfo(Level.Game).GameAbort();
}

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, CallerPRI.PlayerName);
}

defaultproperties
{
  ReferendumDescriptionText="%1 started a vote to end the current map."
}
