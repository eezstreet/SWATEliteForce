class Lightstick extends Engine.SwatGrenade
	config(SwatEquipment);

import enum EquipmentSlot from Engine.HandheldEquipment;

var config class<LightstickProjectile> LightstickClass;
var config float ThrowVelocity;
var config float AIThrowVelocity;
var config string BaseThirdPersonThrowAnim;
var config name BaseThirdPersonThrowAnimNet;
var config int StartingAmount;

var private bool Used;

simulated function CreateModels()
{
	Super.CreateModels();
}

simulated function UsedHook()
{
    log("Lightstick away!");
}

simulated function OnPostEquipped()
{
    log("Lightstick equipped!");
}

function name GetThirdPersonThrowAnimation()
{
	return 'None';
}

// Lightstick need not be equipped for AIs to use
simulated function bool ValidateUse( optional bool Prevalidate )
{
	return false;
}

simulated latent protected function PreUsed()
{
	Super.PreUsed();
}

simulated function OnUsingFinishedHook()
{
}

simulated function CheckTickEquipped()
{
}

simulated function bool ShouldDisplayReticle()
{
	return false;
}

defaultproperties
{
    Slot=Slot_Lightstick
    LightstickClass=class'SwatEquipment.LightstickProjectile'
	ThrowVelocity=100
	AIThrowVelocity=25
	StartingAmount=25
	UnavailableAfterUsed=false
	BaseThirdPersonThrowAnim="LightStickDrop_"
	BaseThirdPersonThrowAnimNet="LightStickDrop_MP"
	HandsPreThrowAnimation="GlowPreThrow"
	HandsThrowAnimation="GlowThrow"

	InstantUnequip = false
}
