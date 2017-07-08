///////////////////////////////////////////////////////////////////////////////
// SquadBreachStingAndClearAction.uc - SquadBreachStingAndClearAction class
// this action is used to organize the Officer's breach, sting, & clear behavior

class SquadBreachStingAndClearAction extends SquadBreachThrowGrenadeAndClearAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Events

protected function TriggerDeployingGrenadeSpeech()
{
	ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerDeployingStingSpeech();
}

protected function TriggerThrowGrenadeMoveUpSpeech()
{
	ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerMoveUpStingSpeech();
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

protected function SetThrower()
{
	Thrower = GetThrowingOfficer(Slot_StingGrenade);

	if (Thrower == None)
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
}

protected latent function PreTargetDoorBreached()
{
	if (!IsFirstOfficerThrower() && Breacher != Thrower)
	{
		PrepareToThrowGrenade(Slot_StingGrenade, true);
	}
}

protected latent function PostTargetDoorBreached()
{
	if (IsFirstOfficerThrower() || Breacher == Thrower)
	{
		PrepareToThrowGrenade(Slot_StingGrenade, false);
	}

	ThrowGrenade();
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadBreachStingAndClearGoal'
}
