class KickReferendum extends Voting.Referendum dependsOn(SwatAdmin);

import enum AdminPermissions from SwatAdmin;

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
		Level.Game.Broadcast(None, "", 'ReferendumSucceeded');
		Level.Game.VotedToBeKicked(TargetPC);
	}
	else
	{
		mplog("The kick referendum was unsuccessful. " $ TargetPRI.PlayerName $ " will not be kicked");
		Level.Game.Broadcast(None, "", 'ReferendumFailed');
	}
}

function bool ReferendumCanBeCalledOnTarget(PlayerController Caller, PlayerController Target)
{
	if(Target == Level.GetLocalPlayerController() || Level.Game.IsA('SwatGameInfo') &&
		SwatGameInfo(Level.Game).Admin.ActionAllowed(Target, AdminPermissions.Permission_Immunity))
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
