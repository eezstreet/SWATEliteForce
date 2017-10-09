class SwatServerSetupAdminPanel extends SwatGUIPanel
	;

import enum AdminPermissions from SwatGame.SwatAdmin;

var SwatServerSetupMenu SwatServerSetupMenu;

var localized config string GuestPermissionString;
var localized config string AdminPermissionString;
var localized config string PermissionNames[AdminPermissions.Permission_Max];
var localized config string PermissionDescription[AdminPermissions.Permission_Max];

var localized config string NewRoleFailedNotification;
var localized config string DeleteRoleFailedNotification;

var(SWATGui) protected EditInline Config GUIScrollTextBox MyInformation;
var(SWATGui) protected EditInline Config GUIRadioButton MyGuestPermissionSelection;
var(SWATGui) protected EditInline Config GUIRadioButton MyAdminPermissionSelection;
var(SWATGui) protected EditInline Config GUIComboBox MyRoleListBox;
var(SWATGui) protected EditInline Config GUIButton MyNewRoleButton;
var(SWATGui) protected EditInline Config GUIButton MyDeleteRoleButton;
var(SWATGui) protected EditInline Config GUIEditBox MyRoleNameBox;
var(SWATGui) protected EditInline Config GUIEditBox MyRolePasswordBox;

var(SWATGui) protected EditInline Config GUIListBox AvailableRights;
var(SWATGui) protected EditInline Config GUIListBox SelectedRights;
var(SWATGui) protected EditInline Config GUIButton AddRights;
var(SWATGui) protected EditInline Config GUIButton RemoveRights;

var private SwatAdminPermissions SelectedPermission;

var SwatAdmin AdminData;

// Triggered upon changing a radio button group
function SetRadioGroup(GUIRadioButton Group)
{
	Super.SetRadioGroup( group );

	switch(Group)
	{
		case MyGuestPermissionSelection:
			MyRoleListBox.SetEnabled(false);
			MyDeleteRoleButton.SetEnabled(false);
			MyRolePasswordBox.SetEnabled(false);
			MyNewRoleButton.SetEnabled(false);
			MyRoleNameBox.SetEnabled(false);
			AddRights.SetEnabled(true);
			RemoveRights.SetEnabled(true);
			UpdateSelectedPermission(AdminData.GuestPermissions);
			MyInformation.SetContent(GuestPermissionString);
			break;
		case MyAdminPermissionSelection:
			MyDeleteRoleButton.SetEnabled(true);
			MyNewRoleButton.SetEnabled(true);
			MyRoleNameBox.SetEnabled(true);

			if(MyRoleListBox.ItemCount() == 0)
			{
				MyRolePasswordBox.SetEnabled(false);
				MyRoleListBox.SetEnabled(false);
				AddRights.SetEnabled(false);
				RemoveRights.SetEnabled(false);
			}
			else
			{
				MyRolePasswordBox.SetEnabled(true);
				MyRoleListBox.SetEnabled(true);
				AddRights.SetEnabled(true);
				RemoveRights.SetEnabled(true);
			}

			RoleSelectionChanged();
			MyInformation.SetContent(AdminPermissionString);
			break;
	}
}

// Called whenever a ComboBox element gets changed
function InternalOnChange(GUIComponent Sender)
{
	switch(Sender)
	{
		case MyRoleListBox:
			UpdateSelectedPermission(SwatAdminPermissions(MyRoleListBox.GetObject()));
			MyInformation.SetContent(AdminPermissionString);
			break;
		case AvailableRights:
			MyInformation.SetContent(PermissionDescription[AvailableRights.List.GetExtraIntData()]);
			break;
		case SelectedRights:
			MyInformation.SetContent(PermissionDescription[SelectedRights.List.GetExtraIntData()]);
			break;
		case MyRolePasswordBox:
			SelectedPermission.HashPassword = MyRolePasswordBox.GetText();
			break;
	}
}

// Called whenever a button gets pressed
function InternalOnClick(GUIComponent Sender)
{
	switch(Sender)
	{
		case MyNewRoleButton:
			TryCreateNewRole();
			break;
		case MyDeleteRoleButton:
			TryDeleteRole();
			break;
		case AddRights:
			AddToRights();
			break;
		case RemoveRights:
			RemFromRights();
			break;
	}
}

// Called when the panel gets activated
function InternalOnActivate()
{
	// change us to be on the Guest role by default I guess
	MyGuestPermissionSelection.SelectRadioButton();
}

// Called when the panel gets created
function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

	OnActivate = InternalOnActivate;
	MyRoleListBox.OnChange = InternalOnChange;
	AvailableRights.OnChange = InternalOnChange;
	SelectedRights.OnChange = InternalOnChange;
	MyRolePasswordBox.OnChange = InternalOnChange;
	MyNewRoleButton.OnClick = InternalOnClick;
	MyDeleteRoleButton.OnClick = InternalOnClick;
	AddRights.OnClick = InternalOnClick;
	RemoveRights.OnClick = InternalOnClick;
}

//
event HandleParameters(string Param1, string Param2, optional int Param3)
{
	LoadServerSettings( !SwatServerSetupMenu.bIsAdmin );
}

// Set the permission set
function UpdateSelectedPermission(SwatAdminPermissions perm, optional string RoleName)
{
	local int i;

	SelectedPermission = perm;

	// Remove *everything* from the rights lists
	AvailableRights.Clear();
	SelectedRights.Clear();

	// Loop through all of the elements, adding them to either the available or selected rights
	for(i = 0; i < AdminPermissions.Permission_Max; i++)
	{
		if(perm.GetPermission(AdminPermissions(i)))
		{
			SelectedRights.List.Add(PermissionNames[i], , , i);
		}
		else
		{
			AvailableRights.List.Add(PermissionNames[i], , , i);
		}
	}

	// Set the password field to match this permission set
	MyRolePasswordBox.SetText(perm.GetPassword());
}

