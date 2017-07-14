class LeaderReferendum extends Voting.Referendum;

var() config localized string ReferendumDescriptionText;

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, CallerPRI.PlayerName, TargetPRI.PlayerName);
}

function ReferendumDecided(bool YesVotesWin)
{
	local GameModeCOOP GMC;

	if (TargetPC == None)
		return;

	if (YesVotesWin)
	{
		GMC = GameModeCOOP(SwatGameInfo(Level.Game).GetGameMode());

		if (GMC != None)
		{
			mplog("The leader referendum was successful. Promoting " $ TargetPRI.PlayerName $ " to leader");
			Level.Game.Broadcast(None, "", 'ReferendumSucceeded');
			GMC.SetLeader(NetTeam(TargetPC.PlayerReplicationInfo.Team), SwatGamePlayerController(TargetPC));
		}
	}
	else
	{
		mplog("The leader referendum was unsuccessful. " $ TargetPRI.PlayerName $ " will not be promoted to leader");
		Level.Game.Broadcast(None, "", 'ReferendumFailed');
	}
}

function bool ReferendumCanBeCalledOnTarget(PlayerController Caller, PlayerController Target)
{
	if(Caller.PlayerReplicationInfo.Team != Target.PlayerReplicationInfo.Team)
	{
		Level.Game.Broadcast(None, "", 'LeaderVoteTeamMismatch', Caller);
		return false;
	}
	return true;
}

defaultproperties
{
	ReferendumDescriptionText="%1 has started a vote to promote %2 to leader"
	bNoImmunity=true
	bUseTeam=true
}
