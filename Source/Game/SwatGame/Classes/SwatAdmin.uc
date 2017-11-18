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

var public config bool UseAdminLog;
var private FileLog AdminLog;
var public config bool SanitizeAdminLog;

var private array<SwatGamePlayerController> MutedPlayers;

var private localized config string PenaltyFormat;
var private localized config string SayFormat;
var private localized config string SwitchTeamsFormat;
var private localized config string NameChangeFormat;
var private localized config string YesVoteFormat;
var private localized config string NoVoteFormat;
var private localized config string SuicideFormat;
var private localized config string KillFormat;
var private localized config string TeamKillFormat;
var private localized config string ArrestFormat;
var private localized config string ConnectFormat;
var private localized config string DisconnectFormat;
var private localized config string KickFormat;
var private localized config string KickBanFormat;
var private localized config string IncapacitateFormat;
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

	if(UseAdminLog)
	{
		AdminLog = Spawn(class'FileLog');

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

	if(AdminLog != None)
	{
		AdminLog.Destroy();
		AdminLog = None;
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
	} until(i != -1);
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
		ChatLog.OpenLog("chatlog_"$Level.Year$"_"$Level.Month$"_"$Level.Day);
		ChatLog.Logf("["$Level.Day$"/"$Level.Month$"/"$Level.Year$" "$Level.Hour$":"$Level.Minute$":"$Level.Second$"] "$Message);
		ChatLog.CloseLog();
	}
}

