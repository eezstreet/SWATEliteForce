class CustomScenario_SelectionPanel extends CustomScenarioTabPanel;

var(SWATGui) private EditInline Config GUIButton            cmd_play;

var(SWATGui) private EditInline Config GUIButton            cmd_new;
var(SWATGui) private EditInline Config GUIButton            cmd_edit;
var(SWATGui) private EditInline Config GUIButton            cmd_delete;
var(SWATGui) private EditInline Config CustomScenarioList   lst_scenarios;

// Stuff that's in the pack edit screen
var() private CustomScenarioPack CurrentPack;
var() private string PendingPackName;
var() private array<class<Actor> > PendingDisabledEquipment;
var() private array<class<Actor> > PendingFirstUnlocks;
var() private array<class<Actor> > PendingSecondUnlocks;
var() private bool PendingUseProgression;
var() private bool PendingUseGearUnlocks;
var() private array<string> PendingProgression;
var(SWATGui) private EditInline Config GUIEditBox			pack_name;
var(SWATGui) private EditInline Config GUICheckboxButton	pack_use_unlocks;
var(SWATGui) private EditInline Config GUICheckboxButton	pack_use_progression;
var(SWATGui) private EditInline Config GUIButton			pack_edit_equipment;
var(SWATGui) private EditInline Config GUIButton			pack_edit_unlocks;
var(SWATGui) private EditInline Config GUIButton			pack_edit_progression;
var(SWATGui) private EditInline Config GUIButton			pack_save;
var(SWATGui) private EditInline Config GUIButton			pack_showlist;

// Stuff that's in the equipment choose screen. This should be pretty similar to the one on the Server Setup page.
var(SWATGui) private EditInline Config GUILabel				equip_header;
var(SWATGui) private EditInline Config GUIListBox			equip_available;
var(SWATGui) private EditInline Config GUIListBox			equip_disabled;
var(SWATGui) private EditInline Config GUILabel				equip_availableLabel;
var(SWATGui) private EditInline Config GUILabel				equip_disabledLabel;
var(SWATGui) private EditInline Config GUIButton			equip_addequipment;
var(SWATGui) private EditInline Config GUIButton			equip_remequipment;

// Stuff that's in the progression screen. This should be pretty similar to the map rotation setup on the Server Setup page.
var(SWATGui) private EditInline Config GUILabel				prog_header;
var(SWATGui) private EditInline Config GUIListBox			prog_mapsbox;
var(SWATGui) private EditInline Config GUIButton			prog_upbutton;
var(SWATGui) private EditInline Config GUIButton			prog_dnbutton;

// Stuff that's on the unlocks screen. We'll have to use some creativity in building this "tab".
var(SWATGui) private EditInline Config GUILabel				unlock_header;
var(SWATGui) private EditInline Config GUIComboBox			unlock_packlist;
var(SWATGui) private EditInline Config GUILabel				unlock_packlistLabel;
var(SWATGui) private EditInline Config GUIListBox			unlock_unlocklist;
var(SWATGui) private EditInline Config GUIListBox			unlock_availablelist;
var(SWATGui) private EditInline Config GUILabel				unlock_unlocklistLabel;
var(SWATGui) private EditInline Config GUILabel				unlock_availablelistLabel;
var(SWATGui) private EditInline Config GUIButton			unlock_addUnlock;
var(SWATGui) private EditInline Config GUIButton			unlock_remUnlock;


var() private config localized string ConfirmDeleteString;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    Data = CustomScenarioPage.CustomScenarioCreatorData;

    cmd_play.OnClick        = cmd_play_OnClick;

    cmd_new.OnClick         = cmd_new_OnClick;
    cmd_edit.OnClick        = cmd_edit_OnClick;
    cmd_delete.OnClick      = cmd_delete_OnClick;
    lst_scenarios.OnChange  = lst_scenarios_OnChange;
	pack_use_unlocks.OnChange = UseUnlocks_OnChange;
	pack_use_progression.OnChange = pack_use_progression_OnChange;
	pack_name.OnChange = pack_name_OnChange;
	pack_edit_equipment.OnCLick = pack_edit_equipment_OnClick;
	pack_edit_unlocks.OnClick = pack_edit_unlocks_OnClick;
	pack_edit_progression.OnClick = pack_edit_progression_OnClick;
	pack_save.OnClick = pack_save_OnClick;
	pack_showlist.OnClick = pack_showlist_OnClick;

	equip_addequipment.OnClick = equip_addequipment_OnClick;
	equip_remequipment.OnClick = equip_remequipment_OnClick;

	prog_upbutton.OnClick = prog_upbutton_OnClick;
	prog_dnbutton.OnClick = prog_dnbutton_OnClick;

	unlock_addUnlock.OnClick = unlock_addUnlock_OnClick;
	unlock_remUnlock.OnClick = unlock_remUnlock_OnClick;
	unlock_packlist.OnChange = unlock_packlist_OnChange;
}

