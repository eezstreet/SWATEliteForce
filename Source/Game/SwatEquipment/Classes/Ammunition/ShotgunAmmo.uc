class ShotgunAmmo extends RoundBasedAmmo;

var(ShotgunAmmo) private config bool bPenetratesDoor "Whether this ammo type can penetrate doors";
var(ShotgunAmmo) private config bool OverrideBreach "Whether this ammo type overrides the weapon's breaching chance";
var(ShotgunAmmo) private config float OverrideBreachWoodChance "If OverrideBreach is true, the chance to breach a wooden door per pellet";
var(ShotgunAmmo) private config float OverrideBreachMetalChance "If OverrideBreach is true, the chance to breach a metal door per pellet";

final function bool AmmoOverridesWeaponBreachChance()
{
	return OverrideBreach;
}

final function float GetAmmoBreachChance(bool Wooden)
{
	if(Wooden)
	{
		return OverrideBreachWoodChance;
	}
	return OverrideBreachMetalChance;
}

final function bool WillPenetrateDoor()
{
  return bPenetratesDoor;
}

defaultproperties
{
    bPenetratesDoor=true
    StaticMesh=StaticMesh'Hotel_sm.hot_bath_prodbot2'
}
