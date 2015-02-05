class ClipBasedWeapon extends Engine.FiredWeapon;

simulated function EquippedHook()
{
    Super.EquippedHook();

    Ammo.UpdateHUD(); 
}

//simulated function UnEquippedHook();  //TMC do we want to blank the HUD's ammo count?