event Activate()
{
    RefreshScenariosList();

    Super.Activate();

    UpdateButtonStates();

	pack_name.DisableComponent();
	pack_edit_unlocks.DisableComponent();
	pack_use_progression.DisableComponent();
	pack_edit_equipment.DisableComponent();
	pack_edit_progression.DisableComponent();
	pack_save.DisableComponent();

	// FIXME: maybe use a tab control here somehow?
	ShowScenarioList();
	HideEquipmentPanel();
	HideUnlocksPanel();
	HideProgressionPanel();

	// Down here, because the act of hiding the unlocks panel enables the unlocks checkbox
	pack_use_unlocks.DisableComponent();
}

function cmd_play_OnClick(GUIComponent Sender)
{
    local string Scenario;
    local string Pack;

    lst_scenarios.GetSelectedRow(Scenario, Pack);

    CustomScenarioPage.PlayScenario(Scenario, Pack);
}

function cmd_new_OnClick(GUIComponent Sender)
{
    CustomScenarioPage.CreateNewScenario();
}

function cmd_edit_OnClick(GUIComponent Sender)
{
    local string Scenario;
    local string Pack;

    lst_scenarios.GetSelectedRow(Scenario, Pack);

    CustomScenarioPage.EditScenario(Scenario, Pack);
}

function cmd_delete_OnClick(GUIComponent Sender)
{
    local string Scenario;
    local string Pack;

    lst_scenarios.GetSelectedRow(Scenario, Pack);

	Controller.TopPage().OnDlgReturned=ConfirmDeleteDlgReturned;
    Controller.TopPage().OpenDlg( FormatTextString( ConfirmDeleteString, Scenario, Pack ), QBTN_YesNo, "" );
}

// Called when clicking the EDIT EQUIPMENT button
function pack_edit_equipment_OnClick(GUIComponent Sender)
{
	HideScenarioList();
	HideUnlocksPanel();
	HideProgressionPanel();
	ShowEquipmentPanel();
}

// Called when clicking the EDIT UNLOCKS button
function pack_edit_unlocks_OnClick(GUIComponent Sender)
{
	HideScenarioList();
	HideProgressionPanel();
	HideEquipmentPanel();
	ShowUnlocksPanel();
}

// Called when changing the name of the pack
function pack_name_OnChange(GUIComponent Sender)
{
	PendingPackName = pack_name.GetText();
}

// Called when clicking the EDIT PROGRESSION button
function pack_edit_progression_OnClick(GUIComponent Sender)
{
	HideScenarioList();
	HideEquipmentPanel();
	HideUnlocksPanel();
	ShowProgressionPanel();
}

