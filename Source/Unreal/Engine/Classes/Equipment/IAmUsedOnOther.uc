interface IAmUsedOnOther extends IAmAQualifiedUseEquipment;

//An Interface to QualifiedUseEquipment, ie. HandheldEquipment that the Player must Qualify to use.

simulated function UseOn(Actor inOther);
simulated function LatentUseOn(Actor inOther);
simulated function bool CanUseOnOtherNow(Actor Other);
simulated function Actor GetOther();
