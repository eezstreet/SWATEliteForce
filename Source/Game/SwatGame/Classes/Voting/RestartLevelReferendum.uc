class RestartLevelReferendum extends Voting.Referendum;

var() config localized string ReferendumDescriptionText;

// The chat text that is displayed
simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, CallerPRI.PlayerName);
}

// What happens when the vote has been completed
function ReferendumDecided(bool YesVotesWin)
{
  if(YesVotesWin)
  {
    mplog("The map restart referendum was successful. The current map will be restarted.");
    Level.Game.Broadcast(None, "", 'ReferendumSucceeded');
    SetTimer(3.0, false); // Perform the timer action after 3 seconds
  }
  else
  {
    mplog("The map restart referendum was unsuccessful. The current map will not be restarted");
    Level.Game.Broadcast(None, "", 'ReferendumFailed');
  }
}

// We set a timer because we don't want the map restart to happen instantaneously.
// For some actions (such as kicking) we don't care and can do it immediately.
function Timer()
{
  SwatRepo(Level.GetRepo()).NetRestartRound();
}

defaultproperties
{
  ReferendumDescriptionText="%1 has started a vote to restart the current level."
}