// This literally doesn't do anything, because there's no confirmation of anything that needs to happen.
private function InternalOnDlgReturned( int Selection, String passback )
{
	SwatServerSetupMenu.OnDlgReturned = None;
}

// Tries to create a new role. This can fail however.
function TryCreateNewRole()
{
	local String RoleName;
	local SwatAdminPermissions Perms;

	RoleName = MyRoleNameBox.GetText();
	if(Len(RoleName) == 0)
	{
		SwatServerSetupMenu.OnDlgReturned=InternalonDlgReturned;
		SwatServerSetupMenu.OpenDlg(NewRoleFailedNotification, QBTN_Ok, "NewRoleFailed");
		return;
	}

	Perms = PlayerOwner().Spawn(class'SwatAdmin'.default.PermissionClass, None, Name(RoleName));
	Perms.PermissionSetName = RoleName;
	AdminData.Permissions[AdminData.Permissions.Length] = Perms;

	// Clear the name field and set this object as our new role
	MyRoleNameBox.SetText("");
	MyRoleListBox.List.Add(RoleName, Perms);
	UpdateSelectedPermission(Perms);

	MyRolePasswordBox.SetEnabled(true);
	AddRights.SetEnabled(true);
	RemoveRights.SetEnabled(true);
	MyRoleListBox.SetEnabled(true);
}

// Tries to delete the selected role. This can fail however.
function TryDeleteRole()
{
	local int Index;

	if(SelectedPermission == None || SelectedPermission == AdminData.GuestPermissions)
	{	// You can't delete it if you didn't select it (roll-safe.jpg)
		return;
	}

	Index = MyRoleListBox.GetIndex();	// this will actually match the array Data
	MyRoleListBox.RemoveItem(Index);
	AdminData.Permissions.Remove(Index, 1);
}

// Adds the selected rights
function AddToRights()
{
	local int SelectedRight;
	local String SelectedRightName;

	SelectedRightName = AvailableRights.List.Get();
	if(SelectedRightName == "")
	{
		return; // we didn't select something
	}

	SelectedRight = AvailableRights.List.GetExtraIntData();
	AvailableRights.List.RemoveItem(SelectedRightName);

	SelectedRights.List.Add(SelectedRightName, , , SelectedRight);
	SelectedPermission.SetPermission(AdminPermissions(SelectedRight), true);
}

// Removes the selected rights
function RemFromRights()
{
	local int SelectedRight;
	local String SelectedRightName;

	SelectedRightName = SelectedRights.List.Get();
	if(SelectedRightName == "")
	{
		return; // we didn't select something
	}

	SelectedRight = SelectedRights.List.GetExtraIntData();
	SelectedRights.List.RemoveItem(SelectedRightName);

	AvailableRights.List.Add(SelectedRightName, , , SelectedRight);
	SelectedPermission.SetPermission(AdminPermissions(SelectedRight), false);
}

// Called either when the combobox gets changed, or we switch from guest permissions to custom permissions
function RoleSelectionChanged()
{
	UpdateSelectedPermission(AdminData.Permissions[MyRoleListBox.GetIndex()]);
}

function LoadServerSettings( optional bool bReadOnly )
{
	local int i;

	if(bReadOnly)
	{
		// FIXME
		return;
	}

	if(AdminData != None)
	{
		AdminData.destroy();
	}

	AdminData = PlayerOwner().Spawn(class'SwatAdmin', None, 'AdminData');

	for(i = 0; i < AdminData.Permissions.Length; i++)
	{
		MyRoleListBox.List.Add(AdminData.Permissions[i].PermissionSetName, AdminData.Permissions[i]);
	}

	SelectedPermission = AdminData.GuestPermissions;
}

// Called whenever the server settings need to be saved (obviously)
function SaveServerSettings()
{
	local int i;

	AdminData.PermissionNames.Length = AdminData.Permissions.Length;
	for(i = 0; i < AdminData.Permissions.Length; i++)
	{
		AdminData.PermissionNames[i] = AdminData.Permissions[i].Name;
		AdminData.Permissions[i].SaveConfig();
	}

	AdminData.default.GuestPermissionName = AdminData.GuestPermissions.Name;
	AdminData.GuestPermissions.SaveConfig();

	AdminData.SaveConfig();
}

defaultproperties
{
	OnActivate=InternalOnActivate

	NewRoleFailedNotification="Please type a name for this role."
	DeleteRoleFailedNotification="Please select a role to delete."

	PermissionNames[0]="Kick"
	PermissionNames[1]="KickBan"
	PermissionNames[2]="Switch Maps"
	PermissionNames[3]="Start Level"
	PermissionNames[4]="End Level"
	PermissionNames[5]="Change Settings"
	PermissionNames[6]="Vote Immunity"

	PermissionDescription[0]="Kick players from the server."
	PermissionDescription[1]="Kick (and ban) players from the server."
	PermissionDescription[2]="Change the server's map."
	PermissionDescription[3]="Start the level before all players are ready."
	PermissionDescription[4]="End the level before the mission is complete."
	PermissionDescription[5]="Change the server's settings."
	PermissionDescription[6]="Provides immunity to kick and kickban votes."
}
