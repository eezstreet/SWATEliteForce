class GUIAmmoStatusBase extends GUI.GUIMultiComponent
    abstract;

function SetWeaponStatus( Ammunition Ammo );
function SetTacticalAidStatus(int Count, optional HandheldEquipment Equipment, optional Ammunition Ammo);




defaultproperties
{
    bPersistent=True
}
