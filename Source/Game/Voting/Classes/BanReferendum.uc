class BanReferendum extends Engine.Actor implements IReferendum;

var() config localized string ReferendumDescriptionText;
var private PlayerController BanTarget;
var private PlayerReplicationInfo BannerPRI;
var private PlayerReplicationInfo BanTargetPRI;

replication
{
	reliable if (bNetDirty && (Role == ROLE_Authority))
		BannerPRI, BanTargetPRI;
}

function Initialise(PlayerReplicationInfo InitBannerPRI, PlayerController Banee)
{
	BanTarget = Banee;
	BannerPRI = InitBannerPRI;
	BanTargetPRI = BanTarget.PlayerReplicationInfo;
}

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, BannerPRI.PlayerName, BanTargetPRI.PlayerName);
}

function ReferendumDecided(bool YesVotesWin)
{
	if (BanTarget == None)
		return;

	if (YesVotesWin)
	{
		mplog("The ban referendum was successful. Banning " $ BanTargetPRI.PlayerName);
		Level.Game.BroadcastTeam(BanTarget, "", 'ReferendumSucceeded');
		Level.Game.VotedToBeBanned(BanTarget);
	}
	else
	{
		mplog("The ban referendum was unsuccessful. " $ BanTargetPRI.PlayerName $ " will not be banned");
		Level.Game.BroadcastTeam(BanTarget, "", 'ReferendumFailed');
	}
}

defaultproperties
{
	ReferendumDescriptionText="%1 has started a vote to ban %2"

	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bOnlyDirtyReplication=true
	bSkipActorPropertyReplication=true

	bHidden=true
}