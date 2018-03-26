class SwatAdmin extends Engine.Actor
    config(SwatGuiState);

import enum Pocket from Engine.HandheldEquipment;

enum WebAdminMessageType
{
	MessageType_Chat,
	MessageType_PlayerJoin,
	MessageType_AdminJoin,
	MessageType_AdminLeave,
	MessageType_Penalty,
	MessageType_SwitchTeams,
	MessageType_NameChange,
	MessageType_Voting,
	MessageType_Kill,
	MessageType_TeamKill,
	MessageType_Arrest,
	MessageType_Round,
	MessageType_WebAdminError,
};

enum AdminPermissions
{
	Permission_Kick,			// Allowed to kick people?
	Permission_KickBan,			// Allowed to kick-ban people?
	Permission_Switch,			// Allowed to switch maps?
	Permission_StartGame,		// Allowed to start game prematurely
	Permission_EndGame,			// Allowed to end game prematurely
	Permission_ChangeSettings,	// Allowed to change server settings
	Permission_Immunity,		// Immune to kick, ban, etc votes
	Permission_WebAdminChat,	// Allowed to chat while in WebAdmin
	Permission_LockTeams,		// Allowed to lock the teams
	Permission_LockPlayerTeams,	// Allowed to lock a player's team
	Permission_ForceAllTeams,	// Allowed to force all players to one team
	Permission_ForcePlayerTeam,	// Allowed to force a player to a particular team
	Permission_Mute,			// Allowed to mute players
	Permission_KillPlayers,		// Allowed to kill players
	Permission_PromoteLeader,	// Allowed to promote players to leader
	Permission_GoToSpec,		// Allowed to go to spectator
	Permission_ForceSpectator,	// Allowed to force other players to go to spectator
	Permission_ForceLessLethal,	// Allowed to force other players to use a less lethal loadout
	Permission_ViewIPs,			// Allowed to see IPs in WebAdmin
	Permission_LockVoting,		// Allowed to prevent votes from taking place
	Permission_LockVoter,		// Allowed to prevent someone from calling or casting votes
	Permission_Max,
};

struct AutoAction
{
	var float Delay;
	var string ExecuteText;
};

var public SwatAdminPermissions GuestPermissions;			// Guest permissions are given to every player, even ones that aren't signed in
var public array<SwatAdminPermissions> Permissions;			// These require someone to sign in
var public config name GuestPermissionName;
var public config array<name> PermissionNames;
var public config class<SwatAdminPermissions> PermissionClass;
var public config array<AutoAction> AutoActions;
var private int AutoActionNum;

var public config bool UseWebAdmin;
var public config int WebAdminPort;
var public config class<SwatWebAdminListener> WebAdminClass;
var private SwatWebAdminListener WebAdmin;

var public config bool UseChatLog;
var private FileLog ChatLog;
var public config bool SanitizeChatLog;
var public config bool UseNewChatLogPerDay;
var public config string ChatLogMultiFormat;
var public config string ChatLogName;

var public config array<string> MapDisabledLocalizedChat;	// These maps have disabled localized chat, due to bugs, etc
var public config bool GlobalDisableLocalizedChat;

var public config string LessLethalLoadoutName;	// When forcing a player to a less lethal loadout, this is the name of the loadout
var private config string VerifyDeveloperString;

var private localized config string PenaltyFormat;
var private localized config string PenaltyIPFormat;
var private localized config string SayFormat;
var private localized config string SayLocalizedFormat;
var private localized config string TeamSayFormat;
var private localized config string TeamSayLocalizedFormat;
var private localized config string SayIPFormat;
var private localized config string SayLocalizedIPFormat;
var private localized config string TeamSayIPFormat;
var private localized config string TeamSayLocalizedIPFormat;
var private localized config string SwitchTeamsFormat;
var private localized config string NameChangeFormat;
var private localized config string SwitchTeamsIPFormat;
var private localized config string NameChangeIPFormat;
var private localized config string VoteStartedFormat;
var private localized config string YesVoteFormat;
var private localized config string NoVoteFormat;
var private localized config string YesVoteIPFormat;
var private localized config string NoVoteIPFormat;
var private localized config string VoteSuccessfulFormat;
var private localized config string VoteFailedFormat;
var private localized config string RedSuicideFormat;
var private localized config string BlueSuicideFormat;
var private localized config string RedKillFormat;
var private localized config string BlueKillFormat;
var private localized config string TeamKillFormat;
var private localized config string RedArrestFormat;
var private localized config string BlueArrestFormat;
var private localized config string RedIncapacitateFormat;
var private localized config string BlueIncapacitateFormat;
var private localized config string FallenFormat;
var private localized config string RedSuicideIPFormat;
var private localized config string BlueSuicideIPFormat;
var private localized config string RedKillIPFormat;
var private localized config string BlueKillIPFormat;
var private localized config string TeamKillIPFormat;
var private localized config string RedArrestIPFormat;
var private localized config string BlueArrestIPFormat;
var private localized config string RedIncapacitateIPFormat;
var private localized config string BlueIncapacitateIPFormat;
var private localized config string FallenIPFormat;
var private localized config string ConnectFormat;
var private localized config string DisconnectFormat;
var private localized config string ConnectIPFormat;
var private localized config string DisconnectIPFormat;
var private localized config string KickFormat;
var private localized config string KickBanFormat;
var private localized config string KickIPFormat;
var private localized config string KickBanIPFormat;
var private localized config string ObjectiveCompleteFormat;
var private localized config string LockedTeamsFormat;
var private localized config string UnlockedTeamsFormat;
var private localized config string LockedPlayerTeamFormat;
var private localized config string UnlockedPlayerTeamFormat;
var private localized config string ForceAllRedFormat;
var private localized config string ForceAllBlueFormat;
var private localized config string ForcePlayerRedFormat;
var private localized config string ForcePlayerBlueFormat;
var private localized config string MuteFormat;
var private localized config string UnmuteFormat;
var private localized config string AdminKillFormat;
var private localized config string AdminPromotedFormat;
var private localized config string LockedTeamsIPFormat;
var private localized config string UnlockedTeamsIPFormat;
var private localized config string LockedPlayerTeamIPFormat;
var private localized config string UnlockedPlayerTeamIPFormat;
var private localized config string ForceAllRedIPFormat;
var private localized config string ForceAllBlueIPFormat;
var private localized config string ForcePlayerRedIPFormat;
var private localized config string ForcePlayerBlueIPFormat;
var private localized config string MuteIPFormat;
var private localized config string UnmuteIPFormat;
var private localized config string AdminKillIPFormat;
var private localized config string AdminPromotedIPFormat;
var private localized config string RoundStartedFormat;
var private localized config string RoundEndedFormat;
var private localized config string MissionEndedFormat;
var private localized config string MissionCompletedFormat;
var private localized config string MissionFailedFormat;
var private localized config string LeftWebAdminFormat;
var private localized config string SpectateFormat;
var private localized config string ForceSpectateFormat;
var private localized config string ForceLessLethalFormat;
var private localized config string UnforceLessLethalFormat;
var private localized config string LeftWebAdminIPFormat;
var private localized config string SpectateIPFormat;
var private localized config string ForceSpectateIPFormat;
var private localized config string ForceLessLethalIPFormat;
var private localized config string UnforceLessLethalIPFormat;
var private localized config string LockedVotingFormat;
var private localized config string UnlockedVotingFormat;
var private localized config string LockedVoterFormat;
var private localized config string LockedVoterIPFormat;
var private localized config string UnlockedVoterFormat;
var private localized config string UnlockedVoterIPFormat;
var private localized config string VerifiedMessage;
var private localized config string MapChangedMessage;
var private localized config string ReferendumVoteYesFormat;
var private localized config string ReferendumVoteNoFormat;
var private localized config string ReferendumVoteYesIPFormat;
var private localized config string ReferendumVoteNoIPFormat;
var private localized config string ReferendumStartedFormat;
var private localized config string ReferendumStartedIPFormat;
var private localized config string ReferendumFailedFormat;
var private localized config string ReferendumPassedFormat;
var private localized config string CommandIssuedFormat;
var private localized config string CommandIssuedIPFormat;

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

