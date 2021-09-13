class SwatWebAdminListener extends IPDrv.TCPLink
	transient
	config(SwatGuiState)
	dependsOn(SwatAdmin);

import enum AdminPermissions from SwatAdmin;
import enum WebAdminMessageType from SwatAdmin;
import enum COOPStatus from SwatGame.SwatPlayerReplicationInfo;

struct WebAdminMessage
{
	var WebAdminMessageType MessageType;
	var string Message;
};

struct WebAdminUser
{
	var string Alias;
	var string Cookie;
	var string IP;
	var bool GuestUser;
	var int KeepAlive;
	var SwatAdminPermissions PermissionSet;
	var array<WebAdminMessage> WaitingMessages;
};

var globalconfig bool DebugWebAdmin;
var globalconfig int KeepAliveTime;
var globalconfig string PageHeader;
var globalconfig string PageStyle;
var globalconfig string PageFooter;
var globalconfig float ClientRefreshSeconds;
var globalconfig float ServerRefreshSeconds;

var globalconfig bool FormatHTML;

var localized config string NoPermissionString;
var localized config string NotEnoughArgsString;

var private int BoundPort;
var globalconfig array<WebAdminUser> Users;

var globalconfig localized string NotReadyString;
var globalconfig localized string ReadyString;
var globalconfig localized string HealthyString;
var globalconfig localized string InjuredString;
var globalconfig localized string IncapacitatedString;
var globalconfig localized string LeaderString;
var globalconfig localized string NotAvailableString;

//////////////////////////////////////////////////////////////////
//
//	Main entrypoint for the listener, the host for all WebAdmin connections

function BeginPlay()
{
	local int DefaultPort;

	DefaultPort = class'SwatAdmin'.default.WebAdminPort;
	if(DefaultPort == 0)
	{
		Destroy();
		return;
	}

	BoundPort = BindPort(DefaultPort, true);
	if(BoundPort == 0)
	{
		mplog("WebAdmin: Couldn't bind to port "$DefaultPort);
		Destroy();
		return;
	}

	if(Listen())
	{
		mplog("WebAdmin: Now listening on port "$BoundPort);
	}
	else
	{
		mplog("WebAdmin: Couldn't listen on port "$DefaultPort);
		Destroy();
		return;
	}

	AcceptClass = class'SwatWebAdmin';
	SetTimer(ServerRefreshSeconds, true);
}

private function string GetStatusString( COOPStatus status )
{
	local SwatGuiConfig GC;

	GC = SwatRepo(Level.GetRepo()).GuiConfig;
    switch(status)
    {
        case STATUS_NotReady:
            if( GC.SwatGameState != GAMESTATE_MidGame )
                return NotReadyString;
            else
                return NotAvailableString;
        case STATUS_Ready:
            if( GC.SwatGameState != GAMESTATE_MidGame )
                return ReadyString;
            else
                return NotAvailableString;
        case STATUS_Healthy:
            return HealthyString;
        case STATUS_Injured:
            return InjuredString;
        case STATUS_Incapacitated:
            return IncapacitatedString;
    }

    return "";
}

// The timer on this class is responsible for checking whether or not to keep the admins alive.
event Timer()
{
	local int i;

	for(i = Users.Length - 1; i >= 0; i--)	// loop backwards so we don't die when removing a user
	{
		if(float(Users[i].KeepAlive + KeepAliveTime) < Level.TimeSeconds)
		{
			if(Users[i].Alias != "")
			{
				mplog("WebAdmin: Logged "$Users[i].Alias$" out due to timeout");
			}
			Users.Remove(i, 1);
		}
	}
}

// When we spawn something, make sure to set us as the listener!!
event GainedChild(Actor Child)
{
	Super.GainedChild(Child);

	SwatWebAdmin(Child).Listener = self;

	if(DebugWebAdmin)
	{
		mplog("WebAdmin: Connection attempt ");
	}
}

// Converts the local IP address into a string
function string GetLocalAddress()
{
	local IpAddr Addr;

	GetLocalIP(Addr);

	return IpAddrToString(Addr);
}

// Checks to see if an alias is in use. If it is, return true.
function bool AliasInUse(string Alias)
{
	local int i;
	for(i = 0; i < Users.Length; i++)
	{
		if(Users[i].Alias ~= Alias)
		{
			return true;
		}
	}

	return false;
}

