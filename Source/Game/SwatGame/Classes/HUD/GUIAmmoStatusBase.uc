class GUIAmmoStatusBase extends GUI.GUIMultiComponent
    abstract;

function SetWeaponStatus( Ammunition Ammo );
function SetTacticalAidStatus(int Count, optional Ammunition Ammo);




defaultproperties
{
    bPersistent=True
}