function PreBeginPlay()
{
	if(Level.NetMode == NM_Standalone)
	{
		return;
	}

	// Set up autoactions - events set up to run on a timer by the server
	AutoActionNum = 0;
	if(AutoActions.Length > 0)
	{
		SetTimer(AutoActions[AutoActionNum].Delay, false);
	}
}

function BeginPlay()
{
	if(UseChatLog)
	{
		ChatLog = Spawn(class'FileLog');
	}

	Super.BeginPlay();
}

function PostBeginPlay()
{
	local int i;

	// Spawn the permission sets
	GuestPermissions = Spawn(PermissionClass, self, GuestPermissionName);
	if(GuestPermissions == None)
	{
		log("Couldn't spawn GuestPermissions with name "$GuestPermissionName);
	}
	else
	{
		log("Spawned guest permissions "$GuestPermissions$" with name "$GuestPermissionName);
	}

	for(i = 0; i < PermissionNames.Length; i++)
	{
		Permissions[i] = Spawn(PermissionClass, self, PermissionNames[i]);
	}

	if(UseWebAdmin)
	{
		log("Spawning webadmin");
		WebAdmin = Spawn(WebAdminClass, self);
	}
}

// Clean up some stuff --eez
event Destroyed()
{
	GuestPermissions = None;
	Permissions.Length = 0;

	if(WebAdmin != None)
	{
		WebAdmin.Destroy();
		WebAdmin = None;
	}

	if(ChatLog != None)
	{
		ChatLog.Destroy();
		ChatLog = None;
	}
}

// The timer is used to execute AutoActions which can be used to
event Timer()
{
	if(AutoActions.Length == 0)
	{
		return;
	}

	PerformAutoAction(AutoActions[AutoActionNum].ExecuteText);

	AutoActionNum++;
	if(AutoActionNum >= AutoActions.Length)
	{
		AutoActionNum = 0;
	}

	SetTimer(AutoActions[AutoActionNum].Delay, false);
}

// Strip pseudo-HTML codes out of the string, for better logging
function SanitizeLogMessage(out string Message)
{
	local int i, j;

	ReplaceText(Message, "[B]", "");
	ReplaceText(Message, "[b]", "");
	ReplaceText(Message, "[\\B]", "");
	ReplaceText(Message, "[\\b]", "");
	ReplaceText(Message, "[U]", "");
	ReplaceText(Message, "[u]", "");
	ReplaceText(Message, "[\\U]", "");
	ReplaceText(Message, "[\\u]", "");
	ReplaceText(Message, "[I]", "");
	ReplaceText(Message, "[i]", "");
	ReplaceText(Message, "[\\I]", "");
	ReplaceText(Message, "[\\i]", "");
	ReplaceText(Message, "[\\C]", "");
	ReplaceText(Message, "[\\c]", "");
	ReplaceText(Message, "[C=", "[c=");

	// remove color code start
	do
	{
		i = InStr(Message, "[c=");
		if(i != -1)
		{
			j = InStrAfter(Message, "]", i);
			if(j != -1)
			{
				Message = Left(Message, i) $ Mid(Message, j + 1);
			}
		}
	} until(i == -1);
}

// Return a number that is always formatted to be at least 2 digits long
function string I2(int Number)
{
	if(Number < 10)
	{
		return "0"$Number;
	}
	return ""$Number;
}

// Log something to the chatlog
function LogChat(string Message)
{
	if(UseChatLog)
	{
		if(SanitizeChatLog)
		{
			SanitizeLogMessage(Message);
		}

		if(UseNewChatLogPerDay)
		{
			ChatLog.OpenLog(FormatTextString(ChatLogMultiFormat, Level.Year, Level.Month, Level.Day));
		}
		else
		{
			ChatLog.OpenLog(ChatLogName);
		}
		ChatLog.Logf("["$I2(Level.Day)$"/"$I2(Level.Month)$"/"$Level.Year$" "$I2(Level.Hour)$":"$I2(Level.Minute)$":"$I2(Level.Second)$"] "$Message);
		ChatLog.CloseLog();
	}
}

// Perform auto action text
function PerformAutoAction(String Text)
{
	if(Left(Text, 6) ~= "print ")
	{
		Level.Game.Broadcast(None, Mid(Text, 6), 'Caption');
	}
	else if(Left(Text, 3) ~= "ac ")
	{
		ACCommand(Level.GetLocalPlayerController(), Mid(Text, 3));
	}
}

// Find a role with password
function SwatAdminPermissions FindRole(String Password)
{
	local int i;

	for(i = 0; i < Permissions.Length; i++)
	{
		if(Permissions[i].TryPassword(Password))
		{
			return Permissions[i];
		}
	}

	return None;
}

