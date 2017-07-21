///////////////////////////////////////////////////////////////////////////////
// SquadBangAndClearAction.uc - SquadBangAndClearAction class
// this action is used to organize the Officer's bang & clear behavior

class SquadBangAndClearAction extends SquadThrowGrenadeAndClearAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Events

protected function TriggerDeployingGrenadeSpeech()
{
	ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerDeployingFlashbangSpeech();
}

protected function TriggerThrowGrenadeMoveUpSpeech()
{
	ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerMoveUpBangsSpeech();
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

protected function SetThrower()
{
	Thrower = GetThrowingOfficer(Slot_Flashbang);	
	
	if (Thrower == None)
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
}

protected latent function PrepareToMoveThroughOpenDoorway()
{
	PrepareToThrowGrenade(Slot_Flashbang, false);
	ThrowGrenade();
}

protected latent function PreTargetDoorOpened()
{
	if (!IsFirstOfficerThrower())
	{
		PrepareToThrowGrenade(Slot_Flashbang, true);
	}
}

protected latent function PostTargetDoorOpened()
{
	if (IsFirstOfficerThrower())
	{
		PrepareToThrowGrenade(Slot_Flashbang, false);
	}

	ThrowGrenade();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadBangAndClearGoal'
}