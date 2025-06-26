class SwatWeaponCabinetPanel extends SwatGUIPanel;

import enum WeaponEquipClass from Engine.SwatWeapon;

var(SWATGui) protected EditInline Config GUIComboBox MyWeaponCategoryBox;
var(SWATGui) protected EditInline Config GUIComboBox MyWeaponBox;
var(SWATGui) protected EditInline Config GUIComboBox MyAmmoBox;
var(SWATGui) protected EditInline Config GUIScrollTextBox MyDescriptionBox;
var(SWATGui) protected EditInline Config GUIImage MyPreviewBox;
var() protected localized config array<string> WeaponCategoryNames;

var public class<SwatWeapon> CurrentWeaponClass;
var public class<SwatAmmo> CurrentAmmoClass;
var protected array<class<SwatWeapon> > AllWeapons;
var private bool Repopulating;

// Add a new ammo to the thing
protected function AddNewAmmo(string AmmoType)
{
	local class<SwatAmmo> AmmoItem;
	local class AmmoClass;

	AmmoClass = class(DynamicLoadObject(AmmoType, class'Class'));
	AmmoItem = class<SwatAmmo>(AmmoClass);

	MyAmmoBox.AddItem(AmmoItem.static.GetFriendlyName(), AmmoItem);
}

// A new weapon has been selected. Get the ammo types and put them into MyAmmoBox.
protected function RepopulateAmmoInformationForNewWeapon()
{
	local class<SwatWeapon> Weapon;
	local int i;
	local string Description;

	MyAmmoBox.Clear();

	Weapon = class<SwatWeapon>(MyWeaponBox.GetObject());

	CurrentWeaponClass = Weapon;
	for(i = 0; i < CurrentWeaponClass.default.PlayerAmmoOption.Length; i++)
	{
		AddNewAmmo(CurrentWeaponClass.default.PlayerAmmoOption[i]);
	}

	// Set the description
	Description = Weapon.static.GetDescription();
	MyDescriptionBox.SetContent(Description);

	// Set the image
	MyPreviewBox.Image = Weapon.static.GetGUIImage();
}

// A new category has been selected. Get the weapons for this category and put them into MyWeaponBox.
protected function RepopulateWeaponInformationForNewCategory()
{
	local int Category;
	local int i;
	local class<SwatWeapon> WeaponClass;

	MyWeaponBox.Clear();

	Category = MyWeaponCategoryBox.GetInt();
	for(i = 0; i < AllWeapons.Length; i++)
	{
		WeaponClass = AllWeapons[i];
		if(int(WeaponClass.default.WeaponCategory) == Category)
		{
			MyWeaponBox.AddItem(WeaponClass.static.GetFriendlyName(), WeaponClass);
		}
	}
}

// A new piece of ammo was selected. Change the description to match it.
protected function ChangeAmmoDescription()
{
	local string Description;
	local class<SwatAmmo> AmmoClass;

	AmmoClass = class<SwatAmmo>(MyAmmoBox.GetObject());
	Description = AmmoClass.static.GetDescription();

	MyDescriptionBox.SetContent(Description);

	CurrentAmmoClass = AmmoClass;
}

// A combo box has been changed
function InternalOnChange(GUIComponent Sender)
{
	switch(Sender)
	{
		case MyWeaponCategoryBox:
			RepopulateWeaponInformationForNewCategory();
			break;
		case MyWeaponBox:
			Repopulating = true;
			RepopulateAmmoInformationForNewWeapon();
			Repopulating = false;
			break;
		case MyAmmoBox:
			if(!Repopulating)
			{
				ChangeAmmoDescription();
			}
			break;
	}
}

// Initialize everything
function InitComponent(GUIComponent MyOwner)
{
	local int i;
	local class LoadedClass;
	local class<SwatWeapon> WeaponClass;

	Super.InitComponent(MyOwner);

	AllWeapons.Length = 0;

	for(i = 0; i < GC.AvailableEquipmentPockets[0].EquipmentClassName.Length - 1; i++)
	{
		LoadedClass = class(DynamicLoadObject( GC.AvailableEquipmentPockets[0].EquipmentClassName[i], class'Class'));
		WeaponClass = class<SwatWeapon>(LoadedClass);
		AllWeapons[AllWeapons.Length] = WeaponClass;
	}

	for(i = 0; i < WeaponCategoryNames.Length; i++)
	{
		MyWeaponCategoryBox.AddItem(WeaponCategoryNames[i], , , i);
	}

	MyWeaponCategoryBox.OnChange = InternalOnChange;
	MyWeaponBox.OnChange = InternalOnChange;
	MyAmmoBox.OnChange = InternalOnChange;
}

defaultproperties
{
	WeaponCategoryNames[0]="Uncategorized"
	WeaponCategoryNames[1]="Assault Rifles"
	WeaponCategoryNames[2]="Marksman Rifles"
	WeaponCategoryNames[3]="Submachine Guns"
	WeaponCategoryNames[4]="Shotguns"
	WeaponCategoryNames[5]="Light Machine Guns"
	WeaponCategoryNames[6]="Machine Pistols"
	WeaponCategoryNames[7]="Pistols"
	WeaponCategoryNames[8]="Less Lethal"
	WeaponCategoryNames[9]="Grenade Launchers"
	WeaponCategoryNames[10]="No Weapon"
}
