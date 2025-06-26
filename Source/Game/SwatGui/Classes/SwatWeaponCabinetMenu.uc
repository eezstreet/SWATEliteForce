class SwatWeaponCabinetMenu extends SwatPopupMenuBase;

var(SwatGui) private EditInline Config SwatWeaponCabinetPanel Panel;

var(SWATGui) protected EditInline Config GUIButton		    MyApplyWeaponButton;
var(SWATGui) protected EditInline Config GUIButton		    MyCancelButton;

function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);

    MyApplyWeaponButton.OnClick=InternalOnClick;
    MyCancelButton.OnClick=InternalOnClick;
}

function InternalOnClick(GUIComponent Sender)
{
	switch(Sender)
	{
		case MyApplyWeaponButton:
			SwapWeapon();
			ResumeGame();
			break;
		case MyCancelButton:
			ResumeGame();
			break;
	}
}

// Called whenever we are given the OK to swap weapons
function SwapWeapon()
{
	local class<SwatWeapon> Weapon;
	local class<SwatAmmo> Ammo;

	Weapon = Panel.CurrentWeaponClass;
	Ammo = Panel.CurrentAmmoClass;

	SwatGuiController(Controller).GivePlayerWeapon(Weapon, Ammo);
}

// Called whenever we hit ESC
function ResumeGame()
{
	Controller.CloseMenu();
}