// Called when clicking the SAVE MISSION PACK button
function pack_save_OnClick(GUIComponent Sender)
{
	local int i;

	CurrentPack.PackVersion = CurrentPack.LatestPackVersion;
	CurrentPack.UseProgression = pack_use_progression.bChecked;
	CurrentPack.UseGearUnlocks = pack_use_unlocks.bChecked;
	CurrentPack.ScenarioStrings.Length = 0;
	CurrentPack.FirstEquipmentUnlocks.Length = 0;
	CurrentPack.SecondEquipmentUnlocks.Length = 0;
	CurrentPack.DisabledEquipment.Length = 0;

	for(i = 0; i < PendingProgression.Length; i++)
	{
		CurrentPack.ScenarioStrings[i] = PendingProgression[i];
	}

	for(i = 0; i < PendingFirstUnlocks.Length; i++)
	{
		CurrentPack.FirstEquipmentUnlocks[i] = PendingFirstUnlocks[i];
	}

	for(i = 0; i < PendingSecondUnlocks.Length; i++)
	{
		CurrentPack.SecondEquipmentUnlocks[i] = PendingSecondUnlocks[i];
	}

	for(i = 0; i < PendingDisabledEquipment.Length; i++)
	{
		CurrentPack.DisabledEquipment[i] = PendingDisabledEquipment[i];
	}

	log("pack_save_OnClick MISSION PACK STATS---");
	log("Pack Version: "$CurrentPack.PackVersion);
	log("Use Progression: "$CurrentPack.UseProgression);
	log("Use Gear Unlocks: "$CurrentPack.UseGearUnlocks);
	log("Scenario Strings ("$CurrentPack.ScenarioStrings.Length$")");
	for(i = 0; i < CurrentPack.ScenarioStrings.Length; i++)
	{
		log("---"$CurrentPack.ScenarioStrings[i]);
	}
	log("FirstEquipmentUnlocks ("$CurrentPack.FirstEquipmentUnlocks.Length$")");
	for(i = 0; i < CurrentPack.FirstEquipmentUnlocks.Length; i++)
	{
		log("---"$CurrentPack.FirstEquipmentUnlocks[i]);
	}
	log("SecondEquipmentUnlocks ("$CurrentPack.SecondEquipmentUnlocks.Length$")");
	for(i = 0; i < CurrentPack.SecondEquipmentUnlocks.Length; i++)
	{
		log("---"$CurrentPack.SecondEquipmentUnlocks[i]);
	}
	log("DisabledEquipment("$CurrentPack.DisabledEquipment.Length$")");
	for(i = 0; i < CurrentPack.DisabledEquipment.Length; i++)
	{
		log("---"$CurrentPack.DisabledEquipment[i]);
	}

	CustomScenarioPage.SavePack(PendingPackName, CurrentPack);
}

// Called when clicking the SHOW LIST button
function pack_showlist_OnClick(GUIComponent Sender)
{
	ShowScenarioList();
	HideEquipmentPanel();
	HideUnlocksPanel();
	HideProgressionPanel();
}

// Called when clicking the add equipment button on the Equipment subscreen
function equip_addequipment_OnClick(GUIComponent Sender)
{
	local class<Equipment> Equipment;
	local string EquipmentName;
	local int Index;
	local int i;

	if(equip_available.ItemCount() == 0)
	{
		return; // no items to disable
	}

	Index = equip_available.List.GetIndex();
	if(Index < 0)
	{
		return; // nothing selected
	}

	Equipment = class<Equipment>(equip_available.List.GetObject());
	EquipmentName = equip_available.List.Get();

	equip_disabled.List.Add(EquipmentName, Equipment);
	equip_available.List.Remove(Index);

	// Rebuild the list of equipment
	RebuildPendingEquipment();

	// Remove the equipment piece from any of the pending unlocks
	for(i = 0; i < PendingFirstUnlocks.Length; i++)
	{
		if(PendingFirstUnlocks[i] == Equipment)
		{
			if(PendingSecondUnlocks[i] != None)
			{
				PendingFirstUnlocks[i] = PendingSecondUnlocks[i];
				PendingSecondUnlocks[i] = None;
			}
			else
			{
				PendingFirstUnlocks[i] = None;
			}
			break;
		}
	}

	for(i = 0; i < PendingSecondUnlocks.Length; i++)
	{
		if(PendingSecondUnlocks[i] == Equipment)
		{
			PendingSecondUnlocks[i] = None;
			break;
		}
	}
}

// Called when clicking the remove equipment button on the Equipment subscreen
function equip_remequipment_OnClick(GUIComponent Sender)
{
	local class<Equipment> Equipment;
	local string EquipmentName;
	local int Index;

	if(equip_disabled.ItemCount() == 0)
	{
		return; // no items to enable
	}

	Index = equip_disabled.List.GetIndex();
	if(Index < 0)
	{
		return; // nothing selected
	}

	Equipment = class<Equipment>(equip_disabled.List.GetObject());
	EquipmentName = equip_disabled.List.Get();

	equip_available.List.Add(EquipmentName, Equipment);
	equip_disabled.List.Remove(Index);

	// Rebuild the list of equipment
	RebuildPendingEquipment();
}

