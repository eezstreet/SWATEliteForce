///////////////////////////////////////////////////////////////////////////////
// SquadStingAndClearAction.uc - SquadStingAndClearAction class
// this action is used to organize the Officer's sting & clear behavior

class SquadStingAndClearAction extends SquadThrowGrenadeAndClearAction;
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
// State Code

protected function SetThrower()
{
	Thrower = GetThrowingOfficer(Slot_StingGrenade);	
	
	if (Thrower == None)
	{
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
	}
}

protected latent function PrepareToMoveThroughOpenDoorway()
{
	PrepareToThrowGrenade(Slot_StingGrenade, false);
	ThrowGrenade();
}

protected latent function PreTargetDoorOpened()
{
	if (!IsFirstOfficerThrower())
	{
		PrepareToThrowGrenade(Slot_StingGrenade, true);
	}
}

protected latent function PostTargetDoorOpened()
{
	if (IsFirstOfficerThrower())
	{
		PrepareToThrowGrenade(Slot_StingGrenade, false);
	}

	ThrowGrenade();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadStingAndClearGoal'
}