class LeaderReferendum extends Engine.Actor implements Voting.IReferendum;

var() config localized string ReferendumDescriptionText;
var private PlayerController LeaderTarget;
var private PlayerReplicationInfo NominatorPRI;
var private PlayerReplicationInfo LeaderTargetPRI;

replication
{
	reliable if (bNetDirty && (Role == ROLE_Authority))
		NominatorPRI, LeaderTargetPRI;
}

function Initialise(PlayerReplicationInfo InitNominatorPRI, PlayerController LeaderCandidate)
{
	LeaderTarget = LeaderCandidate;
	NominatorPRI = InitNominatorPRI;
	LeaderTargetPRI = LeaderTarget.PlayerReplicationInfo;
}

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, NominatorPRI.PlayerName, LeaderTargetPRI.PlayerName);
}

function ReferendumDecided(bool YesVotesWin)
{
	local GameModeCOOP GMC;

	if (LeaderTarget == None)
		return;

	if (YesVotesWin)
	{	
		GMC = GameModeCOOP(SwatGameInfo(Level.Game).GetGameMode());

		if (GMC != None)
		{
			mplog("The leader referendum was successful. Promoting " $ LeaderTargetPRI.PlayerName $ " to leader");
			Level.Game.BroadcastTeam(LeaderTarget, "", 'ReferendumSucceeded');
			GMC.SetLeader(NetTeam(LeaderTarget.PlayerReplicationInfo.Team), SwatGamePlayerController(LeaderTarget));
		}
	}
	else
	{
		mplog("The leader referendum was unsuccessful. " $ LeaderTargetPRI.PlayerName $ " will not be promoted to leader");
		Level.Game.BroadcastTeam(LeaderTarget, "", 'ReferendumFailed');
	}
}

defaultproperties
{
	ReferendumDescriptionText="%1 has started a vote to promote %2 to leader"

	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bOnlyDirtyReplication=true
	bSkipActorPropertyReplication=true

	bHidden=true
}