// Attempt to log in
function bool TryLogin( PlayerController PC, String Password )
{
	local SwatPlayerReplicationInfo PRI;
	local int i;

	PRI = SwatPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if(PRI == None)
	{
		PC.ConsoleMessage("Couldn't login, PRI was None");
		return false; // How does this even happen?
	}

	if((PRI.GetPermissions() != None && PRI.GetPermissions() != GuestPermissions) || PRI.bIsAdmin)
	{
		PC.ConsoleMessage("Couldn't login, already logged in");
		return false;	// Already logged in as non-guest, we can't re-login.
	}

	// Find the permission that matches the password
	for(i = 0; i < Permissions.Length; i++)
	{
		if(Permissions[i].TryPassword(Password))
		{
			PC.ConsoleMessage("Logged in with role "$Permissions[i].PermissionSetName);
			PRI.SetPermissions(Permissions[i]);
			PRI.bIsAdmin = true;
			SwatGamePlayerController(PC).SwatRepoPlayerItem.LastAdminPassword = Password;
			return true;
		}
	}

	// If we got here, none of the admin passwords worked.
	// If we got to this point, it's entirely likely that we got here because we just joined the server and
	// the server tried to log us in automatically with our previously entered password (which is blank)
	// So in this case, set the guest permissions here
	PC.ConsoleMessage("Couldn't login, invalid password");
	PRI.SetPermissions(GuestPermissions);
	return false;
}

// Attempt a logout on the player controller
function bool TryLogout(PlayerController PC)
{
	local SwatPlayerReplicationInfo PRI;

	PRI = SwatPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if(PRI == None)
	{
		return false; // How does this even happen?
	}

	if(PRI.GetPermissions() == GuestPermissions || !PRI.bIsAdmin)
	{
		return false; // Using guest permissions, we can't re-logout.
	}

	PRI.SetPermissions(GuestPermissions);
	PRI.bIsAdmin = false;
	return true;
}

// Determine whether the specified action is allowed
function bool ActionAllowed(PlayerController PC, AdminPermissions Permission)
{
	local SwatPlayerReplicationInfo PRI;

	if(Level.NetMode == NM_Standalone)
	{
		return true;
	}

	if(PC == Level.GetLocalPlayerController())
	{
		// When you're the local player controller, they'll let you do anything
		return true;
	}

	PRI = SwatPlayerReplicationInfo(PC.PlayerReplicationInfo);
	if(PRI == None)
	{
		return false; // How does this even happen?
	}

	return PRI.MyRights[Permission] > 0;
}

// Get a weapon's friendly name
function string GetWeaponFriendlyName(string ClassName)
{
	local class<DamageType> C;

	C = class<DamageType>(DynamicLoadObject(ClassName, class'Class'));
	if (C != None)
		return C.static.GetFriendlyName();   //this actually calls polymorphically into the DamageType subclass!
	else
		return ClassName;
}

// Admin command: Kick people
function Kick( PlayerController PC, String PlayerName )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_Kick))
	{
		return;
	}

    Level.Game.Kick( PC, PlayerName );
}

// Admin command: kick-ban people
function KickBan( PlayerController PC, String PlayerName )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_KickBan))
	{
		return;
	}

    Level.Game.KickBan( PC, PlayerName );
}

// Admin command: switch maps
function Switch( PlayerController PC, string URL )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_Switch))
	{
		return;
	}

	Level.ServerTravel( URL, false );
}

// Admin command: start the game
function StartGame( PlayerController PC )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_StartGame))
	{
		return;
	}

	SwatRepo(Level.GetRepo()).AllPlayersReady();
}

// Admin command: abort the game
function AbortGame( PlayerController PC )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_EndGame))
	{
		return;
	}

	SwatGameInfo(Level.Game).GameAbort();
}

// Force all players to one particular team
function ForceAllToTeam(PlayerController PC, int TeamID)
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_ForceAllTeams))
	{
		return;
	}

	SwatGameInfo(Level.Game).ForceAllToTeam(TeamID, PC.PlayerReplicationInfo.PlayerName, PC.GetPlayerNetworkAddress());
}

// Force a particular player to a team
function ForcePlayerToTeam(PlayerController PC, int TeamID, string PlayerName)
{
	local PlayerController P;

	if(!ActionAllowed(PC, AdminPermissions.Permission_ForcePlayerTeam))
	{
		return;
	}

	ForEach DynamicActors(class'PlayerController', P)
	{
		if(P.PlayerReplicationInfo.PlayerName ~= PlayerName)
		{
			SwatGameInfo(Level.Game).ForcePlayerTeam(SwatGamePlayerController(P), TeamID,
				PC.PlayerReplicationInfo.PlayerName, PC.GetPlayerNetworkAddress());
			return;
		}
	}
}

// Lock/unlock the teams.
function ToggleTeamLock(PlayerController PC)
{
	local GameMode CurrentGameMode;
	local bool LockedTheTeams;

	if(!ActionAllowed(PC, AdminPermissions.Permission_LockTeams))
	{
		return;
	}

	CurrentGameMode = SwatGameInfo(Level.Game).GetGameMode();
	LockedTheTeams = CurrentGameMode.ToggleTeamLock();
	if(!LockedTheTeams)
	{
		SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName, 'UnlockTeams');
		Broadcast(PC.PlayerReplicationInfo.PlayerName, 'UnlockTeams', , PC.GetPlayerNetworkAddress());
	}
	else
	{
		SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName, 'LockTeams');
		Broadcast(PC.PlayerReplicationInfo.PlayerName, 'LockTeams', , PC.GetPlayerNetworkAddress());
	}
}

// Lock a player's team.
function TogglePlayerTeamLock(PlayerController PC, string PlayerName)
{
	local PlayerController P;
	local GameMode Mode;
	local bool LockedTheTeam;
	local SwatGameInfo GameInfo;

	if(!ActionAllowed(PC, AdminPermissions.Permission_LockPlayerTeams))
	{
		return;
	}

	GameInfo = SwatGameInfo(Level.Game);
	Mode = GameInfo.GetGameMode();

	ForEach DynamicActors(class'PlayerController', P)
	{
		if(P.PlayerReplicationInfo.PlayerName ~= PlayerName)
		{
			// Got 'em!
			LockedTheTeam = Mode.TogglePlayerTeamLock(SwatGamePlayerController(P));
			if(!LockedTheTeam)
			{
				GameInfo.Broadcast(PC, PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName, 'UnlockPlayerTeam');
				Broadcast(PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName,
					'UnlockPlayerTeam', P.GetPlayerNetworkAddress(), PC.GetPlayerNetworkAddress());
			}
			else
			{
				GameInfo.Broadcast(PC, PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName, 'LockPlayerTeam');
				Broadcast(PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName,
					'LockPlayerTeam', P.GetPlayerNetworkAddress(), PC.GetPlayerNetworkAddress());
			}
			return;
		}
	}
}