// Log an action to the administrator log
function LogAdmin(string Message)
{
	if(UseAdminLog)
	{
		if(SanitizeAdminLog)
		{
			SanitizeLogMessage(Message);
		}
		AdminLog.OpenLog("adminlog_"$Level.Year$"_"$Level.Month$"_"$Level.Day);
		AdminLog.Logf("["$Level.Day$"/"$Level.Month$"/"$Level.Year$" "$Level.Hour$":"$Level.Minute$":"$Level.Second$"] "$Message);
		AdminLog.CloseLog();
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

	StrA = GetFirstField(Msg,"\t");
    StrB = GetFirstField(Msg,"\t");
    StrC = GetFirstField(Msg,"\t");

	switch(Type)
	{
		case 'PenaltyIssuedChat':
			SendToWebAdmin(WebAdminMessageType.MessageType_Penalty, FormatTextString(PenaltyFormat, StrA, StrB));
			break;
		case 'TeamSay':
			SendToWebAdmin(WebAdminMessageType.MessageType_Chat, FormatTextString(SayFormat, StrA, StrB));
			LogChat(FormatTextString(SayFormat, StrA, StrB));
			break;
		case 'Say':
			SendToWebAdmin(WebAdminMessageType.MessageType_Chat, FormatTextString(SayFormat, StrA, StrB));
			LogChat(FormatTextString(SayFormat, StrA, StrB));
			break;
		case 'WebAdminChat':
			SendToWebAdmin(WebAdminMessageType.MessageType_Chat, FormatTextString(SayFormat, StrA, StrB));
			LogChat(FormatTextString(SayFormat, StrA, StrB));
			break;
		case 'SayLocalized':
			SendToWebAdmin(WebAdminMessageType.MessageType_Chat, FormatTextString(SayFormat, StrA, StrB));
			LogChat(FormatTextString(SayFormat, StrA, StrB));
			break;
		case 'TeamSayLocalized':
			SendToWebAdmin(WebAdminMessageType.MessageType_Chat, FormatTextString(SayFormat, StrA, StrB));
			LogChat(FormatTextString(SayFormat, StrA, StrB));
			break;
		case 'SwitchTeams':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(SwitchTeamsFormat, StrA));
			break;
		case 'NameChange':
			SendToWebAdmin(WebAdminMessageType.MessageType_NameChange, FormatTextString(NameChangeFormat, StrA, StrB));
			break;
		case 'CommandGiven':
			SendToWebAdmin(WebAdminMessageType.MessageType_Chat, Msg);
			break;
		case 'YesVote':
			SendToWebAdmin(WebAdminMessageType.MessageType_Voting, FormatTextString(YesVoteFormat, StrA));
			break;
		case 'NoVote':
			SendToWebAdmin(WebAdminMessageType.MessageType_Voting, FormatTextString(NoVoteFormat, StrA));
			break;
		case 'ReferendumStarted':
			SendToWebAdmin(WebAdminMessageType.MessageType_Voting, Msg);
			break;
		case 'ReferendumSucceeded':
			SendToWebAdmin(WebAdminMessageType.MessageType_Voting, "The vote succeeded.");
			break;
		case 'ReferendumFailed':
			SendToWebAdmin(WebAdminMessageType.MessageType_Voting, "The vote failed.");
			break;
		case 'BlueSuicide':
		case 'RedSuicide':
			SendToWebAdmin(WebAdminMessageType.MessageType_Kill, FormatTextString(SuicideFormat, StrA));
			break;
		case 'BlueKill':
		case 'RedKill':
			SendToWebAdmin(WebAdminMessageType.MessageType_Kill, FormatTextString(KillFormat, StrA, StrB, StrC));
			break;
		case 'BlueIncapacitate':
		case 'RedIncapacitate':
			SendToWebAdmin(WebAdminMessageType.MessageType_Kill, FormatTextString(IncapacitateFormat, StrA, StrB, StrC));
			break;
		case 'TeamKill':
			SendToWebAdmin(WebAdminMessageType.MessageType_TeamKill, FormatTextString(TeamKillFormat, StrA, StrB, StrC));
			break;
		case 'BlueArrest':
		case 'RedArrest':
			SendToWebAdmin(WebAdminMessageType.MessageType_Arrest, FormatTextString(ArrestFormat, StrA, StrB));
			break;
		case 'PlayerConnect':
			SendToWebAdmin(WebAdminMessageType.MessageType_PlayerJoin, FormatTextString(ConnectFormat, StrA));
			break;
		case 'PlayerDisconnect':
			SendToWebAdmin(WebAdminMessageType.MessageType_PlayerJoin, FormatTextString(DisconnectFormat, StrA));
			break;
		case 'RoundStarted':
			SendToWebAdmin(WebAdminMessageType.MessageType_Round, "The round has started.");
			break;
		case 'RoundEnded':
			SendToWebAdmin(WebAdminMessageType.MessageType_Round, "The round has ended.");
			break;
		case 'MissionEnded':
			SendToWebAdmin(WebAdminMessageType.MessageType_Round, "The mission has ended.");
			break;
		case 'MissionFailed':
			SendToWebAdmin(WebAdminMessageType.MessageType_Round, "The mission has been FAILED!");
			break;
		case 'MissionCompleted':
			SendToWebAdmin(WebAdminMessageType.MessageType_Round, "The mission has been COMPLETED!");
			break;
		case 'WebAdminLeft':
			SendToWebAdmin(WebAdminMessageType.MessageType_AdminLeave, Msg$" has left WebAdmin.");
			break;
		case 'Kick':
			SendToWebAdmin(WebAdminMessageType.MessageType_PlayerJoin, FormatTextString(KickFormat, StrB, StrA));
			LogAdmin(FormatTextString(KickFormat, StrB, StrA));
			break;
		case 'KickBan':
			SendToWebAdmin(WebAdminMessageType.MessageType_PlayerJoin, FormatTextString(KickBanFormat, StrB, StrA));
			LogAdmin(FormatTextString(KickBanFormat, StrB, StrA));
			break;
		case 'ObjectiveComplete':
			SendToWebAdmin(WebAdminMessageType.MessageType_Round, FormatTextString(ObjectiveCompleteFormat, StrA));
			break;
		case 'ForceTeamRed':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(ForceAllRedFormat, StrA));
			LogAdmin(FormatTextString(ForceAllRedFormat, StrA));
			break;
		case 'ForceTeamBlue':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(ForceAllBlueFormat, StrA));
			LogAdmin(FormatTextString(ForceAllBlueFormat, StrA));
			break;
		case 'ForcePlayerRed':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(ForcePlayerRedFormat, StrA, StrB));
			LogAdmin(FormatTextString(ForcePlayerRedFormat, StrA, StrB));
			break;
		case 'ForcePlayerBlue':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(ForcePlayerBlueFormat, StrA, StrB));
			LogAdmin(FormatTextString(ForcePlayerBlueFormat, StrA, StrB));
			break;
		case 'LockTeams':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(LockedTeamsFormat, StrA));
			LogAdmin(FormatTextString(LockedTeamsFormat, StrA));
			break;
		case 'UnlockTeams':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(UnlockedTeamsFormat, StrA));
			LogAdmin(FormatTextString(UnlockedTeamsFormat, StrA));
			break;
		case 'LockPlayerTeam':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(LockedPlayerTeamFormat, StrA, StrB));
			LogAdmin(FormatTextString(LockedPlayerTeamFormat, StrA, StrB));
			break;
		case 'UnlockPlayerTeam':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(UnlockedPlayerTeamFormat, StrA, StrB));
			LogAdmin(FormatTextString(UnlockedPlayerTeamFormat, StrA, StrB));
			break;
		case 'Mute':
			SendToWebAdmin(WebAdminMessageType.MessageType_Chat, FormatTextString(MuteFormat, StrA, StrB));
			LogAdmin(FormatTextString(MuteFormat, StrA, StrB));
			break;
		case 'Unmute':
			SendToWebAdmin(WebAdminMessageType.MessageType_Chat, FormatTextString(UnmuteFormat, StrA, StrB));
			LogAdmin(FormatTextString(UnmuteFormat, StrA, StrB));
			break;
		case 'AdminKill':
			SendToWebAdmin(WebAdminMessageType.MessageType_Kill, FormatTextString(AdminKillFormat, StrA, StrB));
			LogAdmin(FormatTextString(AdminKillFormat, StrA, StrB));
			break;
		case 'AdminLeader':
			SendToWebAdmin(WebAdminMessageType.MessageType_SwitchTeams, FormatTextString(AdminPromotedFormat, StrA, StrB));
			LogAdmin(FormatTextString(AdminPromotedFormat, StrA, StrB));
			break;
	}
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
	UseAdminLog=true
	SanitizeChatLog=true
	SanitizeAdminLog=true

	PenaltyFormat="%1 caused penalty: %2"
	SayFormat="%1: %2"
	SwitchTeamsFormat="%1 switched teams."
	NameChangeFormat="%1 changed their name to %2"
	YesVoteFormat="%1 voted yes."
	NoVoteFormat="%1 voted no."
	SuicideFormat="%1 committed suicide."
	KillFormat="%1 killed %2 with %3"
	TeamKillFormat="%1 TEAM-KILLED %2 with %3"
	ConnectFormat="%1 connected to game server."
	DisconnectFormat="%1 disconnected from game server."
	ArrestFormat="%1 arrested %2"
	IncapacitateFormat="%1 incapacitated %2 with %3"
	KickFormat="%1 was kicked by %2"
	KickBanFormat="%1 was kick-banned by %2"
	ObjectiveCompleteFormat="Objective Complete: %1"
	LockedTeamsFormat="%1 locked the teams."
	UnlockedTeamsFormat="%1 unlocked the teams."
	LockedPlayerTeamFormat="%1 locked %2's team."
	UnlockedPlayerTeamFormat="%1 unlocked %2's team."
	ForceAllRedFormat="%1 forced all players to be on the red team."
	ForceAllBlueFormat="%1 forced all players to be on the blue team."
	ForcePlayerRedFormat="%1 forced %2 to be on the red team."
	ForcePlayerBlueFormat="%1 forced %2 to be on the blue team."
	MuteFormat="%1 muted %2."
	UnmuteFormat="%1 un-muted %2."
	AdminKillFormat="%1 killed %2."
	AdminPromotedFormat="%1 promoted %2 to leader."
}