// Generates a random 16-letter token
function string GenerateGUID()
{
	local int i;
	local string OutValue;
	local int x;

	// Create a 16 character-long string.
	for(i = 0; i < 16; i++)
	{
		// Generate a random digit, 0-51.
		// If it's > 25, it's an uppercase letter - otherwise it's lowercase
		x = Rand(50);
		if(x > 25)
		{
			x += 45;
		}
		else
		{
			x += 97;
		}
		OutValue = OutValue $ Chr(x);
	}

	return OutValue;
}

// Tries to login the specified user, and returns the cookie back
// Precondition: The alias is already assumed to not be in use
function string LoginUser(string Alias, SwatAdminPermissions Permissions, IpAddr IP, bool GuestUser)
{
	local WebAdminUser User;

	User.Alias = Alias;
	User.KeepAlive = Level.TimeSeconds;
	User.PermissionSet = Permissions;
	User.Cookie = GenerateGUID();
	User.IP = IpAddrToString(IP);
	User.GuestUser = GuestUser;

	Users[Users.Length] = User;

	return User.Cookie;
}

// Tries to log out the specified user cookie
function bool LogoutUser(string Cookie)
{
	local int i;

	for(i = 0; i < Users.Length; i++)
	{
		if(Cookie == Users[i].Cookie)
		{
			SwatGameInfo(Level.Game).Broadcast(self, Users[i].Alias, 'WebAdminLeft');
			Users.Remove(i, 1);
			return true;
		}
	}
	return false;
}

// CHecks to see if a user cookie is logged in
function bool LoggedIn(string Cookie)
{
	local int i;

	for(i = 0; i < Users.Length; i++)
	{
		if(Cookie == Users[i].Cookie)
		{
			return true;
		}
	}
	return false;
}

function bool GetUserData(string Cookie, optional out string Alias, optional out SwatAdminPermissions Permissions)
{
	local int i;

	for(i = 0; i < Users.Length; i++)
	{
		if(Cookie == Users[i].Cookie)
		{
			Alias = Users[i].Alias;
			Permissions = Users[i].PermissionSet;
			return true;
		}
	}
	return false;
}

// We get polled every 5 seconds by each client
function bool Polled(SwatWebAdmin AdminClient, string Cookie, string NewUser, string NewPass, bool NewGuest, IpAddr NewIP)
{
	local int i;
	local int j;
	local string XML;
	local SwatGameReplicationInfo SGRI;
	local SwatPlayerReplicationInfo PRI;
	local string NewCookie;
	local SwatAdminPermissions Perms;
	local string Name;
	local string StatusText;
	local ServerSettings Settings;

	Settings = ServerSettings(Level.CurrentServerSettings);
	SGRI = SwatGameReplicationInfo(Level.Game.GameReplicationInfo);

	for(i = 0; i < Users.Length; i++)
	{
		if(Cookie == Users[i].Cookie)
		{
			Users[i].KeepAlive = Level.TimeSeconds + KeepAliveTime;

			XML = "<POLLDATA>";

			log("Poll - Server name is "$Settings.ServerName$" and map is "$Settings.Maps[Settings.MapIndex]);

			XML = XML $ "<SERVER>";
			XML = XML $ "<NAME>" $ Settings.ServerName $ "</NAME>";
			XML = XML $ "<MAP>" $ Settings.Maps[Settings.MapIndex] $ "</MAP>";
			XML = XML $ "</SERVER>";

			XML = XML $ "<USERS>";
			for(j = 0; j < ArrayCount(SGRI.PRIStaticArray); j++)
			{
				PRI = SGRI.PRIStaticArray[j];
				if(PRI == None)
				{
					continue;
				}

				Name = PRI.PlayerName;
				FixHTMLBolding(Name);
				FixHTMLItalics(Name);
				FixHTMLUnderline(Name);
				FixHTMLColor(Name);

				XML = XML $ "<USER>";
				XML = XML $ "<NAME><![CDATA[" $ Name $ "]]></NAME>";
				XML = XML $ "<TEAM>"$NetTeam(PRI.Team).GetTeamNumber()$"</TEAM>";

				StatusText = GetStatusString(PRI.COOPPlayerStatus);
				if ( PRI.COOPPlayerStatus != STATUS_Incapacitated && PRI.IsLeader )
				{
					StatusText = StatusText $ LeaderString;
				}

				FixHTMLBolding(StatusText);
				FixHTMLItalics(StatusText);
				FixHTMLUnderline(StatusText);
				FixHTMLColor(StatusText);
				XML = XML $ "<STATUS><![CDATA["$StatusText$"]]></STATUS>";

				XML = XML $ "</USER>";

			}
			XML = XML $ "</USERS>";

			XML = XML $ "<ADMINS>";
			for(j = 0; j < Users.Length; j++)
			{
				Name = Users[j].Alias;
				FixHTMLBolding(Name);
				FixHTMLItalics(Name);
				FixHTMLUnderline(Name);
				FixHTMLColor(Name);

				XML = XML $ "<ADMIN>";
				XML = XML $ "<ALIAS><![CDATA[" $ Name $ "]]></ALIAS>";
				XML = XML $ "<ROLE>" $ Users[i].PermissionSet.PermissionSetName $ "</ROLE>";
				XML = XML $ "</ADMIN>";
			}
			XML = XML $ "</ADMINS>";

			XML = XML $ "<MSGS>";
			for(j = 0; j < Users[i].WaitingMessages.Length; j++)
			{
				XML = XML $ "<MSG>";
				XML = XML $ "<MSGTYPE>" $ Users[i].WaitingMessages[j].MessageType $ "</MSGTYPE>";

				// Use CDATA for messages because we can expect some HTML in them
				XML = XML $ "<MSGTEXT><![CDATA[" $ Users[i].WaitingMessages[j].Message $ "]]></MSGTEXT>";
				XML = XML $ "</MSG>";
			}
			Users[i].WaitingMessages.Length = 0;
			XML = XML $ "</MSGS>";

			XML = XML $ "</POLLDATA>";
			AdminClient.SendXML(XML);
			return true;
		}
	}

	// The user wasn't found. Try to log us in with the previous credentials
	if(NewGuest)
	{
		Perms = SwatGameInfo(Level.Game).Admin.GuestPermissions;
	}
	else
	{
		Perms = SwatGameInfo(Level.Game).Admin.FindRole(NewPass);
		if(Perms == None)
		{
			return false;
		}
	}

	NewCookie = LoginUser(NewUser, Perms, NewIP, NewGuest);
	AdminClient.SetCookie(NewCookie);

	return false;
}