function RebuildPendingEquipment()
{
	local int i;

	// Clear it out
	PendingDisabledEquipment.Length = 0;

	// ... and rebuild it
	for(i = 0; i < equip_disabled.Num(); i++)
	{
		PendingDisabledEquipment[i] = class<Equipment>(equip_disabled.List.GetObjectAtIndex(i));
	}
}

function RebuildPendingProgression()
{
	local int i;

	// Clear out the pending progression
	PendingProgression.Length = 0;

	// Trawl the map list and insert each one one-by-one
	for(i = 0; i < prog_mapsbox.Num(); i++)
	{
		PendingProgression[i] = prog_mapsbox.List.GetItemAtIndex(i);
	}
}

function prog_upbutton_OnClick(GUIComponent Sender)
{
	local int index;

	// Get index and swap it with the previous
	index = prog_mapsbox.GetIndex();

	if(index <= 0)
	{
		return;
	}

	prog_mapsbox.List.SwapIndices( index, index-1 );
	prog_mapsbox.List.SetIndex( index - 1 );

	// Clear out the pending progression and rebuild it
	RebuildPendingProgression();
}

function prog_dnbutton_OnClick(GUIComponent Sender)
{
	local int index;

	// Get index and swap it with the next
	index = prog_mapsbox.GetIndex();

	if(index < 0 || index >= prog_mapsbox.Num()-1)
	{
		return;
	}

	prog_mapsbox.List.SwapIndices(index, index + 1);
	prog_mapsbox.List.SetIndex(index + 1);

	// Clear out the pending progression and rebuild it
	RebuildPendingProgression();
}

function unlock_addUnlock_OnClick(GUIComponent Sender)
{
	local int Index, MissionIndex;
	local class<Equipment> Equipment;
	local string EquipmentName;

	Index = unlock_availablelist.List.GetIndex();
	if(Index < 0 || Index >= unlock_availablelist.Num())
	{
		log("bad index in unlock_addunlock_onclick");
		return;	// invalid index selected
	}

	MissionIndex = unlock_packlist.List.GetIndex();

	Equipment = class<Equipment>(unlock_availablelist.List.GetObject());
	EquipmentName = unlock_availablelist.List.Get();

	if(unlock_unlocklist.Num() == 0)
	{	// Add it to the first unlock list
		PendingFirstUnlocks[MissionIndex] = Equipment;
		unlock_unlocklist.List.Add(EquipmentName, Equipment, , , true);
		unlock_availablelist.List.Remove(Index);
	}
	else if(unlock_unlocklist.Num() == 1)
	{	// Add it to the second unlock list
		PendingSecondUnlocks[MissionIndex] = Equipment;
		unlock_unlocklist.List.Add(EquipmentName, Equipment, , , false);
		unlock_availablelist.List.Remove(Index);
	}

	// If the unlocks list has two things in it, disable the Add Unlock button
	if(unlock_unlocklist.Num() >= 2)
	{
		unlock_addUnlock.DisableComponent();
	}
}

function unlock_remUnlock_OnClick(GUIComponent Sender)
{
	local int Index, MissionIndex, i;
	local class<Equipment> Equipment, TempEquipment;
	local string EquipmentName, TempEquipmentName;

	Index = unlock_unlocklist.List.GetIndex();
	if(Index < 0 || Index >= unlock_unlocklist.Num())
	{
		return;
	}

	MissionIndex = unlock_packlist.List.GetIndex();

	Equipment = class<Equipment>(unlock_unlocklist.List.GetObject());
	EquipmentName = unlock_unlocklist.List.Get();

	// Add it to the available equipment list
	unlock_availablelist.List.Add(EquipmentName, Equipment);

	// Remove the option from the unlocked list.
	if(unlock_unlocklist.List.GetExtraBoolData() && unlock_unlocklist.Num() == 2)
	{	// We removed the first option. We need to shuffle the second option back to being a first option.
		// Stupid - loop through the list of options to find the one that isn't the first one
		for(i = 0; i < unlock_unlocklist.Num(); i++)
		{
			if(!unlock_unlocklist.List.GetExtraBoolAt(i))
			{
				// Store the name
				TempEquipmentName = unlock_unlocklist.List.GetAt(i);
				TempEquipment = class<Equipment>(unlock_unlocklist.List.GetObjectAt(i));
				break;
			}
		}

		// Clear the whole list
		unlock_unlocklist.Clear();
		unlock_unlocklist.List.Clear();

		// Readd the second item, but mark it as the first item
		unlock_unlocklist.List.Add(TempEquipmentName, TempEquipment, , , true);

		// Fix the pending unlocks
		PendingFirstUnlocks[MissionIndex] = TempEquipment;
		PendingSecondUnlocks[MissionIndex] = None;
	}
	else if(unlock_unlocklist.List.GetExtraBoolData())
	{	// Removed the first option and there is not a second option
		// Clear the whole list
		unlock_unlocklist.List.Remove(Index);
		PendingFirstUnlocks[MissionIndex] = None;
	}
	else
	{	// We removed the second option. This is significantly less of a pain to deal with.
		unlock_unlocklist.List.Remove(Index);
		PendingSecondUnlocks[MissionIndex] = None;
	}

	// Always enable the Add Unlock button after hitting the Remove Unlock button
	unlock_addUnlock.EnableComponent();
}

