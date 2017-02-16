///////////////////////////////////////////////////////////////////////////////
class Shotgun extends RoundBasedWeapon;
///////////////////////////////////////////////////////////////////////////////

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
	MaxDoorDistance = 99.45;		//1.5 meters in UU
	PlayerToDoor = HitLocation - Owner.Location;
    if (Victim.IsA('SwatDoor') && (PlayerToDoor Dot PlayerToDoor) < MaxDoorDistance*MaxDoorDistance)
        IHaveSkeletalRegions(Victim).OnSkeletalRegionHit(
                HitRegion, 
                HitLocation, 
                HitNormal, 
                0,                  //damage: unimportant for breaching a door
                GetDamageType(), 
                Owner);

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
