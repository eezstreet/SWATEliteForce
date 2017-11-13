class SwatWebAdminListener extends IPDrv.TCPLink
	transient
	config(Swat4XDedicatedServer)
	dependsOn(SwatAdmin);

import enum AdminPermissions from SwatAdmin;
import enum WebAdminMessageType from SwatAdmin;

struct WebAdminMessage
{
	var WebAdminMessageType MessageType;
	var string Message;
};

struct WebAdminUser
{
	var string Alias;
	var string Cookie;
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

var localized config string NoPermissionString;

var private int BoundPort;
var globalconfig array<WebAdminUser> Users;

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
function string LoginUser(string Alias, SwatAdminPermissions Permissions)
{
	local WebAdminUser User;

	User.Alias = Alias;
	User.KeepAlive = Level.TimeSeconds;
	User.PermissionSet = Permissions;
	User.Cookie = GenerateGUID();

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
function bool Polled(SwatWebAdmin AdminClient, string Cookie, string NewUser, string NewPass, bool NewGuest)
{
	local int i;
	local int j;
	local string XML;
	local SwatGameReplicationInfo SGRI;
	local SwatPlayerReplicationInfo PRI;
	local string NewCookie;
	local SwatAdminPermissions Perms;

	SGRI = SwatGameReplicationInfo(Level.Game.GameReplicationInfo);

	for(i = 0; i < Users.Length; i++)
	{
		if(Cookie == Users[i].Cookie)
		{
			Users[i].KeepAlive = Level.TimeSeconds + KeepAliveTime;

			XML = "<POLLDATA>";

			XML = XML $ "<USERS>";
			for(j = 0; j < ArrayCount(SGRI.PRIStaticArray); j++)
			{
				PRI = SGRI.PRIStaticArray[j];
				if(PRI == None)
				{
					continue;
				}

				XML = XML $ "<USER>" $ PRI.PlayerName $ "</USER>";
			}
			XML = XML $ "</USERS>";

			XML = XML $ "<ADMINS>";
			for(j = 0; j < Users.Length; j++)
			{
				XML = XML $ "<ADMIN>";
				XML = XML $ "<ALIAS>" $ Users[i].Alias $ "</ALIAS>";
				XML = XML $ "<ROLE>" $ Users[i].PermissionSet.PermissionSetName $ "</ROLE>";
				XML = XML $ "</ADMIN>";
			}
			XML = XML $ "</ADMINS>";

			XML = XML $ "<MSGS>";
			for(j = 0; j < Users[i].WaitingMessages.Length; j++)
			{
				XML = XML $ "<MSG>";
				XML = XML $ "<MSGTYPE>" $ Users[i].WaitingMessages[j].MessageType $ "</MSGTYPE>";
				XML = XML $ "<MSGTEXT>" $ Users[i].WaitingMessages[j].Message $ "</MSGTEXT>";
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

	NewCookie = LoginUser(NewUser, Perms);
	AdminClient.SetCookie(NewCookie);

	return false;
}

// We got sent some command from a webadmin
function SentCommand(SwatWebAdmin AdminClient, int User, string Content)
{
	local array<string> argv;
	local WebAdminMessage msg;
	local string Alias;
	local string IngameName;
	local int i;

	i = User;
	Alias = Users[i].Alias;
	IngameName = Alias$"(WebAdmin)";

	Split(Content, " ", argv);

	msg.MessageType = WebAdminMessageType.MessageType_WebAdminError;

	// perform command based on the first argument
	if(argv[0] ~= "kick")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_Kick))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else if(!Level.Game.RemoteKick(IngameName, ConcatArgs(argv, 1)))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
	}
	else if(argv[0] ~= "ban" || argv[0] ~= "kickban")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_KickBan))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else if(!Level.Game.RemoteKickBan(IngameName, ConcatArgs(argv, 1)))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
	}
	else if(argv[0] ~= "lockteams" || argv[0] ~= "unlockteams" || argv[0] ~= "toggleteamlock")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_LockTeams))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else
		{
			SwatGameInfo(Level.Game).RemoteLockTeams(Users[i].Alias$"(WebAdmin)");
		}
	}
	else if(argv[0] ~= "lockplayerteam" || argv[0] ~= "unlockplayerteam" || argv[0] ~= "toggleplayerteamlock")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_LockPlayerTeams))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else if(!SwatGameInfo(Level.Game).RemoteLockPlayerTeam(Users[i].Alias$"(WebAdmin)", ConcatArgs(argv, 1)))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
	}
	else if(argv[0] ~= "alltored" || argv[0] ~= "forceallred" || argv[0] ~= "forceredall")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_ForceAllTeams))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else
		{
			SwatGameInfo(Level.Game).RemoteForceAllToTeam(Users[i].Alias$"(WebAdmin)", 2);
		}
	}
	else if(argv[0] ~= "alltoblue" || argv[0] ~= "forceallblue" || argv[0] ~= "forceblueall")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_ForceAllTeams))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else
		{
			SwatGameInfo(Level.Game).RemoteForceAllToTeam(Users[i].Alias$"(WebAdmin)", 0);
		}
	}
	else if(argv[0] ~= "forcered")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_ForcePlayerTeam))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else if(!SwatGameInfo(Level.Game).RemoteForcePlayerTeam(Users[i].Alias$"(WebAdmin)", ConcatArgs(argv, 1), 2))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
	}
	else if(argv[0] ~= "forceblue")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_ForcePlayerTeam))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else if(!SwatGameInfo(Level.Game).RemoteForcePlayerTeam(Users[i].Alias$"(WebAdmin)", ConcatArgs(argv, 1), 0))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
	}
	else if(argv[0] ~= "mute" || argv[0] ~= "unmute" || argv[0] ~= "togglemute")
	{
		if(!Users[i].PermissionSet.GetPermission(AdminPermissions.Permission_Mute))
		{
			msg.Message = NoPermissionString;
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
		else if(!SwatGameInfo(Level.Game).RemoteMute(Users[i].Alias$"(WebAdmin)", ConcatArgs(argv, 1)))
		{
			msg.Message = "Couldn't find player '"$ConcatArgs(argv, 1)$"'";
			Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
		}
	}
	else
	{
		msg.Message = "Unknown command '"$argv[0]$"'";
		Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
	}
}