// Fix bold tags on a string
function FixHTMLBolding(out string Text)
{
	if(!FormatHTML)
	{
		return;
	}

	ReplaceText(Text, "[B]", "[b]");
	ReplaceText(Text, "[b]", "</b><b>");
	ReplaceText(Text, "[\\B]", "[\\b]");
	ReplaceText(Text, "[\\b]", "</b>");
	Text = Text $ "</b>";
}

// Fix italic tags on a string
function FixHTMLItalics(out string Text)
{
	if(!FormatHTML)
	{
		return;
	}

	ReplaceText(Text, "[I]", "[i]");
	ReplaceText(Text, "[i]", "</i><i>");
	ReplaceText(Text, "[\\I]", "[\\i]");
	ReplaceText(Text, "[\\i]", "</i>");
	Text = Text $ "</i>";
}

// Fix underline tags on a string
function FixHTMLUnderline(out string Text)
{
	if(!FormatHTML)
	{
		return;
	}

	ReplaceText(Text, "[U]", "[u]");
	ReplaceText(Text, "[u]", "</u><u>");
	ReplaceText(Text, "[\\U]", "[\\u]");
	ReplaceText(Text, "[\\u]", "</u>");
	Text = Text $ "</u>";
}

// Fix coloring tags on a string
function FixHTMLColor(out string Text)
{
	local int i, j;

	if(!FormatHTML)
	{
		return;
	}

	ReplaceText(Text, "[C=", "[c=");
	ReplaceText(Text, "[\\C]", "[\\c]");
	ReplaceText(Text, "[\\c]", "</font>");

	do
	{
		i = InStr(Text, "[c=");
		if(i != -1)
		{
			j = InStrAfter(Text, "]", i);
			if(j == -1)
			{
				i = -1;
			}
			else
			{
				Text = Left(Text, i) $ "</font><font color=" $ Mid(Text, i + 3, 6) $ ">" $ Mid(Text, j + 1);
			}
		}
	} until(i == -1);

	Text = Text $ "</font>";
}