// Called when changing the mission selected on the Unlocks screen.
function unlock_packlist_OnChange(GUIComponent Sender)
{
	local int MissionIndex, i;
	local class Base, H;
	local class<Equipment> HE;
	local bool bSkip;

	// Clear out the list of stuff that's in both the unlocked and available lists.
	unlock_unlocklist.Clear();
	unlock_unlocklist.List.Clear();
	unlock_availablelist.Clear();
	unlock_availablelist.List.Clear();

	// Iterate over all classes of equipment.
	MissionIndex = unlock_packlist.List.GetIndex();
	if(MissionIndex < 0)
	{	// Not a valid mission selected
		return;
	}

	Base = class'Engine.Equipment';
	foreach AllClasses(Base, H)
	{
		HE = class<Equipment>(H);
		bSkip = false;

		if(!HE.static.IsUsableByPlayer())
		{
			continue;
		}

		// Check to see if it's in the list of disable equipment.
		for(i = 0; i < PendingDisabledEquipment.Length; i++)
		{
			if(H == PendingDisabledEquipment[i])
			{
				bSkip = true;
				break;
			}
		}

		if(bSkip == true)
		{	// Equipment is disabled
			continue;
		}

		// Check to see if the piece of equipment is already unlocked - first slot
		for(i = 0; i < PendingFirstUnlocks.Length; i++)
		{
			if(i == MissionIndex && H == PendingFirstUnlocks[i])
			{	// It's unlocked on the selected mission
				unlock_unlocklist.List.Add(HE.static.GetFriendlyName(), , , , true);
				bSkip = true;
				break;
			}
			else if(H == PendingFirstUnlocks[i])
			{	// It's unlocked on another mission.
				bSkip = true;
				break;
			}
		}

		if(bSkip == true)
		{	// Equipment is unlocked already
			continue;
		}

		// Check to see if the piece of equipment is already unlocked - second slot
		for(i = 0; i < PendingSecondUnlocks.Length; i++)
		{
			if(i == MissionIndex && H == PendingSecondUnlocks[i])
			{	// It's unlocked on the selected mission
				unlock_unlocklist.List.Add(HE.static.GetFriendlyName(), HE, , , false);
				bSkip = true;
				break;
			}
			else if(H == PendingSecondUnlocks[i])
			{	// It's unlocked on another mission.
				bSkip = true;
				break;
			}
		}

		if(bSkip == true)
		{	// Equipment is unlocked already
			continue;
		}

		// Not unlocked, player usable, and not disabled, add it to the available equipment list
		unlock_availablelist.List.Add(HE.static.GetFriendlyName(), HE);
	}

	// If there are two items in the Unlocked Items list, disable the Add Item button
	if(unlock_unlocklist.Num() >= 2)
	{
		unlock_addUnlock.DisableComponent();
	}
	else
	{
		unlock_addUnlock.EnableComponent();
	}
}

/////////////////////////////////////////////////////////
//
//	Scenario list. Shown by default.

function HideScenarioList()
{
	lst_scenarios.DisableComponent();
	lst_scenarios.Hide();
	cmd_play.Hide();
	cmd_new.Hide();
	cmd_delete.Hide();
	cmd_edit.Hide();
	pack_showlist.Show();
}