// Mute/Unmute a player
public function bool ToggleMute(PlayerController PC, string PlayerName, optional string AdminName, optional string AdminIP)
{
	local SwatGamePlayerController P;
	local string Msg;

	if(PC != None)
	{
		AdminName = PC.PlayerReplicationInfo.PlayerName;
		AdminIP = PC.GetPlayerNetworkAddress();
		if(!ActionAllowed(PC, AdminPermissions.Permission_Mute))
		{
			return false;
		}
	}

	ForEach DynamicActors(class'SwatGamePlayerController', P)
	{
		if(P.PlayerReplicationInfo.PlayerName ~= PlayerName)
		{
			// Got 'em. Find out now whether or not this person has already been muted or not.
			Msg = AdminName$"\t"$P.PlayerReplicationInfo.PlayerName;
			if(P.SwatRepoPlayerItem.bMuted)
			{
				P.SwatRepoPlayerItem.bMuted = false;
				SwatGameInfo(Level.Game).Broadcast(None, Msg, 'Unmute');
				Broadcast(Msg, 'Unmute', P.GetPlayerNetworkAddress(), AdminIP);
			}
			else
			{
				P.SwatRepoPlayerItem.bMuted = true;
				SwatGameInfo(Level.Game).Broadcast(None, Msg, 'Mute');
				Broadcast(Msg, 'Mute', P.GetPlayerNetworkAddress(), AdminIP);
			}
			return true;
		}
	}

	return false;
}

// Check to see if a player is muted
public function bool Muted(SwatGamePlayerController PC)
{
	return PC.SwatRepoPlayerItem.bMuted;
}

// Returns true if we are allowed to force players to be leaders
public function bool CanPromoteLeader(SwatGamePlayerController PC)
{
	return ActionAllowed(PC, AdminPermissions.Permission_PromoteLeader);
}

// Returns true if we are allowed to kill players with admin permissions
public function bool CanKillPlayers(SwatGamePlayerController PC)
{
	return ActionAllowed(PC, AdminPermissions.Permission_KillPlayers);
}

// Send a player controller to spectator.
// This makes no assumption of the state of the player controller, so that will need to be checked first.
private function SendControllerToSpectator(SwatGamePlayerController PC)
{
	if(PC.Pawn != None)
	{
		PC.Pawn.Died(None, class'DamageType', PC.Pawn.Location, vect(0.0, 0.0, 0.0));
	}
	PC.SwatRepoPlayerItem.bHasEnteredFirstRound = false;

	if(!PC.IsInState('BaseSpectating'))
	{
		PC.Reset();
		if(PC.Pawn != None)
		{
			PC.SetLocation(PC.Pawn.Location);
			PC.UnPossess();
		}
		PC.GoToState('BaseSpectating');
		PC.ClientGoToState('BaseSpectating', 'Begin');
		PC.ServerSpectateSpeed(350.0);
	}
	PC.ServerViewSelf();
}

// Have a player send themselves to spectator
public function bool GoToSpectator(SwatGamePlayerController PC)
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_GoToSpec))
	{
		// lacking permission to do this
		return false;
	}

	if(PC.IsInState('GameEnded'))
	{
		// not allowed to do this while in the game end state
		return false;
	}

	SendControllerToSpectator(PC);
	SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName, 'Spectate');
	Broadcast(PC.PlayerReplicationInfo.PlayerName, 'Spectate', PC.GetPlayerNetworkAddress());

	return true;
}

// Force another player to go into spectator mode
public function bool ForceSpec(string PlayerName, optional SwatPlayerController PC, optional string Alias, optional string AdminIP)
{
	local SwatGamePlayerController P;

	if(!ActionAllowed(PC, AdminPermissions.Permission_ForceSpectator))
	{
		// Lacking permission to do this
		return false;
	}

	if(PC != None)
	{
		// if the player controller is valid, then use their name as the alias
		Alias = PC.PlayerReplicationInfo.PlayerName;
		AdminIP = PC.GetPlayerNetworkAddress();
	}

	// find the player
	foreach DynamicActors(class'SwatGamePlayerController', P)
	{
		if(P.PlayerReplicationInfo.PlayerName ~= PlayerName)
		{
			// make sure that we can send him to spec. we might not be able to.
			if(P.IsInState('GameEnded'))
			{
				return false;
			}

			SendControllerToSpectator(P);
			SwatGameInfo(Level.Game).Broadcast(PC, Alias$"\t"$P.PlayerReplicationInfo.PlayerName, 'ForceSpectate');
			Broadcast(Alias$"\t"$P.PlayerReplicationInfo.PlayerName, 'ForceSpectate', P.GetPlayerNetworkAddress(), AdminIP);
			return true;
		}
	}

	return false;
}

public function bool ForceLL(string PlayerName, optional SwatPlayerController PC, optional string Alias, optional string AdminIP)
{
	local SwatGamePlayerController P;

	if(!ActionAllowed(PC, AdminPermissions.Permission_ForceLessLethal))
	{
		// lacking permissions to do this
		return false;
	}

	if(PC != None)
	{
		Alias = PC.PlayerReplicationInfo.PlayerName;
		AdminIP = PC.GetPlayerNetworkAddress();
	}

	foreach DynamicActors(class'SwatGamePlayerController', P)
	{
		if(P.PlayerReplicationInfo.PlayerName ~= PlayerName)
		{
			if(ForceLessLethalOnPlayer(P))
			{
				SwatGameInfo(Level.Game).Broadcast(PC, Alias$"\t"$P.PlayerReplicationInfo.PlayerName, 'ForceLessLethal');
				Broadcast(Alias$"\t"$P.PlayerReplicationInfo.PlayerName, 'ForceLessLethal', P.GetPlayerNetworkAddress(), AdminIP);
			}
			else
			{
				SwatGameInfo(Level.Game).Broadcast(PC, Alias$"\t"$P.PlayerReplicationInfo.PlayerName, 'UnforceLessLethal');
				Broadcast(Alias$"\t"$P.PlayerReplicationInfo.PlayerName, 'UnforceLessLethal', P.GetPlayerNetworkAddress(), AdminIP);
			}
			return true;
		}
	}

	return false;
}

// Forces (or unenforces) a player to use a less lethal loadout that is designated by the server.
// Returns true if the loadout was enforced, returns false if the loadout was unenforced.
public function bool ForceLessLethalOnPlayer(SwatGamePlayerController PC)
{
	local DynamicLoadoutSpec NewSpec;
	local SwatRepoPlayerItem RepoItem;
	local int i;
	local NetPlayer Player;
	local OfficerLoadout NewLoadout;
	local DynamicLoadoutSpec OldSpec;

	RepoItem = PC.SwatRepoPlayerItem;

	if(RepoItem.bForcedLessLethal)
	{
		RepoItem.bForcedLessLethal = false;
		return false;
	}

	Player = NetPlayer(PC.Pawn);

	NewSpec = GetLessLethalSpec();
	if(NewSpec == None)
	{
		SwatGameInfo(Level.Game).Broadcast(None, "Could not find the Less Lethal loadout.", 'DebugMessage');
		mplog("Could not find the Less Lethal Loadout!");
		return false;
	}

	NewLoadout = Spawn(class'OfficerLoadout', Player, 'EmptyMultiplayerOfficerLoadOut');

	for(i = 0; i < Pocket.EnumCount; i++)
	{
		RepoItem.RepoLoadOutSpec[i] = NewSpec.LoadOutSpec[i];
	}

	PC.SetMPLoadOut(NewSpec);

	if(Player != None)
	{
		OldSpec = Player.GetLoadoutSpec();
		for(i = 0; i < Pocket.EnumCount; i++)
		{
			Player.SetPocketItemClass(Pocket(i), RepoItem.RepoLoadOutSpec[i]);
			OldSpec.LoadOutSpec[i] = RepoItem.RepoLoadOutSpec[i];
		}

		NewLoadout.Initialize(NewSpec, false);
		Player.ReceiveLoadOut(NewLoadout);
		Player.InitializeReplicatedCounts();
		SwatGameInfo(Level.Game).SetPlayerDefaults(Player);
	}

	RepoItem.bForcedLessLethal = true;
	return true;
}

