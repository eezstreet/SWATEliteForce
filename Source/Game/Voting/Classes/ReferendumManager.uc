class ReferendumManager extends Engine.Actor;

var private TeamInfo ReferendumTeam;				// The team of the player that started the referendum

var private int YesVotes;							// The current tally of yes votes
var private int NoVotes;							// The current tally of no votes
	
var private array<int> Voters;						// A list of PlayerIds that have submitted a vote
	
var private globalconfig float ReferendumDuration;	// How long the referendum will allow votes to be cast
var private float TimeRemaining;					// How much time remains before the referendum expires

struct CooldownTimer
{
	var int PlayerId;
	var float TimeRemaining;
};

// Each PlayerId can only start a referendum every StartReferendumCooldown seconds
var private float StartReferendumCooldown;

// VoterCooldownTimers tracks the amount of time each previous referendum starter has before they may start another referendum
// If a PlayerId is in this array they may not start a referendum
var private array<CooldownTimer> VoterCooldownTimers;

// Each PlayerId can only have a referendum started against them every ReferendumImmunityCooldown seconds
var private float ReferendumImmunityCooldown;

// ImmunityCooldownTimers tracks the amount of time each previous referendum target has before they may have a referendum targetted at them again
// If a PlayerId is in this array they may not be the target of a referendum
var private array<CooldownTimer> ImmunityCooldownTimers;

// Objects that define what actually happens once a specific type of referendum is decided
var private IReferendum CurrentReferendumType;
var private KickReferendum KickReferendumType;
var private BanReferendum BanReferendumType;

replication
{
	reliable if (bNetDirty && (Role == ROLE_Authority))
		ReferendumTeam, YesVotes, NoVotes, TimeRemaining, CurrentReferendumType;
}

simulated function TeamInfo GetTeam()
{
	return ReferendumTeam;
}

simulated function int GetNumberOfYesVotes()
{
	return YesVotes;
}

simulated function int GetNumberOfNoVotes()
{
	return NoVotes;
}

simulated function float GetTimeRemaining()
{
	return TimeRemaining;
}

// Returns true if a referendum is currently active
simulated function bool ReferendumActive()
{
	return TimeRemaining > 0.0;
}

simulated function String GetReferendumDescription()
{
	if (CurrentReferendumType != None)
		return CurrentReferendumType.ReferendumDescription();
	else
		return "";
}

function AddVoterToCooldownList(int PlayerId)
{
	VoterCooldownTimers.Length = VoterCooldownTimers.Length + 1;
	VoterCooldownTimers[VoterCooldownTimers.Length - 1].PlayerId = PlayerId;
	VoterCooldownTimers[VoterCooldownTimers.Length - 1].TimeRemaining = StartReferendumCooldown;
}

function Tick(float Delta)
{
	local int MaxVoters;

	if (Level.NetMode == NM_Client)
		return;

	UpdateCooldownTimers(Delta);

	// Dont continue if the referendum is not active
	if (!ReferendumActive())
		return;

	// Reduce the time remaining
	TimeRemaining -= Delta;

	MaxVoters = MaxPossibleVoters();

	// If the referendum has now expired or enough people have voted to decide the referendum, end the referendum
	if (!ReferendumActive() || (YesVotes > (MaxVoters - YesVotes)) || (NoVotes >= (MaxVoters - NoVotes)))
		EndReferendum();
}

private function UpdateCooldownTimers(float Delta)
{
	local int i;

	// Decreament each voter cooldown timer
	for (i = 0; i < VoterCooldownTimers.Length; ++i)
		VoterCooldownTimers[i].TimeRemaining -= Delta;

	// Remove any voters who's cooldowns have expired
	while (VoterCooldownTimers.Length > 0 && VoterCooldownTimers[0].TimeRemaining <= 0.0)
		VoterCooldownTimers.Remove(0, 1);

	// Decreament each immunity cooldown timer
	for (i = 0; i < ImmunityCooldownTimers.Length; ++i)
		ImmunityCooldownTimers[i].TimeRemaining -= Delta;

	// Remove any immune players who's cooldowns have expired
	while (ImmunityCooldownTimers.Length > 0 && ImmunityCooldownTimers[0].TimeRemaining <= 0.0)
		ImmunityCooldownTimers.Remove(0, 1);
}

