class FireInterfaceContext extends PlayerInterfaceContext
    perObjectConfig
    config(PlayerInterface_Fire)
    native;

import enum EquipmentSlot from Engine.HandheldEquipment;

var config bool CaresAboutCanBeArrestedNow;
var config bool CanBeArrestedNow;

var config bool CaresAboutCanBeUsedByToolkitNow;
var config bool CanBeUsedByToolkitNow;

var config EquipmentSlot EquipmentSlotForQualify;
var config Material ReticleImage;

var config localized string FireFeedbackText;

defaultproperties
{
    EquipmentSlotForQualify=SLOT_Invalid
}