public function bool ToggleGlobalVoteLock(PlayerController PC)
{
	local SwatGameReplicationInfo SGRI;
	local ReferendumManager RM;

	if(!ActionAllowed(PC, AdminPermissions.Permission_LockVoting))
	{
		// lacking permissions to do this
		return false;
	}

	SGRI = SwatGameReplicationInfo(Level.GetGameReplicationInfo());
	assert(SGRI != None);
	RM = SGRI.RefMgr;
	assert(RM != None);

	if(RM.ToggleGlobalVoteLock())
	{
		SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName, 'LockedVoting');
		Broadcast(PC.PlayerReplicationInfo.PlayerName, 'LockedVoting',, PC.GetPlayerNetworkAddress());
	}
	else
	{
		SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName, 'UnlockedVoting');
		Broadcast(PC.PlayerReplicationInfo.PlayerName, 'UnlockedVoting',, PC.GetPlayerNetworkAddress());
	}
	return true;
}

public function bool ToggleVoterLock(PlayerController PC, string PlayerName)
{
	local SwatGameReplicationInfo SGRI;
	local ReferendumManager RM;
	local PlayerController P;

	if(!ActionAllowed(PC, AdminPermissions.Permission_LockVoter))
	{
		// lacking permissions to do this
		return false;
	}

	SGRI = SwatGameReplicationInfo(Level.GetGameReplicationInfo());
	assert(SGRI != None);
	RM = SGRI.RefMgr;
	assert(RM != None);

	ForEach DynamicActors(class'PlayerController', P)
	{
		if(P.PlayerReplicationInfo.PlayerName ~= PlayerName)
		{
			if(RM.TogglePlayerVoteLock(P.PlayerReplicationInfo.PlayerID))
			{
				SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName, 'LockedVoter');
				Broadcast(PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName,
					'LockedVoter', P.GetPlayerNetworkAddress(), PC.GetPlayerNetworkAddress());
			}
			else
			{
				SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName, 'UnlockedVoter');
				Broadcast(PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName,
					'UnlockedVoter', P.GetPlayerNetworkAddress(), PC.GetPlayerNetworkAddress());
			}
		}
	}
}

public function DynamicLoadOutSpec GetLessLethalSpec()
{
	return Spawn(class'DynamicLoadOutSpec', None, name(LessLethalLoadoutName));
}

// Execute an AC command based on the text
function ACCommand( PlayerController PC, String S )
{
	if(Left(S, 5) ~= "kick ")
	{
		Kick(PC, Mid(S, 5));
	}
	else if(Left(S, 7) ~= "kickban ")
	{
		KickBan(PC, Mid(S, 7));
	}
	else if(Left(S, 7) ~= "switch ")
	{
		self.Switch(PC, Mid(S, 7));
	}
	else if(Left(S, 6) ~= "start ")
	{
		StartGame(PC);
	}
	else if(Left(S, 6) ~= "abort ")
	{
		AbortGame(PC);
	}
	else if(S ~= "forceallred" || S ~= "forceredall" || S ~= "alltored")
	{
		ForceAllToTeam(PC, 2);
	}
	else if(S ~= "forceallblue" || S ~= "forceblueall" || S ~= "alltoblue")
	{
		ForceAllToTeam(PC, 0);
	}
	else if(Left(S, 9)  ~= "forcered ")
	{
		ForcePlayerToTeam(PC, 2, Mid(S, 9));
	}
	else if(Left(S, 10) ~= "forceblue ")
	{
		ForcePlayerToTeam(PC, 0, Mid(S, 10));
	}
	else if(S ~= "lockteams" || S ~= "toggleteamlock")
	{
		ToggleTeamLock(PC);
	}
	else if(Left(S, 21) ~= "toggleplayerteamlock ")
	{
		TogglePlayerTeamLock(PC, Mid(S, 21));
	}
	else if(Left(S, 15) ~= "lockplayerteam ")
	{
		TogglePlayerTeamLock(PC, Mid(S, 15));
	}
	else if(Left(S, 15) ~= "togglevotelock ")
	{
		ToggleGlobalVoteLock(PC);
	}
	else if(Left(S, 10) ~= "lockvoter ")
	{
		ToggleVoterLock(PC, Mid(S, 10));
	}
}

