class SwatAdmin extends Engine.Actor
    config(SwatAdmin);

enum AdminPermissions
{
	Permission_Kick,			// Allowed to kick people?
	Permission_KickBan,			// Allowed to kick-ban people?
	Permission_Switch,			// Allowed to switch maps?
	Permission_StartGame,		// Allowed to start game prematurely
	Permission_EndGame,			// Allowed to end game prematurely
	Permission_ChangeSettings,	// Allowed to change server settings
	Permission_Immunity,		// Immune to kick, ban, etc votes
	Permission_Max,
};

var public SwatAdminPermissions GuestPermissions;			// Guest permissions are given to every player, even ones that aren't signed in
var public array<SwatAdminPermissions> Permissions;			// These require someone to sign in
var public config name GuestPermissionName;
var public config array<name> PermissionNames;
var public config class<SwatAdminPermissions> PermissionClass;

////////////////////////////////////////////////////////////////////////////////

function PostBeginPlay()
{
	local int i;

	GuestPermissions = Spawn(PermissionClass, self, GuestPermissionName);

	for(i = 0; i < PermissionNames.Length; i++)
	{
		Permissions[i] = Spawn(PermissionClass, self, PermissionNames[i]);
	}
}

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

function bool ActionAllowed(PlayerController PC, AdminPermissions Permission)
{
	local SwatPlayerReplicationInfo PRI;

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

function Kick( PlayerController PC, String PlayerName )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_Kick))
	{
		return;
	}

    Level.Game.Kick( PC, PlayerName );
}

function KickBan( PlayerController PC, String PlayerName )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_KickBan))
	{
		return;
	}

    Level.Game.KickBan( PC, PlayerName );
}

function Switch( PlayerController PC, string URL )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_Switch))
	{
		return;
	}

	Level.ServerTravel( URL, false );
}

function StartGame( PlayerController PC )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_StartGame))
	{
		return;
	}

	SwatRepo(Level.GetRepo()).AllPlayersReady();
}

function AbortGame( PlayerController PC )
{
	if(!ActionAllowed(PC, AdminPermissions.Permission_EndGame))
	{
		return;
	}

	SwatGameInfo(Level.Game).GameAbort();
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
}
