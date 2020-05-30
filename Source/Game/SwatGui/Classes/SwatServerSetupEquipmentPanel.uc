class SwatServerSetupEquipmentPanel extends SwatGUIPanel
	;

var SwatServerSetupMenu SwatServerSetupMenu;

var(SWATGui) public EditInline Config GUIComboBox MyLessLethalBox;
var(SWATGui) protected EditInline Config GUIListBox MyAvailableEquipment;
var(SWATGui) protected EditInline Config GUIListBox MyDisabledEquipment;
var(SWATGui) protected EditInline Config GUIButton AddEquipment;
var(SWATGui) protected EditInline Config GUIButton RemoveEquipment;

function SetSubComponentsEnabled(bool bSetEnabled)
{
	MyLessLethalBox.SetEnabled(bSetEnabled);
	MyAvailableEquipment.SetEnabled(bSetEnabled);
	MyDisabledEquipment.SetEnabled(bSetEnabled);
	AddEquipment.SetEnabled(bSetEnabled);
	RemoveEquipment.SetEnabled(bSetEnabled);
}

function InternalOnActivate()
{
	SetSubComponentsEnabled( SwatServerSetupMenu.bIsAdmin );

	AddEquipment.OnClick = AddSelectedEquipment;
	RemoveEquipment.OnClick = RemoveSelectedEquipment;
}

//
event HandleParameters(string Param1, string Param2, optional int Param3)
{
	LoadServerSettings( !SwatServerSetupMenu.bIsAdmin );
}

function AddSelectedEquipment(GUIComponent Sender)
{
	local string Name;
	local string Extra;

	Name = MyAvailableEquipment.List.Get();
	Extra = MyAvailableEquipment.List.GetExtra();

	MyAvailableEquipment.List.Remove(MyAvailableEquipment.List.GetIndex());
	MyDisabledEquipment.List.Add(Name, , Extra);
}

function RemoveSelectedEquipment(GUIComponent Sender)
{
	local string Name;
	local string Extra;

	Name = MyDisabledEquipment.List.Get();
	Extra = MyDisabledEquipment.List.GetExtra();

	MyDisabledEquipment.List.Remove(MyDisabledEquipment.List.GetIndex());
	MyAvailableEquipment.List.Add(Name, , Extra);
}

function SaveServerSettings()
{
	// the stuff done here was moved to SwatServerSetupAdminPanel.uc
}

// Creates a comma-delimited list of disabled equipment classes based on the contents of MyDisabledEquipment
// For instance, "SwatEquipment.ColtM1911HG,SwatEquipment.BreachingSG" disables the M1911 and the Breaching Shotgun
function string GetDisabledEquipmentClasses()
{
	local int i;
	local string S;

	for(i = 0; i < MyDisabledEquipment.List.ElementCount(); i++)
	{
		S = S $ MyDisabledEquipment.List.GetExtraAtIndex(i) $ ",";
	}

	return S;
}

// Loads up the server settings
function LoadServerSettings(bool bReadOnly)
{
	local int i;
	local ServerSettings Settings;
	local string LessLethalLoadoutName;
	local class H;
	local class<Equipment> HE;
	local class Base;
	local array<class> AllDisabledEquipment;
	local array<string> SplitClasses;
	local bool bSkip;

	//
	if( bReadOnly )
	{
		Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);
		LessLethalLoadoutName = "";
	}
	else
	{	// This might cause issues if the menu gets loaded by someone who doesn't have the loadout in question...just leaving this alone for now
		Settings = ServerSettings(PlayerOwner().Level.PendingServerSettings);
		LessLethalLoadoutName = class'SwatGame.SwatAdmin'.default.LessLethalLoadoutName;
	}

	// Figure out what classes are disabled
	Split(Settings.DisabledEquipment, ",", SplitClasses);
	for(i = 0; i < SplitClasses.Length; i++)
	{
		AllDisabledEquipment[AllDisabledEquipment.Length] = class<Equipment>(DynamicLoadObject(SplitClasses[i], class'Class'));
	}

	// Clear out everything
	MyAvailableEquipment.List.Clear();
	MyDisabledEquipment.List.Clear();
	MyLessLethalBox.List.Clear();

	// Populate the list of enabled/disabled equipment...this is a pretty expensive operation tbh
	Base = class'Engine.Equipment';
	foreach AllClasses(Base, H)
	{
		HE = class<Equipment>(H);
		bSkip = false;

		if(!HE.static.IsUsableByPlayer())
		{
			continue;
		}

		// There are some things that we should NEVER consider when making this list because they are not player-attainable
		for(i = 0; i < AllDisabledEquipment.Length; i++)
		{
			if(H == AllDisabledEquipment[i])
			{
				MyDisabledEquipment.List.Add(HE.static.GetFriendlyName(), , string(H));
				bSkip = true;
				break;
			}
		}

		if(bSkip)
		{
			continue;
		}

		MyAvailableEquipment.List.Add(HE.static.GetFriendlyName(), , string(H));
	}

	// Populate the list of loadouts and set the loadout to match
	for( i = 0; i < GC.CustomEquipmentLoadouts.Length; i++ )
	{
		MyLessLethalBox.AddItem(GC.CustomEquipmentLoadoutFriendlyNames[i],,GC.CustomEquipmentLoadouts[i]);
	}
	MyLessLethalBox.List.FindExtra(LessLethalLoadoutName);
}

defaultproperties
{
	OnActivate=InternalOnActivate
}
