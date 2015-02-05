///////////////////////////////////////////////////////////////////////////////
// SquadGasAndClearAction.uc - SquadGasAndClearAction class
// this action is used to organize the Officer's gas & clear behavior

class SquadGasAndClearAction extends SquadThrowGrenadeAndClearAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Events

protected function TriggerThrowGrenadeMoveUpSpeech()
{
	ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerMoveUpGasSpeech();
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

protected function SetThrower()
{
	Thrower = GetThrowingOfficer(Slot_CSGasGrenade);	
	
	if (Thrower == None)
	{
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
	}
}

protected latent function PrepareToMoveThroughOpenDoorway()
{
	PrepareToThrowGrenade(Slot_CSGasGrenade, false);
	ThrowGrenade();
}

protected latent function PreTargetDoorOpened()
{
	if (!IsFirstOfficerThrower())
	{
		PrepareToThrowGrenade(Slot_CSGasGrenade, true);
	}
}

protected latent function PostTargetDoorOpened()
{
	if (IsFirstOfficerThrower())
	{
		PrepareToThrowGrenade(Slot_CSGasGrenade, false);
	}

	ThrowGrenade();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadGasAndClearGoal'
}