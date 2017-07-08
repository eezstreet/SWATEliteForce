class KickReferendum extends Engine.Actor implements IReferendum;

var() config localized string ReferendumDescriptionText;
var private PlayerController KickTarget;
var private PlayerReplicationInfo KickerPRI;
var private PlayerReplicationInfo KickTargetPRI;

replication
{
	reliable if (bNetDirty && (Role == ROLE_Authority))
		KickerPRI, KickTargetPRI;
}

function Initialise(PlayerReplicationInfo InitKickerPRI, PlayerController Kickee)
{
	KickTarget = Kickee;
	KickerPRI = InitKickerPRI;
	KickTargetPRI = KickTarget.PlayerReplicationInfo;
}

simulated function String ReferendumDescription()
{
	return FormatTextString(ReferendumDescriptionText, KickerPRI.PlayerName, KickTargetPRI.PlayerName);
}

function ReferendumDecided(bool YesVotesWin)
{
	if (KickTarget == None)
		return;

	if (YesVotesWin)
	{
		mplog("The kick referendum was successful. Kicking " $ KickTargetPRI.PlayerName);
		Level.Game.BroadcastTeam(KickTarget, "", 'ReferendumSucceeded');
		Level.Game.VotedToBeKicked(KickTarget);
	}
	else
	{
		mplog("The kick referendum was unsuccessful. " $ KickTargetPRI.PlayerName $ " will not be kicked");
		Level.Game.BroadcastTeam(KickTarget, "", 'ReferendumFailed');
	}
}

defaultproperties
{
	ReferendumDescriptionText="%1 started a vote to kick %2"

	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bOnlyDirtyReplication=true
	bSkipActorPropertyReplication=true

	bHidden=true
}