function ShowScenarioList()
{
	lst_scenarios.EnableComponent();
	lst_scenarios.Show();
	cmd_play.Show();
	cmd_new.Show();
	cmd_delete.Show();
	cmd_edit.Show();
	pack_showlist.Hide();
}

/////////////////////////////////////////////////////////
//
//	Edit Equipment

function HideEquipmentPanel()
{
	equip_header.Hide();
	equip_available.Hide();
	equip_disabled.Hide();
	equip_availableLabel.Hide();
	equip_disabledLabel.Hide();
	equip_addequipment.Hide();
	equip_remequipment.Hide();
}

function ShowEquipmentPanel()
{
	equip_header.Show();
	equip_available.Show();
	equip_disabled.Show();
	equip_availableLabel.Show();
	equip_disabledLabel.Show();
	equip_addequipment.Show();
	equip_remequipment.Show();

	// Populate the list of disabled and enabled equipment.
	PopulateEquipmentList();
}

function PopulateEquipmentList()
{
	local class Base, H;
	local class<Equipment> HE;
	local bool bSkip;
	local int i;

	equip_disabled.Clear();
	equip_disabled.List.Clear();
	equip_available.Clear();
	equip_available.List.Clear();

	Base = class'Engine.Equipment';
	foreach AllClasses(Base, H)
	{
		HE = class<Equipment>(H);
		bSkip = false;

		if(!HE.static.IsUsableByPlayer())
		{
			continue;
		}

		// Check to see if it's in the list of disabled equipment for this pack
		for(i = 0; i < PendingDisabledEquipment.Length; i++)
		{
			if(H == PendingDisabledEquipment[i])
			{
				equip_disabled.List.Add(HE.static.GetFriendlyName(), HE);
				bSkip = true;
				break;
			}
		}

		if(bSkip)
		{
			continue;
		}

		equip_available.List.Add(HE.static.GetFriendlyName(), HE);
	}
}

/////////////////////////////////////////////////////////
//
//	Edit Progression

function HideProgressionPanel()
{
	prog_header.Hide();
	prog_mapsbox.Hide();
	prog_upbutton.Hide();
	prog_dnbutton.Hide();
}

function ShowProgressionPanel()
{
	prog_header.Show();
	prog_mapsbox.Show();
	prog_upbutton.Show();
	prog_dnbutton.Show();

	// Populate the list of missions in the pack.
	PopulateProgressionList();
}

function PopulateProgressionList()
{
	local int i;

	prog_mapsbox.Clear();
	for(i = 0; i < PendingProgression.Length; i++)
	{
		prog_mapsbox.List.Add(PendingProgression[i], , , i);
	}
}

/////////////////////////////////////////////////////////
//
//	Edit Unlocks

function HideUnlocksPanel()
{
	unlock_header.Hide();
	unlock_packlist.Hide();
	unlock_packlistLabel.Hide();
	unlock_unlocklist.Hide();
	unlock_availablelist.Hide();
	unlock_unlocklistLabel.Hide();
	unlock_availablelistLabel.Hide();
	unlock_addUnlock.Hide();
	unlock_remUnlock.Hide();

	pack_use_unlocks.EnableComponent();
}

function ShowUnlocksPanel()
{
	unlock_header.Show();
	unlock_packlist.Show();
	unlock_packlistLabel.Show();
	unlock_unlocklist.Show();
	unlock_availablelist.Show();
	unlock_unlocklistLabel.Show();
	unlock_availablelistLabel.Show();
	unlock_addUnlock.Show();
	unlock_remUnlock.Show();

	// Disable the "Allow Unlocks?" checkbox while we're messing with unlocks
	pack_use_unlocks.DisableComponent();

	// Populate the list of unlocks.
	PopulateUnlocksList();
}

// Only called when showing the unlock panel.
function PopulateUnlocksList()
{
	local int i;

	// Populate the list of missions
	unlock_packlist.List.TypeOfSort = SORT_Numeric;
	unlock_packlist.Clear();
	for(i = 0; i < PendingProgression.Length; i++)
	{
		unlock_packlist.AddItem(PendingProgression[i], , , i);
	}
}

