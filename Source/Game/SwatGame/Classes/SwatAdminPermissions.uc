class SwatAdminPermissions extends Engine.Actor
	config(SwatAdmin)
	perobjectconfig;

import enum AdminPermissions from SwatAdmin;

var config string PermissionSetName;	// Not replicated
var config string HashPassword;	// The password associated with this permission set (hashed)
var config int AllowedPermissions[AdminPermissions.Permission_Max];

////////////////////////////////////////////////////////////////
//
//	Data replication

replication
{
	unreliable if(Role == ROLE_Authority)
		AllowedPermissions;
}

////////////////////////////////////////////////////////////////
//
//	Methods

function SetPermission(AdminPermissions per, bool allowed)
{
	if(allowed)
	{
		AllowedPermissions[per] = 1;
	}
	else
	{
		AllowedPermissions[per] = 0;
	}
}

function bool GetPermission(AdminPermissions per)
{
	return AllowedPermissions[per] > 0;
}

function bool TryPassword(String Password)
{
	if(Password == HashPassword)
	{
		// Yes. We store passwords as plaintext. Allow me to justify this for a sec.
		// SHA1 and MD5 aren't programmed in Unreal Engine. Yet.
		// Since we can override this class (and therefore this function) later, it makes more sense to have a base class
		// that handles plaintext and then make a derived version that's more secure and handles stuff in SHA1 or whatever.
		return true;
	}

	return false;
}

function string GetPassword()
{
	return HashPassword;
}

////////////////////////////////////////////////////////////////
//
//	Default properties

defaultproperties
{
	HashPassword=""
	bAlwaysRelevant=true
	RemoteRole=Role_DumbProxy
}
