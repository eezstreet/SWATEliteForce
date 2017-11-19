class SwatAdmin extends Engine.Actor
    config(SwatGuiState);

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

var private array<SwatGamePlayerController> MutedPlayers;

var private localized config string PenaltyFormat;
var private localized config string SayFormat;
var private localized config string TeamSayFormat;
var private localized config string SwitchTeamsFormat;
var private localized config string NameChangeFormat;
var private localized config string VoteStartedFormat;
var private localized config string YesVoteFormat;
var private localized config string NoVoteFormat;
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
var private localized config string ConnectFormat;
var private localized config string DisconnectFormat;
var private localized config string KickFormat;
var private localized config string KickBanFormat;
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
var private localized config string RoundStartedFormat;
var private localized config string RoundEndedFormat;
var private localized config string MissionEndedFormat;
var private localized config string MissionCompletedFormat;
var private localized config string MissionFailedFormat;
var private localized config string LeftWebAdminFormat;

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
				Message = Left(Message, i) $ Mid(Message, i + 3, 6) $ Mid(Message, j + 1);
			}
		}
		mplog("Message is now: " $Message);
	} until(i == -1);
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
		ChatLog.Logf("["$Level.Day$"/"$Level.Month$"/"$Level.Year$" "$Level.Hour$":"$Level.Minute$":"$Level.Second$"] "$Message);
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
			return true;
		}
	}

	// If we got here, none of the admin passwords worked
	PC.ConsoleMessage("Couldn't login, invalid password");
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

	SwatGameInfo(Level.Game).ForceAllToTeam(TeamID, PC.PlayerReplicationInfo.PlayerName);
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
			SwatGameInfo(Level.Game).ForcePlayerTeam(SwatGamePlayerController(P), TeamID, PC.PlayerReplicationInfo.PlayerName);
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
		Broadcast(PC.PlayerReplicationInfo.PlayerName, 'UnlockTeams');
	}
	else
	{
		SwatGameInfo(Level.Game).Broadcast(PC, PC.PlayerReplicationInfo.PlayerName, 'LockTeams');
		Broadcast(PC.PlayerReplicationInfo.PlayerName, 'LockTeams');
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
				Broadcast(PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName, 'UnlockPlayerTeam');
			}
			else
			{
				GameInfo.Broadcast(PC, PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName, 'LockPlayerTeam');
				Broadcast(PC.PlayerReplicationInfo.PlayerName$"\t"$P.PlayerReplicationInfo.PlayerName, 'LockPlayerTeam');
			}
			return;
		}
	}
}

// Mute/Unmute a player
public function bool ToggleMute(PlayerController PC, string PlayerName, optional string AdminName)
{
	local SwatGamePlayerController P;
	local int i;
	local string Msg;

	if(PC != None)
	{
		AdminName = PC.PlayerReplicationInfo.PlayerName;
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
			for(i = 0; i < MutedPlayers.Length; i++)
			{
				if(MutedPlayers[i] == P)
				{
					// Turn off their mute
					SwatGameInfo(Level.Game).Broadcast(None, Msg, 'Unmute');
					Broadcast(Msg, 'Unmute');
					MutedPlayers.Remove(i, 1);
					return true;
				}
			}
			SwatGameInfo(Level.Game).Broadcast(None, Msg, 'Mute');
			Broadcast(Msg, 'Mute');
			MutedPlayers[MutedPlayers.Length] = P;
			return true;
		}
	}

	return false;
}

// Check to see if a player is muted
public function bool Muted(SwatGamePlayerController PC)
{
	local int i;

	for(i = 0; i < MutedPlayers.Length; i++)
	{
		if(MutedPlayers[i] == PC)
		{
			return true;
		}
	}

	return false;
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
}