// Returns false if the referendum could not be started
protected function bool StartReferendum(PlayerReplicationInfo PRI, IReferendum ReferendumType, optional bool bDontUseTeam)
{
	// Only one referendum can be active at any one time
	if (ReferendumActive())
	{
		//mplog("The referendum has failed to start because a referendum is already in progress");
		assert(PlayerController(PRI.Owner) != None);
		Level.Game.Broadcast(None, "", 'ReferendumAlreadyActive', PlayerController(PRI.Owner));
		return false;
	}

	// Check if this PlayerId is allowed to start a referendum
	if (!CanStartReferendum(PRI.PlayerId))
	{
		//mplog("The referendum has failed to start because the cooldown for player " $ PRI.PlayerName $ " has not yet expired");
		assert(PlayerController(PRI.Owner) != None);
		Level.Game.Broadcast(None, "", 'ReferendumStartCooldown', PlayerController(PRI.Owner));
		return false;
	}

	// Start a cooldown for PlayerId to start another referendum
	AddVoterToCooldownList(PRI.PlayerId);

	if (bDontUseTeam)
		ReferendumTeam = None;
	else
		ReferendumTeam = PRI.Team;

	// No one has voted yet
	Voters.Length = 0;
	YesVotes = 0;
	NoVotes = 0;

	TimeRemaining = ReferendumDuration;
	CurrentReferendumType = ReferendumType;

	return true;
}

// Start a referendum to kick a player from the server
function bool StartKickReferendum(PlayerReplicationInfo PRI, PlayerController KickTarget)
{
	// A player is immune from referendums if they've recently "survived" a referendum against them
	if (ImmuneFromReferendums(KickTarget.PlayerReplicationInfo.PlayerId))
	{
		//mplog("Player " $ KickTarget.PlayerReplicationInfo.PlayerName $ " is currently immune from referendums");
		assert(PlayerController(PRI.Owner) != None);
		Level.Game.Broadcast(None, KickTarget.PlayerReplicationInfo.PlayerName, 'PlayerImmuneFromReferendum', PlayerController(PRI.Owner));
		return false;
	}

	if (KickReferendumType == None)
		KickReferendumType = Spawn(class'KickReferendum');

	KickReferendumType.Initialise(PRI, KickTarget);

	if (StartReferendum(PRI, KickReferendumType, Level.IsCoopServer))
	{
		// Start a cooldown for KickTarget's Id to be immune from referendums
		ImmunityCooldownTimers.Length = ImmunityCooldownTimers.Length + 1;
		ImmunityCooldownTimers[ImmunityCooldownTimers.Length - 1].PlayerId = KickTarget.PlayerReplicationInfo.PlayerId;
		ImmunityCooldownTimers[ImmunityCooldownTimers.Length - 1].TimeRemaining = ReferendumImmunityCooldown;

		return true;
	}

	return false;
}

// Start a referendum to ban a player from the server
function bool StartBanReferendum(PlayerReplicationInfo PRI, PlayerController BanTarget)
{
	// A player is immune from referendums if they've recently "survived" a referendum against them
	if (ImmuneFromReferendums(BanTarget.PlayerReplicationInfo.PlayerId))
	{
		//mplog("Player " $ BanTarget.PlayerReplicationInfo.PlayerId $ " is currently immune from referendums");
		assert(PlayerController(PRI.Owner) != None);
		Level.Game.Broadcast(None, BanTarget.PlayerReplicationInfo.PlayerName, 'PlayerImmuneFromReferendum', PlayerController(PRI.Owner));
		return false;
	}

	if (BanReferendumType == None)
		BanReferendumType = Spawn(class'BanReferendum');

	BanReferendumType.Initialise(PRI, BanTarget);

	if (StartReferendum(PRI, BanReferendumType, Level.IsCoopServer))
	{
		// Start a cooldown for BanTarget's Id to be immune from referendums
		ImmunityCooldownTimers.Length = ImmunityCooldownTimers.Length + 1;
		ImmunityCooldownTimers[ImmunityCooldownTimers.Length - 1].PlayerId = BanTarget.PlayerReplicationInfo.PlayerId;
		ImmunityCooldownTimers[ImmunityCooldownTimers.Length - 1].TimeRemaining = ReferendumImmunityCooldown;

		return true;
	}

	return false;
}

