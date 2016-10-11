///////////////////////////////////////////////////////////////////////////////
// SquadLeaderThrowAndClearAction.uc - SquadLeaderThrowAndClearAction class
// this action is used to organize the Officer's throw & clear behavior

class SquadLeaderThrowAndClearAction extends SquadThrowGrenadeAndClearAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

var bool grenadeThrown;

///////////////////////////
// Since the thrower is not an AI-controlled officer, we don't need to worry about Formation

protected function bool ShouldThrowerBeFirstOfficer()
{
	return false;
}

protected latent function MoveUpThrower()
{
}

protected function SetThrower()
{
  Thrower = CommandGiver;
}

function Pawn GetThrowingOfficer(EquipmentSlot ThrownItemSlot)
{
  return CommandGiver;
}

///////////////////////////
// Set up the goal to wait for a grenade detonation
///////////////////////////

protected latent function WaitForGrenadeToBeThrown()
{
	while(!grenadeThrown) {
		yield();
	}
}

protected latent function PreTargetDoorOpened()
{
}

protected latent function PostTargetDoorOpened()
{
	WaitForGrenadeToBeThrown();
}

protected latent function PostTargetDoorBreached()
{
	WaitForGrenadeToBeThrown();
}

protected latent function PrepareToMoveThroughOpenDoorway()
{
	WaitForGrenadeToBeThrown();
}

function GrenadeGotDetonated(Pawn PawnThrower) {
	if(PawnThrower == Thrower) {
		grenadeThrown = true;
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadLeaderThrowAndClearGoal'
}
