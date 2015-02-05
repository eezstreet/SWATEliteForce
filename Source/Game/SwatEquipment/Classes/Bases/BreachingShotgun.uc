///////////////////////////////////////////////////////////////////////////////
class BreachingShotgun extends Shotgun
    implements IFrangibleBreachingDamageType;
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
    if (Victim.IsA('SwatDoor'))
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
