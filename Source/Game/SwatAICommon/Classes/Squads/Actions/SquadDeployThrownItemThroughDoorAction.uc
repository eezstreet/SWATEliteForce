///////////////////////////////////////////////////////////////////////////////
// SquadDeployThrownItemThroughDoorAction.uc - SquadDeployThrownItemThroughDoorAction class
// this action is used to organize the Officer's deploy thrown item through door behavior

class SquadDeployThrownItemThroughDoorAction extends SquadThrowGrenadeAndClearAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// automatically copied to our action
var(parameters) EquipmentSlot	ThrownItemSlot;

///////////////////////////////////////////////////////////////////////////////
//
// Events

protected function TriggerThrowGrenadeMoveUpSpeech()
{
	switch(ThrownItemSlot)
	{
		case Slot_Flashbang:
			ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerMoveUpBangsSpeech();
			break;

		case Slot_CSGasGrenade:
			ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerMoveUpGasSpeech();
			break;

		case Slot_StingGrenade:
			ISwatOfficer(Thrower).GetOfficerSpeechManagerAction().TriggerMoveUpStingSpeech();
			break;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

protected function SetThrower()
{
	Thrower = GetThrowingOfficer(ThrownItemSlot);	
	
	if (Thrower == None)
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
}

protected latent function PrepareToMoveThroughOpenDoorway()
{
	PrepareToThrowGrenade(ThrownItemSlot, false);
	ThrowGrenade();
}

protected latent function PreTargetDoorOpened()
{
	if (!IsFirstOfficerThrower())
	{
		PrepareToThrowGrenade(ThrownItemSlot, true);
	}
}

protected latent function PostTargetDoorOpened()
{
	if (IsFirstOfficerThrower())
	{
		PrepareToThrowGrenade(ThrownItemSlot, false);
	}

	ThrowGrenade();
}

state Running
{
 Begin:
	StackUpSquad(true);

	// set up who's doing what
	SetupOfficerRoles();

	PrepareToMoveSquad();		// <-- WaitForZulu() happens in here

	// don't succeed, just wait
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'SquadDeployThrownItemThroughDoorGoal'
}