// Send a message to a specific user
function SendMessageToUser(int User, WebAdminMessage Message)
{
	// Make sure user is valid. Sometimes we call this with bad parameters on purpose
	if(User < 0 || User >= Users.Length)
	{
		return;
	}
	
	// Cleanse the message
	// Remove < and > because this can cause HTML injection
	ReplaceText(Message.Message, "<", "&lt;");
	ReplaceText(Message.Message, ">", "&gt;");

	// Wrap any text that's in [B] or [b] in <b> tags
	FixHTMLBolding(Message.Message);

	// Wrap any text that's in [I] or [i] in <i> tags
	FixHTMLItalics(Message.Message);

	// Wrap any text that's in [U] or [u] in <u> tags
	FixHTMLUnderline(Message.Message);

	// Wrap any text that's in [C=COLOUR] in <font color=colour> tag
	FixHTMLColor(Message.Message);

	log("SendMessageToUser: User is "$User$", Message.Message is "$Message.Message);

	// Send it
	Users[User].WaitingMessages[Users[User].WaitingMessages.Length] = Message;
}

// We got sent some command from a webadmin
// NOTE: If User is -1, and AnonymousAlias/AnonymousPermissions is set, we can send commands without having to login!
function SentCommand(SwatWebAdmin AdminClient, int User, string Content, optional string AnonymousAlias, optional SwatAdminPermissions AnonymousPermissions, optional string AnonymousIP)
{
	local array<string> argv;
	local WebAdminMessage msg;
	local string Alias;
	local string IngameName;
	local int i;
	local SwatAdminPermissions Perms;
	local string IPString;

	if(i == -1)
	{
		Alias = AnonymousAlias;
		IngameName = Alias;
		Perms = AnonymousPermissions;
		IPString = AnonymousIP;
	}
	else
	{
		i = User;
		Alias = Users[i].Alias;

		if(Users[i].GuestUser)
		{
			IngameName = Alias$"(WebGuest)";
		}
		else
		{
			IngameName = Alias$"(WebAdmin)";
		}

		Perms = Users[i].PermissionSet;
		IPString = Users[i].IP;
	}


	Split(Content, " ", argv);

	msg.MessageType = WebAdminMessageType.MessageType_WebAdminError;

	// perform command based on the first argument
	if(argv[0] ~= "kick")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_Kick))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /kick <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!Level.Game.RemoteKick(IngameName, ConcatArgs(argv, 1), IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "ban" || argv[0] ~= "kickban")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_KickBan))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /"$argv[0]$" <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!Level.Game.RemoteKickBan(IngameName, ConcatArgs(argv, 1), IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "lockvotes" || argv[0] ~= "unlockvotes" || 
		argv[0] ~= "lockvoting" || argv[0] ~= "unlockvoting" ||
		argv[0] ~= "togglevotelock")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_LockVoting))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else
		{
			SwatGameInfo(Level.Game).RemoteLockVoting(IngameName, IPString);
		}
	}
	else if(argv[0] ~= "lockvoter" || argv[0] ~= "unlockvoter" || argv[0] ~= "togglevoterlock")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_LockVoter))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /"$argv[0]$" <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).RemoteLockVoter(IngameName, ConcatArgs(argv, 1), IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv,1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "lockteams" || argv[0] ~= "unlockteams" || argv[0] ~= "toggleteamlock")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_LockTeams))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else
		{
			SwatGameInfo(Level.Game).RemoteLockTeams(IngameName, IPString);
		}
	}
	else if(argv[0] ~= "lockplayerteam" || argv[0] ~= "unlockplayerteam" || argv[0] ~= "toggleplayerteamlock")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_LockPlayerTeams))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /"$argv[0]$" <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).RemoteLockPlayerTeam(IngameName, ConcatArgs(argv, 1), IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "alltored" || argv[0] ~= "forceallred" || argv[0] ~= "forceredall")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_ForceAllTeams))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else
		{
			SwatGameInfo(Level.Game).RemoteForceAllToTeam(IngameName, 2, IPString);
		}
	}
	else if(argv[0] ~= "alltoblue" || argv[0] ~= "forceallblue" || argv[0] ~= "forceblueall")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_ForceAllTeams))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else
		{
			SwatGameInfo(Level.Game).RemoteForceAllToTeam(IngameName, 0, IPString);
		}
	}
	else if(argv[0] ~= "forcered")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_ForcePlayerTeam))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /forcered <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).RemoteForcePlayerTeam(IngameName, ConcatArgs(argv, 1), 2, IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "forceblue")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_ForcePlayerTeam))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /forceblue <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).RemoteForcePlayerTeam(IngameName, ConcatArgs(argv, 1), 0, IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "mute" || argv[0] ~= "unmute" || argv[0] ~= "togglemute")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_Mute))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /"$argv[0]$" <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).RemoteMute(IngameName, ConcatArgs(argv, 1), IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "kill")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_KillPlayers))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /kill <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).ForcePlayerDeath(None, ConcatArgs(argv, 1), IngameName, IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "promote")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_PromoteLeader))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /promote <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).ForcePlayerPromotion(None, ConcatArgs(argv, 1), IngameName, IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "forcespec")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_ForceSpectator))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /forcespec <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).Admin.ForceSpec(ConcatArgs(argv, 1), None, IngameName, IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "forcell")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_ForceLessLethal))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /forcell <player name>";
			SendMessageToUser(i, msg);
		}
		else if(!SwatGameInfo(Level.Game).Admin.ForceLL(ConcatArgs(argv, 1), None, IngameName, IPString))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			SendMessageToUser(i, msg);
		}
	}
	else if(argv[0] ~= "switch")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_Switch))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else if(argv.length < 2)
		{
			msg.Message = NotEnoughArgsString;
			SendMessageToUser(i, msg);
			msg.Message = "usage: /switch <map name>";
			SendMessageToUser(i, msg);
		}
		else
		{
			Level.ServerTravel( argv[1], false );
		}
	}
	else if(argv[0] ~= "nextmap")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_Switch))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else
		{
			SwatRepo(Level.GetRepo()).NetSwitchLevels(true);
		}
	}
	else if(argv[0] ~= "startgame")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_StartGame))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else
		{
			SwatRepo(Level.GetRepo()).AllPlayersReady();
		}
	}
	else if(argv[0] ~= "abortgame")
	{
		if(!Perms.GetPermission(AdminPermissions.Permission_EndGame))
		{
			msg.Message = NoPermissionString;
			SendMessageToUser(i, msg);
		}
		else
		{
			SwatGameInfo(Level.Game).GameAbort();
		}
	}
	else
	{
		msg.Message = "Unknown command '"$argv[0]$"'";
		SendMessageToUser(i, msg);
	}
}