function ConfirmDeleteDlgReturned( int Selection, String passback )
{
    local string Scenario;
    local string Pack;

    if( Selection != QBTN_Yes )
        return;

    lst_scenarios.GetSelectedRow(Scenario, Pack);

    CustomScenarioPage.DeleteScenario(Scenario, Pack);

    RefreshScenariosList();
}

function RefreshScenariosList()
{
    local int i,j;
    local string PackName;

    lst_scenarios.Clear();

    for( i = 0; i < CustomScenarioPage.ScenarioPacks.Length; i++ )
    {
        PackName = CustomScenarioPage.ScenarioPacks[i];

        CustomScenarioPage.SetCustomScenarioPack(PackName);

        for( j = 0; j < CustomScenarioPage.GetPack().ScenarioStrings.Length; j++ )
        {
            lst_scenarios.AddRow(CustomScenarioPage.GetPack().ScenarioStrings[j], PackName);
        }
    }
}

//refresh the activation of cmd_new/edit/delete/duplicate
function UpdateButtonStates()
{
	local string Scenario;
	local string Pack;
	local int i;

	lst_scenarios.GetSelectedRow(Scenario, Pack);

	CustomScenarioPage.SetCustomScenarioPack(Pack);
	CurrentPack = CustomScenarioPage.GetPack();

    //the new button is active as long as we're looking at the scenarios list
    cmd_new.EnableComponent();

    //the other buttons are active if we're looking at the scenarios list and a scenario is selected
    cmd_edit.SetEnabled(lst_scenarios.ActiveRowIndex >= 0);
    cmd_delete.SetEnabled(lst_scenarios.ActiveRowIndex >= 0);

    cmd_play.SetEnabled(lst_scenarios.ActiveRowIndex >= 0);

	pack_use_unlocks.EnableComponent();
	pack_use_progression.EnableComponent();
	pack_edit_equipment.EnableComponent();
	pack_edit_progression.EnableComponent();
	pack_save.EnableComponent();

	// Update all of fields
	pack_name.SetText(Pack);
	pack_use_unlocks.SetChecked(CurrentPack.UseGearUnlocks);
	pack_use_progression.SetChecked(CurrentPack.UseProgression);

	if(!pack_use_unlocks.bChecked)
	{
		pack_edit_unlocks.DisableComponent();
	}
	else
	{
		pack_edit_unlocks.EnableComponent();
	}

	// Set the pending fields to match the current pack
	PendingUseGearUnlocks = CurrentPack.UseGearUnlocks;
	PendingUseProgression = CurrentPack.UseProgression;
	PendingFirstUnlocks.Length = 0;
	PendingSecondUnlocks.Length = 0;
	PendingProgression.Length = 0;
	PendingDisabledEquipment.Length = 0;
	PendingPackName = Pack;

	for(i = 0; i < CurrentPack.FirstEquipmentUnlocks.Length; i++)
	{
		PendingFirstUnlocks[i] = CurrentPack.FirstEquipmentUnlocks[i];
	}

	for(i = 0; i < CurrentPack.SecondEquipmentUnlocks.Length; i++)
	{
		PendingSecondUnlocks[i] = CurrentPack.SecondEquipmentUnlocks[i];
	}

	for(i = 0; i < CurrentPack.DisabledEquipment.Length; i++)
	{
		PendingDisabledEquipment[i] = CurrentPack.DisabledEquipment[i];
	}

	for(i = 0; i < CurrentPack.ScenarioStrings.Length; i++)
	{
		PendingProgression[i] = CurrentPack.ScenarioStrings[i];
	}
}

function lst_scenarios_OnChange(GUIComponent Sender)
{
    UpdateButtonStates();
}

function pack_use_progression_OnChange(GUIComponent Sender)
{
	PendingUseProgression = pack_use_progression.bChecked;
}

function UseUnlocks_OnChange(GUIComponent Sender)
{
	if(!pack_use_unlocks.bChecked)
	{
		pack_edit_unlocks.DisableComponent();
	}
	else
	{
		pack_edit_unlocks.EnableComponent();
	}
	PendingUseGearUnlocks = pack_use_unlocks.bChecked;
}

// CustomScenarioTabPanel overrides
function PopulateFieldsFromScenario(bool NewScenario)
{
}

function GatherScenarioFromFields()
{
}

defaultproperties
{
    ConfirmDeleteString="Are you sure that you wish to delete scenario %1 from pack %2?"
}