// We got sent some chat from a webadmin
function SentChat(SwatWebAdmin AdminClient, int User, string Content)
{
	local string Alias;
	local WebAdminMessage Msg;

	Alias = Users[User].Alias;

	if(!Users[User].PermissionSet.GetPermission(AdminPermissions.Permission_WebAdminChat))
	{
		Msg.MessageType = WebAdminMessageType.MessageType_WebAdminError;
		Msg.Message = NoPermissionString;
		Users[User].WaitingMessages[Users[User].WaitingMessages.Length] = Msg;
		return;
	}

	// broadcast it?
	SwatGameInfo(Level.Game).Broadcast(self, Alias$"(WebAdmin)\t"$Content, 'WebAdminChat');
	Level.Game.AdminLog(Alias$"(WebAdmin)\t"$Content, 'WebAdminChat');
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
function SendWebAdminMessage(WebAdminMessageType type, optional string Message)
{
	local WebAdminMessage msg;
	local int i;

	msg.MessageType = type;
	msg.Message = Message;

	for(i = 0; i < Users.Length; i++)
	{
		Users[i].WaitingMessages[Users[i].WaitingMessages.Length] = msg;
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
	PageStyle="<style>.sty_statictext { font-family:Helvetica, Calibri, Arial; font-size:12px; text-align:center; color:#EEEEEE;} .sty_title { font-family:BankGothic, BankGothic Md, BankGothic Md Bt, Helvetica, Calibri, Arial; color:#EEEEEE; font-size:24pt; text-align:center;} .sty_subtitle { font-family:BankGothic, BankGothic Md, BankGothic Md Bt, Helvetica, Calibri, Arial; font-size:18pt; line-height:24pt;} .sty_error {color:#FF4444;} .sty_layouttable {} .sty_textarea { background:#222222; color:#EEEEEE; height:400px; resize:none; border: none; width:100%;} .sty_userlist { font-family:Helvetica, Calibri, Arial; font-size:12px; vertical-align: top;} .sty_userlisttitle { font-family:BankGothic, BankGothic Md, BankGothic Md Bt, Helvetica, Calibri, Arial; font-size:16px;} .sty_tinytext { text-align:center; position:absolute; margin-left:auto; margin-right:auto; font-family:Helvetica, Calibri, Arial; font-size:8px;} #inputarea { background:#222222; border:2px solid #EEEEEE; font-family:Helvetica, Calibri, Arial; padding: 4px; margin-right:4px; color:#EEEEEE; width:100%;} #sendbutton { background:#EEEEEE; border:none; padding:8px; width:10%; font-family:Helvetica, Calibri, Arial; font-weight:bold; float:right;} #bottominput { display:flex; width:100%;} #webadmin-content-wrapper { position:float; margin:auto; width:70%; display:block; right:0px;} #webadmin-content-box { padding:10px; color:#EEEEEE; font-family:Helvetica, Calibri, Arial; line-height:18px; border:4px solid #EEEEEE; text-align:center; font-weight:bold; font-size:12px;} .sty_button { background:white; border:4px solid #222222; font-family:BankGothic, BankGothic Md, BankGothic Md Bt, Helvetica, Calibri, Arial; padding: 8px 16px; line-height:20px; font-size:20px;} .sty_inputtext { background:black; border:1px solid #EEEEEE; line-height: 16px; color:#EEEEEE; padding:4px; margin-bottom:10px; margin-left: 8px;} table { font-family: inherit; color:#EEEEEE; margin-left:auto; margin-right:auto; width:100%;} th { border: 2px solid #EEEEEE; padding: 10px;} td { border: 2px solid #EEEEEE; padding: 10px; width:70%;} form { padding: 10px;} a { color:#FFFFBB} body { background:#222222; margin:100px; padding:0px;}</style>"
	PageFooter="</div></body></html>"

	NoPermissionString="You do not have permission to do that."
}
