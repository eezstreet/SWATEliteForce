///////////////////////////////////////////////////////////////////////////////
// SquadBreachGasAndClearAction.uc - SquadBreachGasAndClearAction class
// this action is used to organize the Officer's breach, gas, & clear behavior

class SquadBreachGasAndClearAction extends SquadBreachThrowGrenadeAndClearAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Events

protected function TriggerDeployingGrenadeSpeech()
{
	ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerDeployingGasSpeech();
}

protected function TriggerThrowGrenadeMoveUpSpeech()
{
	ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerMoveUpGasSpeech();
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

protected function SetThrower()
{
	Thrower = GetThrowingOfficer(Slot_CSGasGrenade);

	if (Thrower == None)
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
}

protected latent function PreTargetDoorBreached()
{
	if (!IsFirstOfficerThrower() && Breacher != Thrower)
	{
		PrepareToThrowGrenade(Slot_CSGasGrenade, true);
	}
}

protected latent function PostTargetDoorBreached()
{
	if (IsFirstOfficerThrower() || Breacher == Thrower)
	{
		PrepareToThrowGrenade(Slot_CSGasGrenade, false);
	}

	ThrowGrenade();
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadBreachGasAndClearGoal'
}
