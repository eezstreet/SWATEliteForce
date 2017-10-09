///////////////////////////////////////////////////////////////////////////////
class Shotgun extends RoundBasedWeapon;
///////////////////////////////////////////////////////////////////////////////

var(Shotgun) config float WoodBreachingChance "The chance to breach a wooden door, per pellet.";
var(Shotgun) config float MetalBreachingChance "The chance to breach a metal door, per pellet.";
var(Shotgun) config bool IgnoreAmmoOverrides "Whether to ignore breaching chance overrides from ammo types.";

function bool ShouldBreach(float BreachingChance)
{
	return FRand() < BreachingChance;
}

function bool ShouldPenetrateMaterial(float BreachingChance)
{
  local ShotgunAmmo ShotgunAmmo;

  ShotgunAmmo = ShotgunAmmo(Ammo);
  assertWithDescription(ShotgunAmmo != None, "[eezstreet] Shotgun "$self$" is not using ShotgunAmmo!");

  if(!ShotgunAmmo.WillPenetrateDoor())
    return false;

  return FRand() < BreachingChance;
}

simulated function bool HandleBallisticImpact(
    Actor Victim,
    vector HitLocation,
    vector HitNormal,
    vector NormalizedBulletDirection,
    Material HitMaterial,
    ESkeletalRegion HitRegion,
    out float Momentum,
    vector ExitLocation,
    vector ExitNormal,
    Material ExitMaterial
    )
{
	local vector PlayerToDoor;
	local float MaxDoorDistance;
	local float BreachingChance;
	local ShotgunAmmo ShotgunAmmo;

	ShotgunAmmo = ShotgunAmmo(Ammo);

	if(Role == Role_Authority)  // ONLY do this on the server!!
	{
		MaxDoorDistance = 99.45;		//1.5 meters in UU
    	PlayerToDoor = HitLocation - Owner.Location;

    	switch (HitMaterial.MaterialVisualType)
    	{
	    	case MVT_ThinMetal:
	    	case MVT_ThickMetal:
	    	case MVT_Default:
				if(!IgnoreAmmoOverrides && ShotgunAmmo.AmmoOverridesWeaponBreachChance())
				{
					BreachingChance = ShotgunAmmo.GetAmmoBreachChance(false);
				}
				else
				{
					BreachingChance = MetalBreachingChance;
				}
	    		break;
	    	case MVT_Wood:
				if(!IgnoreAmmoOverrides && ShotgunAmmo.AmmoOverridesWeaponBreachChance())
				{
					BreachingChance = ShotgunAmmo.GetAmmoBreachChance(true);
				}
				else
				{
					BreachingChance = WoodBreachingChance;
				}
	    		break;
	    	default:
	    		BreachingChance = 0;
	    		break;
    	}

      if (Victim.IsA('SwatDoor') && PlayerToDoor Dot PlayerToDoor < MaxDoorDistance*MaxDoorDistance && ShouldBreach(BreachingChance) )
      {
        IHaveSkeletalRegions(Victim).OnSkeletalRegionHit(
                HitRegion,
                HitLocation,
                HitNormal,
                0,                  //damage: unimportant for breaching a door
                GetDamageType(),
                Owner);
        if(!ShouldPenetrateMaterial(BreachingChance))
        {
          Momentum = 0; // All of the momentum is lost
        }
      }

	}

	// We should still consider it to have ballistic impacts
	return Super.HandleBallisticImpact(
	    Victim,
	    HitLocation,
	    HitNormal,
	    NormalizedBulletDirection,
	    HitMaterial,
	    HitRegion,
	    Momentum,
	    ExitLocation,
	    ExitNormal,
	    ExitMaterial);
}

defaultproperties
{
	WoodBreachingChance = 0.1;
	MetalBreachingChance = 0.05;
}