function bool SubmitYesVote(int PlayerId, TeamInfo Team)
{
	// Can't vote if a referendum is not active
	if (!ReferendumActive())
	{
		mplog("Player " $ PlayerId $ " tried to vote yes, but there was no active referendum");
		return false;
	}

	// If this referendum is team only and the voter is not on the right team disallow the vote
	if (ReferendumTeam != None && ReferendumTeam != Team)
	{
		mplog("Player " $ PlayerId $ " tried to vote yes but was on the wrong team for the current referendum");
		return false;
	}

	// A player my only vote once per referendum
	if (PlayerHasAlreadyVoted(PlayerId))
	{
		mplog("Player " $ PlayerId $ " tried to vote yes, but has already voted");
		return false;
	}

	Voters[Voters.Length] = PlayerId;

	++YesVotes;

	return true;
}

function bool SubmitNoVote(int PlayerId, TeamInfo Team)
{
	// Can't vote if a referendum is not active
	if (!ReferendumActive())
	{
		mplog("Player " $ PlayerId $ " tried to vote no, but there was no active referendum");
		return false;
	}

	// If this referendum is team only and the voter is not on the right team disallow the vote
	if (ReferendumTeam != None && ReferendumTeam != Team)
	{
		mplog("Player " $ PlayerId $ " tried to vote no but was on the wrong team for the current referendum");
		return false;
	}

	// A player my only vote once per referendum
	if (PlayerHasAlreadyVoted(PlayerId))
	{
		mplog("Player " $ PlayerId $ " tried to vote no, but has already voted");
		return false;
	}

	Voters[Voters.Length] = PlayerId;

	++NoVotes;

	return true;
}

// Returns true if the Yes voters have won the referendum
private function bool YesVotesWin()
{
	return Voters.Length > 1 && YesVotes > (MaxPossibleVoters() - YesVotes);
}

private function EndReferendum()
{
	TimeRemaining = 0.0;
	ReferendumDecided();
}

private function ReferendumDecided()
{
	CurrentReferendumType.ReferendumDecided(YesVotesWin());
	CurrentReferendumType = None;
}

// Returns true if a vote has already been submitted by PlayerId
private function bool PlayerHasAlreadyVoted(int PlayerId)
{
	local int i;

	for (i = 0; i < Voters.Length; ++i)
		if (Voters[i] == PlayerId)
			return true;

	return false;
}

// Returns true if a referendum can be started by PlayerId
private function bool CanStartReferendum(int PlayerId)
{
	local int i;

	for (i = 0; i < VoterCooldownTimers.Length; ++i)
		if (VoterCooldownTimers[i].PlayerId == PlayerId)
			return false;

	return true;
}

// Returns true if PlayerId is immune from referendums
private function bool ImmuneFromReferendums(int PlayerId)
{
	local int i;

	for (i = 0; i < ImmunityCooldownTimers.Length; ++i)
		if (ImmunityCooldownTimers[i].PlayerId == PlayerId)
			return true;

	return false;
}

private function int MaxPossibleVoters()
{
	local int NumTeamMembers;
	local Controller Iter;

	if (ReferendumTeam == None)
		return Level.Game.NumPlayers;

	for (Iter = Level.ControllerList; Iter != None; Iter = Iter.NextController)
	{
		if (Iter.IsA('PlayerController'))
		{
			if (PlayerController(Iter).PlayerReplicationInfo != None && PlayerController(Iter).PlayerReplicationInfo.Team == ReferendumTeam)
				++NumTeamMembers;
		}
	}

	return NumTeamMembers;
}

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bOnlyDirtyReplication=true
	bSkipActorPropertyReplication=true

	bHidden=true

	ReferendumDuration=15.0
	StartReferendumCooldown=30.0
	ReferendumImmunityCooldown=60.0
}