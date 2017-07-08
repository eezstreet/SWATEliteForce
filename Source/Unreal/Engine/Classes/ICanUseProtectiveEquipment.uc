interface ICanUseProtectiveEquipment extends IHaveSkeletalRegions;

import enum ESkeletalRegion from Actor;

//only one protection may be specified for any SkeletalRegion
simulated function SetProtection(ESkeletalRegion Region, ProtectiveEquipment Protection);
simulated function bool HasProtection(name ProtectionClass);

simulated function SkeletalRegionInformation GetSkeletalRegionInformation(ESkeletalRegion Region);
simulated function ProtectiveEquipment GetSkeletalRegionProtection(ESkeletalRegion Region);
