interface IHaveSkeletalRegions;

import enum ESkeletalRegion from Actor;

// Notification that we were hit
simulated function OnSkeletalRegionHit(ESkeletalRegion RegionHit, vector HitLocation, vector HitNormal, int Damage, class<DamageType> DamageType, Actor Instigator);