// We got sent some chat from a webadmin
function SentChat(SwatWebAdmin AdminClient, int User, string Content)
{
	local string Alias;
	local WebAdminMessage Msg;
	local string IP;

	Alias = Users[User].Alias;
	IP = Users[User].IP;

	if(Users[User].GuestUser)
	{
		Alias = Alias $ "(WebGuest)";
	}
	else
	{
		Alias = Alias $ "(WebAdmin)";
	}

	if(!Users[User].PermissionSet.GetPermission(AdminPermissions.Permission_WebAdminChat))
	{
		Msg.MessageType = WebAdminMessageType.MessageType_WebAdminError;
		Msg.Message = NoPermissionString;
		SendMessageToUser(User, Msg);
		return;
	}

	// broadcast it?
	SwatGameInfo(Level.Game).Broadcast(self, Alias$"\t"$Content, 'WebAdminChat');
	Level.Game.AdminLog(Alias$"\t"$Content, 'WebAdminChat', IP);
}

// We get sent data whenever a webadmin decides to
function bool SentData(SwatWebAdmin AdminClient, string Cookie, string Content)
{
	local int i;

	for(i = 0; i < Users.Length; i++)
	{
		if(Cookie == Users[i].Cookie)
		{
			if(Asc(Content) == 47)
			{
				// first character is a slash - process as command
				SentCommand(AdminClient, i, Mid(Content, 1));
			}
			else
			{
				// send as chat from webadmin
				SentChat(AdminClient, i, Content);
			}
			Users[i].KeepAlive = Level.TimeSeconds + KeepAliveTime;
			AdminClient.SendXML("");
			return true;
		}
	}

	return false;
}

// Send a text message to all WebAdmin users.
function SendWebAdminMessage(WebAdminMessageType type, optional string Message, optional string MessageWithIP)
{
	local WebAdminMessage msg;
	local int i;

	msg.MessageType = type;

	for(i = 0; i < Users.Length; i++)
	{
		// on some users, we send the message
		// on some users, with send the message with the IP
		// it depends on whether they have the "View IPs" permission on their account
		if(Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_ViewIPs))
		{
			msg.Message = MessageWithIP;
		}
		else
		{
			msg.Message = Message;
		}

		SendMessageToUser(i, msg);
	}
}

