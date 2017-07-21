///////////////////////////////////////////////////////////////////////////////
// SquadBreachBangAndClearAction.uc - SquadBreachBangAndClearAction class
// this action is used to organize the Officer's breach, bang, & clear behavior

class SquadBreachBangAndClearAction extends SquadBreachThrowGrenadeAndClearAction;
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
// State code

protected function SetThrower()
{
	Thrower = GetThrowingOfficer(Slot_Flashbang);

	if (Thrower == None)
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
}

protected latent function PreTargetDoorBreached()
{
	if (!IsFirstOfficerThrower() && Breacher != Thrower)
	{
		PrepareToThrowGrenade(Slot_Flashbang, true);
	}
}

protected latent function PostTargetDoorBreached()
{
	if (IsFirstOfficerThrower() || Breacher == Thrower)
	{
		PrepareToThrowGrenade(Slot_Flashbang, false);
	}

	ThrowGrenade();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadBreachBangAndClearGoal'
}
