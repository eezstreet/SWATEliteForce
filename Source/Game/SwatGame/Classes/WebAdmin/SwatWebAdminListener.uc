class SwatWebAdminListener extends IPDrv.TCPLink
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
	var IpAddr IPAddress;
	var int KeepAlive;
	var SwatAdminPermissions PermissionSet;
	var array<WebAdminMessage> WaitingMessages;
};

var globalconfig bool DebugWebAdmin;
var globalconfig int KeepAliveTime;
var globalconfig string PageHeader;
var globalconfig string PageFooter;

var localized config string NoPermissionString;

var private int BoundPort;
var private array<WebAdminUser> Users;

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
	SetTimer(1.0, true);
}

// The timer on this class is responsible for checking whether or not to keep the admins alive.
event Timer()
{
	local int i;
	local string IPString;

	for(i = Users.Length - 1; i >= 0; i--)	// loop backwards so we don't die when removing a user
	{
		if(float(Users[i].KeepAlive + KeepAliveTime) < Level.TimeSeconds)
		{
			if(Users[i].Alias != "")
			{
				IPString = IpAddrToString(Users[i].IPAddress);
				mplog("WebAdmin: Logged "$Users[i].Alias$" ("$IPString$") out due to timeout");
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
function string LoginUser(string Alias, IpAddr IPAddress, SwatAdminPermissions Permissions)
{
	local WebAdminUser User;

	User.Alias = Alias;
	User.IPAddress = IPAddress;
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
function bool Polled(SwatWebAdmin AdminClient, string Cookie)
{
	local int i;
	local int j;
	local string XML;
	local SwatGameReplicationInfo SGRI;
	local SwatPlayerReplicationInfo PRI;

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
	argv[0] = Mid(argv[0], 1);

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

defaultproperties
{
	KeepAliveTime=30
	DebugWebAdmin=false

	PageHeader="<html><head><title>SWAT: Elite Force WebAdmin</title></head><body><div id='webadmin-content-wrapper'>"
	PageFooter="</div></body></html>"

	NoPermissionString="You do not have permission to do that."
}
