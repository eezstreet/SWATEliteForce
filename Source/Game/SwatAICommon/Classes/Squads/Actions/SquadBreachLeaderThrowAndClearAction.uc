///////////////////////////////////////////////////////////////////////////////
// SquadBreachLeaderThrowAndClearAction.uc - SquadBreachLeaderThrowAndClearAction class
// this action is used to organize the Officer's breach, bang, & clear behavior

class SquadBreachLeaderThrowAndClearAction extends SquadBreachThrowGrenadeAndClearAction;
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
  return;
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
//

protected latent function WaitForGrenadeToBeThrown()
{
	while(!grenadeThrown) {
		yield();
	}
}

protected latent function PrepareToMoveThroughOpenDoorway()
{
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

function GrenadeGotDetonated(Pawn PawnThrower) {
	if(PawnThrower == Thrower) {
		grenadeThrown = true;
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadBreachLeaderThrowAndClearGoal'
}