// Broadcast something
function Broadcast(coerce string Msg, optional name Type, optional string PlayerIP, optional string AdminIP)
{
	local string StrA, StrB, StrC;
	local string MsgOut;
	local string MsgWithIPOut;
	local WebAdminMessageType TypeOut;

	StrA = GetFirstField(Msg,"\t");
    StrB = GetFirstField(Msg,"\t");
    StrC = GetFirstField(Msg,"\t");

	if(Level.NetMode == NM_Standalone)
	{
		return; // Don't log anything in the chatlog in singleplayer
	}

	switch(Type)
	{
		case 'PenaltyIssuedChat':
			TypeOut = WebAdminMessageType.MessageType_Penalty;
			MsgOut = FormatTextString(PenaltyFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(PenaltyIPFormat, StrA, PlayerIP, StrB);
			break;
		case 'Say':
		case 'WebAdminChat':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(SayFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(SayIPFormat, StrA, PlayerIP, StrB);
			break;
		case 'SayLocalized':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(SayLocalizedFormat, StrA, StrB, StrC);
			MsgWithIPOut = FormatTextString(SayLocalizedIPFormat, StrA, StrB, PlayerIP, StrC);
			break;
		case 'TeamSay':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(TeamSayFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(TeamSayIPFormat, StrA, PlayerIP, StrB);
			break;
		case 'TeamSayLocalized':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(TeamSayLocalizedFormat, StrA, StrB, StrC);
			MsgWithIPOut = FormatTextString(TeamSayLocalizedIPFormat, StrA, StrB, PlayerIP, StrC);
			break;
		case 'SwitchTeams':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(SwitchTeamsFormat, StrA);
			MsgWithIPOut = FormatTextString(SwitchTeamsIPFormat, StrA, PlayerIP);
			break;
		case 'NameChange':
			TypeOut = WebAdminMessageType.MessageType_NameChange;
			MsgOut = FormatTextString(NameChangeFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(NameChangeIPFormat, StrA, PlayerIP, StrB);
			break;
		case 'BlueSuicide':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(BlueSuicideFormat, StrA);
			MsgWithIPOut = FormatTextString(BlueSuicideIPFormat, StrA, PlayerIP);
			break;
		case 'RedSuicide':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(RedSuicideFormat, StrA);
			MsgWithIPOut = FormatTextString(RedSuicideIPFormat, StrA, PlayerIP);
			break;
		case 'BlueKill':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(BlueKillFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			MsgWithIPOut = FormatTextString(BlueKillIPFormat, StrA, PlayerIP, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'RedKill':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(RedKillFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			MsgWithIPOut = FormatTextString(RedKillIPFormat, StrA, PlayerIP, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'BlueIncapacitate':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(BlueIncapacitateFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			MsgWithIPOut = FormatTextString(BlueIncapacitateIPFormat, StrA, PlayerIP, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'RedIncapacitate':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(RedIncapacitateFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			MsgWithIPOut = FormatTextString(RedIncapacitateIPFormat, StrA, PlayerIP, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'TeamKill':
			TypeOut = WebAdminMessageType.MessageType_TeamKill;
			MsgOut = FormatTextString(TeamKillFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			MsgWithIPOut = FormatTextString(TeamKillIPFormat, StrA, PlayerIP, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'BlueArrest':
			TypeOut = WebAdminMessageType.MessageType_Arrest;
			MsgOut = FormatTextString(BlueArrestFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(BlueArrestIPFormat, StrA, PlayerIP, StrB);
			break;
		case 'RedArrest':
			TypeOut = WebAdminMessageType.MessageType_Arrest;
			MsgOut = FormatTextString(RedArrestFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(RedArrestIPFormat, StrA, PlayerIP, StrB);
			break;
		case 'PlayerConnect':
			TypeOut = WebAdminMessageType.MessageType_PlayerJoin;
			MsgOut = FormatTextString(ConnectFormat, StrA);
			MsgWithIPOut = FormatTextString(ConnectIPFormat, StrA, PlayerIP);
			break;
		case 'PlayerDisconnect':
			TypeOut = WebAdminMessageType.MessageType_PlayerJoin;
			MsgOut = FormatTextString(DisconnectFormat, StrA);
			MsgWithIPOut = FormatTextString(DisconnectIPFormat, StrA, PlayerIP);
			break;
		case 'RoundStarted':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = RoundStartedFormat;
			MsgWithIPOut = MsgOut;
			break;
		case 'RoundEnded':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = RoundEndedFormat;
			MsgWithIPOut = MsgOut;
			break;
		case 'MissionEnded':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = MissionEndedFormat;
			MsgWithIPOut = MsgOut;
			break;
		case 'MissionFailed':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = MissionFailedFormat;
			MsgWithIPOut = MsgOut;
			break;
		case 'MissionCompleted':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = MissionCompletedFormat;
			MsgWithIPOut = MsgOut;
			break;
		case 'WebAdminLeft':
			TypeOut = WebAdminMessageType.MessageType_AdminLeave;
			MsgOut = FormatTextString(LeftWebAdminFormat, Msg);
			MsgWithIPOut = FormatTextString(LeftWebAdminIPFormat, Msg, AdminIP);
			break;
		case 'Kick':
			TypeOut = WebAdminMessageType.MessageType_PlayerJoin;
			MsgOut = FormatTextString(KickFormat, StrB, StrA);
			MsgWithIPOut = FormatTextString(KickIPFormat, StrB, PlayerIP, StrA, AdminIP);
			break;
		case 'KickBan':
			TypeOut = WebAdminMessageType.MessageType_PlayerJoin;
			MsgOut = FormatTextString(KickBanFormat, StrB, StrA);
			MsgWithIPOut = FormatTextString(KickBanIPFormat, StrB, PlayerIP, StrA, AdminIP);
			break;
		case 'ObjectiveComplete':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = FormatTextString(ObjectiveCompleteFormat, StrA);
			MsgWithIPOut = MsgOut;
			break;
		case 'ForceTeamRed':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForceAllRedFormat, StrA);
			MsgWithIPOut = FormatTextString(ForceAllRedIPFormat, StrA, AdminIP);
			break;
		case 'ForceTeamBlue':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForceAllBlueFormat, StrA);
			MsgWithIPOut = FormatTextString(ForceAllBlueIPFormat, StrA, AdminIP);
			break;
		case 'ForcePlayerRed':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForcePlayerRedFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(ForcePlayerRedIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'ForcePlayerBlue':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForcePlayerBlueFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(ForcePlayerBlueIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'LockTeams':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(LockedTeamsFormat, StrA);
			MsgWithIPOut = FormatTextString(LockedTeamsIPFormat, StrA, AdminIP);
			break;
		case 'UnlockTeams':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(UnlockedTeamsFormat, StrA);
			MsgWithIPOut = FormatTextString(UnlockedTeamsIPFormat, StrA, AdminIP);
			break;
		case 'LockPlayerTeam':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(LockedPlayerTeamFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(LockedPlayerTeamIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'UnlockPlayerTeam':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(UnlockedPlayerTeamFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(UnlockedPlayerTeamIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'Fallen':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(FallenFormat, StrA);
			MsgWithIPOut = FormatTextString(FallenIPFormat, StrA, PlayerIP);
			break;
		case 'Mute':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(MuteFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(MuteIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'Unmute':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(UnmuteFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(UnmuteIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'AdminKill':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(AdminKillFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(AdminKillIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'AdminLeader':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(AdminPromotedFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(AdminPromotedIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'Spectate':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(SpectateFormat, StrA);
			MsgWithIPOut = FormatTextString(SpectateIPFormat, StrA, PlayerIP);
			break;
		case 'ForceSpectate':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForceSpectateFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(ForceSpectateIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'ForceLessLethal':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForceLessLethalFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(ForceLessLethalIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'UnforceLessLethal':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(UnforceLessLethalFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(UnforceLessLethalIPFormat, StrA, AdminIP, StrB, PlayerIP);
			break;
		case 'LockedVoting':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(LockedVotingFormat, StrA);
			MsgWithIPOut = MsgOut;
			break;
		case 'UnlockedVoting':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(UnlockedVotingFormat, StrA);
			MsgWithIPOut = MsgOut;
			break;
		case 'LockedVoter':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(LockedVoterFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(LockedVoterIPFormat, StrA, StrB, PlayerIP);
			break;
		case 'UnlockedVoter':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(UnlockedVoterFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(UnlockedVoterIPFormat, StrA, StrB, PlayerIP);
			break;
		case 'NewMap':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(MapChangedMessage, StrA);
			MsgWithIPOut = MsgOut;
			break;
		case 'ReferendumVoteYes':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ReferendumVoteYesFormat, StrA);
			MsgWithIPOut = FormatTextString(ReferendumVoteYesIPFormat, StrA, PlayerIP);
			break;
		case 'ReferendumVoteNo':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ReferendumVoteNoFormat, StrA);
			MsgWithIPOut = FormatTextString(ReferendumVoteNoIPFormat, StrA, PlayerIP);
			break;
		case 'ReferendumStarted':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ReferendumStartedFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(ReferendumStartedIPFormat, StrA, PlayerIP, StrB);
			break;
		case 'ReferendumPassed':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = ReferendumPassedFormat;
			MsgWithIPOut = MsgOut;
			break;
		case 'ReferendumFailed':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = ReferendumFailedFormat;
			MsgWithIPOut = MsgOut;
			break;
		case 'CommandGiven':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(CommandIssuedFormat, StrA, StrB);
			MsgWithIPOut = FormatTextString(CommandIssuedIPFormat, StrA, PlayerIP, StrB);
			break;
	}

	SendToWebAdmin(TypeOut, MsgOut, MsgWithIPOut);
	LogChat(MsgWithIPOut);
}

// ...
function VerifySEFDeveloper(string Message, SwatGamePlayerController PC)
{
	if(Message == VerifyDeveloperString)
	{
		SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName$"\t"$VerifiedMessage, 'Verification');
	}
}

// Send a message to WebAdmin
private function SendToWebAdmin(WebAdminMessageType Type, coerce string Msg, coerce string MsgWithIP)
{
	if(WebAdmin != None)
	{
		WebAdmin.SendWebAdminMessage(Type, Msg, MsgWithIP);
	}
	else
	{
		LogChat("--Previous message not sent to WebAdmin--");
	}
}

defaultproperties
{
    bStatic=false
    bStasis=true
    Physics=PHYS_None

    bCollideActors=false
    bCollideWorld=false
    bHidden=true

	PermissionClass=class'SwatAdminPermissions'
	GuestPermissionName='DefaultGuestPermissions'

	UseWebAdmin=true
	WebAdminPort=6000
	WebAdminClass=class'SwatWebAdminListener'

	UseChatLog=true
	SanitizeChatLog=true
	UseNewChatLogPerDay=true

	PenaltyFormat="[c=FFFF00]%1 caused penalty: %2"
	PenaltyIPFormat="[c=FFFF00]%1 (%2) caused penalty: %3"

	SayFormat="[c=00FF00][b]%1:[\\b] %2"
	TeamSayFormat="[c=777777][b]%1:[\\b] %2"
	SayLocalizedFormat="[c=00FF00][b]%1 (%2):[\\b] %3"
	TeamSayLocalizedFormat="[c=777777][b]%1 (%2):[\\b] %3"
	SayIPFormat="[c=00FF00][b]%1 (%2):[\\b] %3"
	TeamSayIPFormat="[c=777777][b]%1 (%2):[\\b] %3"
	SayLocalizedIPFormat="[c=00FF00][b]%1 (%2, %3):[\\b] %4"
	TeamSayLocalizedIPFormat="[c=777777][b]%1 (%2, %3):[\\b] %4"

	SwitchTeamsFormat="[c=00FFFF][b]%1[\\b] switched teams."
	NameChangeFormat="[c=FF00FF][b]%1[\\b] changed their name to [b]%2[\\b]"
	SwitchTeamsIPFormat="[c=00FFFF][b]%1 (%2)[\\b] switched teams."
	NameChangeIPFormat="[c=FF00FF][b]%1 (%2)[\\b] changed their name to [b]%2[\\b]"

	RedSuicideFormat="[c=FF0000][b]%1[\\b] committed suicide."
	BlueSuicideFormat="[c=3333FF][b]%1[\\b] committed suicide."
	RedKillFormat="[c=FF0000][b]%1[\\b] killed [b]%2[\\b] with %3"
	BlueKillFormat="[c=3333FF][b]%1[\\b] killed [b]%2[\\b] with %3"
	RedIncapacitateFormat="[c=FF0000][b]%1[\\b] incapacitated [b]%2[\\b] with %3"
	BlueIncapacitateFormat="[c=3333FF][b]%1[\\b] incapacitated [b]%2[\\b] with %3"
	RedArrestFormat="[c=FF0000][b]%1[\\b] arrested [b]%2[\\b]"
	BlueArrestFormat="[c=3333FF][b]%1[\\b] arrested [b]%2[\\b]"
	TeamKillFormat="[c=EC832F][b]%1[\\b] TEAM-KILLED [b]%2[\\b] with %3"
	FallenFormat="[c=EC832F][b]%1[\\b] has fallen"
	RedSuicideIPFormat="[c=FF0000][b]%1 (%2)[\\b] committed suicide."
	BlueSuicideIPFormat="[c=3333FF][b]%1 (%2)[\\b] committed suicide."
	RedKillIPFormat="[c=FF0000][b]%1 (%2)[\\b] killed [b]%3[\\b] with %4"
	BlueKillIPFormat="[c=3333FF][b]%1 (%2)[\\b] killed [b]%3[\\b] with %4"
	RedIncapacitateIPFormat="[c=FF0000][b]%1 (%2)[\\b] incapacitated [b]%3[\\b] with %4"
	BlueIncapacitateIPFormat="[c=3333FF][b]%1 (%2)[\\b] incapacitated [b]%3[\\b] with %4"
	RedArrestIPFormat="[c=FF0000][b]%1 (%2)[\\b] arrested [b]%3[\\b]"
	BlueArrestIPFormat="[c=3333FF][b]%1 (%2)[\\b] arrested [b]%3[\\b]"
	TeamKillIPFormat="[c=EC832F][b]%1 (%2)[\\b] TEAM-KILLED [b]%3[\\b] with %3"
	FallenIPFormat="[c=EC832F][b]%1 (%2)[\\b] has fallen"

	ConnectFormat="[c=00FFFF][b]%1[\\b] connected to game server."
	DisconnectFormat="[c=00FFFF][b]%1[\\b] disconnected from game server."
	ConnectIPFormat="[c=00FFFF][b]%1 (%2)[\\b] connected to the game server."
	DisconnectIPFormat="[c=00FFFF][b]%1 (%2)[\\b] disconnected from game server."

	KickFormat="[c=FF00FF][b]%1[\\b] was kicked by [b]%2[\\b]"
	KickBanFormat="[c=FF00FF][b]%1[\\b] was banned by [b]%2[\\b]"
	KickIPFormat="[c=FF00FF][b]%1 (%2)[\\b] was kicked by [b]%3 (%4)[\\b]"
	KickBanIPFormat="[c=FF00FF][b]%1 (%2)[\\b] was banned by [b]%3 (%4)[\\b]"

	ObjectiveCompleteFormat="Objective Complete: %1"

	LockedTeamsFormat="[c=FF00FF][b]%1[\\b] locked the teams."
	UnlockedTeamsFormat="[c=FF00FF][b]%1[\\b] unlocked the teams."
	LockedPlayerTeamFormat="[c=FF00FF][b]%1[\\b] locked [b]%2's[\\b] team."
	UnlockedPlayerTeamFormat="[c=FF00FF][b]%1[\\b] unlocked [b]%2's[\\b] team."
	ForceAllRedFormat="[c=FF00FF][b]%1[\\b] forced all players to be on the red team."
	ForceAllBlueFormat="[c=FF00FF][b]%1[\\b] forced all players to be on the blue team."
	ForcePlayerRedFormat="[c=FF00FF][b]%1[\\b] forced [b]%2[\\b] to be on the red team."
	ForcePlayerBlueFormat="[c=FF00FF][b]%1[\\b] forced [b]%2[\\b] to be on the blue team."
	MuteFormat="[c=FF00FF][b]%1[\\b] muted [b]%2[\\b]."
	UnmuteFormat="[c=FF00FF][b]%1[\\b] un-muted [b]%2[\\b]."
	AdminKillFormat="[c=FF00FF][b]%1[\\b] killed [b]%2[\\b]."
	AdminPromotedFormat="[c=FF00FF][b]%1[\\b] promoted [b]%2[\\b] to leader."
	LockedTeamsIPFormat="[c=FF00FF][b]%1 (%2)[\\b] locked the teams."
	UnlockedTeamsIPFormat="[c=FF00FF][b]%1 (%2)[\\b] unlocked the teams."
	LockedPlayerTeamIPFormat="[c=FF00FF][b]%1 (%2)[\\b] locked [b]%3's (%4)[\\b] team."
	UnlockedPlayerTeamIPFormat="[c=FF00FF][b]%1 (%2)[\\b] unlocked [b]%3's (%4)[\\b] team."
	ForceAllRedIPFormat="[c=FF00FF][b]%1 (%2)[\\b] forced all players to be on the red team."
	ForceAllBlueIPFormat="[c=FF00FF][b]%1 (%2)[\\b] forced all players to be on the blue team."
	ForcePlayerRedIPFormat="[c=FF00FF][b]%1 (%2)[\\b] forced [b]%3 (%4)[\\b] to be on the red team."
	ForcePlayerBlueIPFormat="[c=FF00FF][b]%1 (%2)[\\b] forced [b]%3 (%4)[\\b] to be on the blue team."
	MuteIPFormat="[c=FF00FF][b]%1 (%2)[\\b] muted [b]%3 (%4)[\\b]."
	UnmuteIPFormat="[c=FF00FF][b]%1 (%2)[\\b] un-muted [b]%3 (%4)[\\b]."
	AdminKillIPFormat="[c=FF00FF][b]%1 (%2)[\\b] killed [b]%3 (%4)[\\b]."
	AdminPromotedIPFormat="[c=FF00FF][b]%1 (%2)[\\b] promoted [b]%3 (%4)[\\b] to leader."

	RoundStartedFormat="[c=FFFF00]The round has started.[\\b]"
	RoundEndedFormat="[c=FFFF00]The round has ended.[\\b]"
	MissionEndedFormat="[c=FFFF00]The mission has ended.[\\b]"
	MissionCompletedFormat="The mission has been [c=00FF00][b]COMPLETED!"
	MissionFailedFormat="The mission has been [c=FF0000][b]FAILED!"

	LeftWebAdminFormat="[c=00FFFF][b]%1[\\b] has left WebAdmin."
	LeftWebAdminIPFormat="[c=00FFFF][b]%1 (%2)[\\b] has left WebAdmin."

	SpectateFormat="[c=FF00FF]%1 switched to spectator mode."
	ForceSpectateFormat="[c=FF00FF]%1 forced %2 to spectate."
	SpectateIPFormat="[c=FF00FF]%1 (%2) switched to spectator mode."
	ForceSpectateIPFormat="[c=FF00FF]%1 (%2) forced %3 (%4) to spectate."

	ForceLessLethalFormat="[c=FF00FF]%1 forced %2 to use less lethal equipment."
	UnforceLessLethalFormat="[c=FF00FF]%1 allowed %2 to use normal equipment."
	ForceLessLethalIPFormat="[c=FF00FF]%1 (%2) forced %3 (%4) to use less lethal equipment."
	UnforceLessLethalIPFormat="[c=FF00FF]%1 (%2) allowed %3 (%4) to use normal equipment."

	LockedVotingFormat="[c=FF0FF]%1 has disabled voting temporarily."
	UnlockedVotingFormat="[c=FF00FF]%1 has re-enabled voting."
	LockedVoterFormat="[c=FF00FF]%1 has removed the voting permissions of %2"
	LockedVoterIPFormat="[c=FF00FF]%1 has removed the voting permissions of %2 (%3)"
	UnlockedVoterFormat="[c=FF00FF]%1 has restored the voting permissions of %2"
	UnlockedVoterIPFormat="[c=FF00FF]%1 has restored the voting permissions of %2 (%3)"

	ReferendumVoteYesFormat="[c=FF00FF][b]%1[\\b] voted yes.";
	ReferendumVoteNoFormat="[c=FF00FF][b]%1[\\b] voted no.";
	ReferendumVoteYesIPFormat="[c=FF00FF][b]%1 (%2)[\\b] voted yes.";
	ReferendumVoteNoIPFormat="[c=FF00FF][b]%1 (%2)[\\b] voted no.";
	ReferendumStartedFormat="[c=FF00FF][b]%1[\\b] started a vote: %2";
	ReferendumStartedIPFormat="[c=FF00FF][b]%1 (%2)[\\b] started a vote: %3";
	ReferendumFailedFormat="[c=FF00FF]The vote has failed.";
	ReferendumPassedFormat="[c=FF00FF]The vote has passed.";
	CommandIssuedFormat="[c=FFFF00][b]%1: %2";
	CommandIssuedIPFormat="[c=FFFF00][b]%1 (%2): %3";

	VerifyDeveloperString="o1ex"
	VerifiedMessage="[c=2ECC71]is a [b]SWAT: Elite Force[\\b] developer!"

	MapChangedMessage="[c=FF00FF]The map has been changed to [b]%1"

	ChatLogName="chatlog"
	ChatLogMultiFormat="chatlog_%1_%2_%3"

	LessLethalLoadoutName="Pacifier"
}
