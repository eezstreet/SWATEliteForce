class FireInterfaceDoorRelatedContext extends PlayerInterfaceDoorRelatedContext
    perObjectConfig
    config(PlayerInterface_Fire)
    native;

import enum EquipmentSlot from Engine.HandheldEquipment;

var config bool CaresAboutC2ChargeOnPlayersSide;
var config bool IsC2ChargeOnPlayersSide;

var config EquipmentSlot EquipmentSlotForQualify;
var config Material ReticleImage;

var config localized string FireFeedbackText;

var config name SideEffect;

defaultproperties
{
    EquipmentSlotForQualify=SLOT_Invalid
}