event Closed()
{
	mplog("WebAdmin closed");
	SaveConfig();
}

defaultproperties
{
	KeepAliveTime=30
	DebugWebAdmin=false

	ClientRefreshSeconds=3.0
	ServerRefreshSeconds=1.0

	FormatHTML = true

	//
	// Styles:
	// - sty_statictext: Used for static blurbs of text
	// - sty_title: Used for the big title at the top
	// - sty_subtitle: Used for smaller titles
	// - sty_error: Used for text that is displayed in error messages (should be red, etc)
	// - sty_layouttable: Used for tables with invisible edges
	// - sty_textarea: Used for the WebAdmin console
	// - sty_userlist: Used for the WebAdmin user list
	// - sty_userlisttitle: Used for the WebAdmin user list title (Players, WebAdmin Users)
	// - sty_tinytext: Used for very small text
	//

	PageHeader="<html><head><title>SWAT: Elite Force WebAdmin</title>%1</head><body><div id='webadmin-content-wrapper'>"
	PageStyle="<style>.sty_statictext { font-family:Helvetica, Calibri, Arial; font-size:12px; text-align:center; color:#EEEEEE;} .sty_title { font-family:BankGothic, BankGothic Md, BankGothic Md Bt, Helvetica, Calibri, Arial; color:#EEEEEE; font-size:24pt; text-align:center;} .sty_subtitle { font-family:BankGothic, BankGothic Md, BankGothic Md Bt, Helvetica, Calibri, Arial; font-size:18pt; line-height:24pt;} .sty_error {color:#FF4444;} .sty_layouttable {} .sty_textarea { background:#222222; color:#EEEEEE; height:400px; resize:none; border: none; width:100%; overflow:scroll; overflow-x:auto; overflow-y:auto; font-family:Courier New, Courier, Consolas, monospace;} .sty_userlist { font-family:Helvetica, Calibri, Arial; font-size:12px; vertical-align: top;} .sty_userlisttitle { font-family:BankGothic, BankGothic Md, BankGothic Md Bt, Helvetica, Calibri, Arial, sans-serif; font-size:16px;} .sty_tinytext { text-align:center; position:absolute; margin-left:auto; margin-right:auto; font-family:Helvetica, Calibri, Arial; font-size:8px;} #inputarea { background:#222222; border:2px solid #EEEEEE; font-family:Helvetica, Calibri, Arial, sans-serif; padding: 4px; margin-right:4px; color:#EEEEEE; width:100%;} .sty_smolbutton { background:#EEEEEE; border:none; padding:8px; font-family:Helvetica, Calibri, Arial, sans-serif; font-weight:bold;} #bottominput { display:flex; width:100%;} #webadmin-content-wrapper { position:float; margin:auto; width:70%; display:block; right:0px;} #webadmin-content-box { padding:10px; color:#EEEEEE; font-family:Helvetica, Calibri, Arial; line-height:18px; border:4px solid #EEEEEE; text-align:center; font-weight:bold; font-size:12px;} .sty_button { background:white; border:4px solid #222222; font-family:BankGothic, BankGothic Md, BankGothic Md Bt, Helvetica, Calibri, Arial, sans-serif; padding: 8px 16px; line-height:20px; font-size:20px;} .sty_inputtext { background:black; border:1px solid #EEEEEE; line-height: 16px; color:#EEEEEE; padding:4px; margin-bottom:10px; margin-left: 8px;} table { font-family: inherit; color:#EEEEEE; margin-left:auto; margin-right:auto; width:100%;} th { border: 2px solid #EEEEEE; padding: 10px;} td { border: 2px solid #EEEEEE; padding: 10px; width:70%;} a { color:#FFFFBB} body { background:#222222; margin:50px; padding:0px;} select { background:#EEEEEE; border: none; padding: 7px;}</style>"
	PageFooter="</div></body></html>"

	NoPermissionString="You do not have permission to do that."
	NotEnoughArgsString="Not enough arguments for command."

	NotReadyString="[c=777777]Not Ready"
	ReadyString="[c=00FF00]Ready"
	NotAvailableString="[c=FF00FF]Not Available"
	HealthyString="[c=00FF00]Healthy"
	InjuredString="[c=FFFF00]Injured"
	IncapacitatedString="[c=FF0000]Incapacitated"
	LeaderString="[c=FFFF00]/Leader"
}