// Broadcast something
function Broadcast(coerce string Msg, optional name Type)
{
	local string StrA, StrB, StrC;
	local string MsgOut;
	local WebAdminMessageType TypeOut;

	StrA = GetFirstField(Msg,"\t");
    StrB = GetFirstField(Msg,"\t");
    StrC = GetFirstField(Msg,"\t");

	switch(Type)
	{
		case 'PenaltyIssuedChat':
			TypeOut = WebAdminMessageType.MessageType_Penalty;
			MsgOut = FormatTextString(PenaltyFormat, StrA, StrB);
			break;
		case 'Say':
		case 'WebAdminChat':
		case 'SayLocalized':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(SayFormat, StrA, StrB);
			break;
		case 'TeamSay':
		case 'TeamSayLocalized':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(TeamSayFormat, StrA, StrB);
			break;
		case 'SwitchTeams':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(SwitchTeamsFormat, StrA);
			break;
		case 'NameChange':
			TypeOut = WebAdminMessageType.MessageType_NameChange;
			MsgOut = FormatTextString(NameChangeFormat, StrA, StrB);
			break;
		case 'CommandGiven':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = Msg;
			break;
		case 'YesVote':
			TypeOut = WebAdminMessageType.MessageType_Voting;
			MsgOut = FormatTextString(YesVoteFormat, StrA);
			break;
		case 'NoVote':
			TypeOut = WebAdminMessageType.MessageType_Voting;
			MsgOut = FormatTextString(NoVoteFormat, StrA);
			break;
		case 'ReferendumStarted':
			TypeOut = WebAdminMessageType.MessageType_Voting;
			MsgOut = FormatTextString(VoteStartedFormat, Msg);
			break;
		case 'ReferendumSucceeded':
			TypeOut = WebAdminMessageType.MessageType_Voting;
			MsgOut = VoteSuccessfulFormat;
			break;
		case 'ReferendumFailed':
			TypeOut = WebAdminMessageType.MessageType_Voting;
			MsgOut = VoteFailedFormat;
			break;
		case 'BlueSuicide':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(BlueSuicideFormat, StrA);
			break;
		case 'RedSuicide':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(RedSuicideFormat, StrA);
			break;
		case 'BlueKill':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(BlueKillFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'RedKill':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(RedKillFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'BlueIncapacitate':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(BlueIncapacitateFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'RedIncapacitate':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(RedIncapacitateFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'TeamKill':
			TypeOut = WebAdminMessageType.MessageType_TeamKill;
			MsgOut = FormatTextString(TeamKillFormat, StrA, StrB, GetWeaponFriendlyName(StrC));
			break;
		case 'BlueArrest':
			TypeOut = WebAdminMessageType.MessageType_Arrest;
			MsgOut = FormatTextString(BlueArrestFormat, StrA, StrB);
			break;
		case 'RedArrest':
			TypeOut = WebAdminMessageType.MessageType_Arrest;
			MsgOut = FormatTextString(RedArrestFormat, StrA, StrB);
			break;
		case 'PlayerConnect':
			TypeOut = WebAdminMessageType.MessageType_PlayerJoin;
			MsgOut = FormatTextString(ConnectFormat, StrA);
			break;
		case 'PlayerDisconnect':
			TypeOut = WebAdminMessageType.MessageType_PlayerJoin;
			MsgOut = FormatTextString(DisconnectFormat, StrA);
			break;
		case 'RoundStarted':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = RoundStartedFormat;
			break;
		case 'RoundEnded':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = RoundEndedFormat;
			break;
		case 'MissionEnded':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = MissionEndedFormat;
			break;
		case 'MissionFailed':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = MissionFailedFormat;
			break;
		case 'MissionCompleted':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = MissionCompletedFormat;
			break;
		case 'WebAdminLeft':
			TypeOut = WebAdminMessageType.MessageType_AdminLeave;
			MsgOut = FormatTextString(LeftWebAdminFormat, Msg);
			break;
		case 'Kick':
			TypeOut = WebAdminMessageType.MessageType_PlayerJoin;
			MsgOut = FormatTextString(KickFormat, StrB, StrA);
			break;
		case 'KickBan':
			TypeOut = WebAdminMessageType.MessageType_PlayerJoin;
			MsgOut = FormatTextString(KickBanFormat, StrB, StrA);
			break;
		case 'ObjectiveComplete':
			TypeOut = WebAdminMessageType.MessageType_Round;
			MsgOut = FormatTextString(ObjectiveCompleteFormat, StrA);
			break;
		case 'ForceTeamRed':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForceAllRedFormat, StrA);
			break;
		case 'ForceTeamBlue':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForceAllBlueFormat, StrA);
			break;
		case 'ForcePlayerRed':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForcePlayerRedFormat, StrA, StrB);
			break;
		case 'ForcePlayerBlue':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(ForcePlayerBlueFormat, StrA, StrB);
			break;
		case 'LockTeams':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(LockedTeamsFormat, StrA);
			break;
		case 'UnlockTeams':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(UnlockedTeamsFormat, StrA);
			break;
		case 'LockPlayerTeam':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(LockedPlayerTeamFormat, StrA, StrB);
			break;
		case 'UnlockPlayerTeam':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(UnlockedPlayerTeamFormat, StrA, StrB);
			break;
		case 'Mute':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(MuteFormat, StrA, StrB);
			break;
		case 'Unmute':
			TypeOut = WebAdminMessageType.MessageType_Chat;
			MsgOut = FormatTextString(UnmuteFormat, StrA, StrB);
			break;
		case 'AdminKill':
			TypeOut = WebAdminMessageType.MessageType_Kill;
			MsgOut = FormatTextString(AdminKillFormat, StrA, StrB);
			break;
		case 'AdminLeader':
			TypeOut = WebAdminMessageType.MessageType_SwitchTeams;
			MsgOut = FormatTextString(AdminPromotedFormat, StrA, StrB);
			break;
	}

	SendToWebAdmin(TypeOut, MsgOut);
	LogChat(MsgOut);
}

// Send a message to WebAdmin
private function SendToWebAdmin(WebAdminMessageType Type, coerce string Msg)
{
	if(WebAdmin != None)
	{
		WebAdmin.SendWebAdminMessage(Type, Msg);
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
	SayFormat="[c=00FF00][b]%1:[\\b] %2"
	TeamSayFormat="[c=777777][b]%1:[\\b] %2"
	SwitchTeamsFormat="[c=00FFFF][b]%1[\\b] switched teams."
	NameChangeFormat="[c=FF00FF][b]%1[\\b] changed their name to [b]%2[\\b]"
	VoteStartedFormat="[c=FF00FF]%1"
	YesVoteFormat="[c=FF00FF]%1 voted yes."
	NoVoteFormat="[c=FF00FF]%1 voted no."
	VoteSuccessfulFormat="[c=FF00FF]The vote was successful."
	VoteFailedFormat="[c=FF00FF]The vote failed."
	RedSuicideFormat="[c=FF0000][b]%1[\\b] committed suicide."
	BlueSuicideFormat="[c=3333FF][b]%1[\\b] committed suicide."
	RedKillFormat="[c=FF0000][b]%1[\\b] killed [b]%2[\\b] with %3"
	BlueKillFormat="[c=3333FF][b]%1[\\b] killed [b]%2[\\b] with %3"
	TeamKillFormat="[c=EC832F][b]%1[\\b] TEAM-KILLED [b]%2[\\b] with %3"
	FallenFormat="[c=EC832F][b]%1[\\b] has fallen"
	ConnectFormat="[c=00FFFF][b]%1[\\b] connected to game server."
	DisconnectFormat="[c=00FFFF][b]%1[\\b] disconnected from game server."
	RedArrestFormat="[c=FF0000][b]%1[\\b] arrested [b]%2[\\b]"
	BlueArrestFormat="[c=3333FF][b]%1[\\b] arrested [b]%2[\\b]"
	RedIncapacitateFormat="[c=FF0000][b]%1[\\b] incapacitated [b]%2[\\b] with %3"
	BlueIncapacitateFormat="[c=3333FF][b]%1[\\b] incapacitated [b]%2[\\b] with %3"
	KickFormat="[c=FF00FF][b]%1[\\b] was kicked by [b]%2[\\b]"
	KickBanFormat="[c=FF00FF][b]%1[\\b] was banned by [b]%2[\\b]"
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
	RoundStartedFormat="[c=FFFF00]The round has started.[\\b]"
	RoundEndedFormat="[c=FFFF00]The round has ended.[\\b]"
	MissionEndedFormat="[c=FFFF00]The mission has ended.[\\b]"
	MissionCompletedFormat="The mission has been [c=00FF00][b]COMPLETED!"
	MissionFailedFormat="The mission has been [c=FF0000][b]FAILED!"
	LeftWebAdminFormat="[c=00FFFF][b]%1[\\b] has left WebAdmin."

	ChatLogName="chatlog"
	ChatLogMultiFormat="chatlog_%1_%2_%3"
}
