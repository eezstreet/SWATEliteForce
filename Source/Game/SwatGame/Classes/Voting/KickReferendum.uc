class KickReferendum extends Voting.Referendum;

var() config localized string ReferendumDescriptionText;

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, CallerPRI.PlayerName, TargetPRI.PlayerName);
}

function ReferendumDecided(bool YesVotesWin)
{
	if (TargetPC == None)
		return;

	if (YesVotesWin)
	{
		mplog("The kick referendum was successful. Kicking " $ TargetPRI.PlayerName);
		Level.Game.BroadcastTeam(TargetPC, "", 'ReferendumSucceeded');
		Level.Game.VotedToBeKicked(TargetPC);
	}
	else
	{
		mplog("The kick referendum was unsuccessful. " $ TargetPRI.PlayerName $ " will not be kicked");
		Level.Game.BroadcastTeam(TargetPC, "", 'ReferendumFailed');
	}
}

function bool ReferendumCanBeCalledOnTarget(PlayerController Caller, PlayerController Target)
{
	if(Target == Level.GetLocalPlayerController() || Level.Game.IsA('SwatGameInfo') && SwatGameInfo(Level.Game).Admin.IsAdmin(Target))
	{
		Level.Game.Broadcast(None, "", 'ReferendumAgainstAdmin', Caller);
		return false;
	}
	return true;
}

defaultproperties
{
	ReferendumDescriptionText="%1 started a vote to kick %2"
}
