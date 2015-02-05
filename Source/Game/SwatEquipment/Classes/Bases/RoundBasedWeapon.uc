class RoundBasedWeapon extends Engine.FiredWeapon;

var config int MagazineSize;

simulated function EquippedHook()
{
    Super.EquippedHook();

    Ammo.UpdateHUD(); 
}

//simulated function UnEquippedHook();  //TMC do we want to blank the HUD's ammo count?
