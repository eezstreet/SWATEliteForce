///////////////////////////////////////////////////////////////////////////////
// SquadBreachLeaderThrowAndClearGoal.uc - SquadBreachLeaderThrowAndClearGoal class
// this goal is used to organize the Officer's breach, throw, & clear behavior

class SquadBreachLeaderThrowAndClearGoal extends SquadBreachAndClearGoal
	implements Engine.ICareAboutGrenadesGoingOff;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

simulated function OnFlashbangWentOff(Pawn Thrower) {
	SquadBreachLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower, EquipmentSlot.Slot_Flashbang);
}

simulated function OnCSGasWentOff(Pawn Thrower) {
	SquadBreachLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower, EquipmentSlot.Slot_CSGasGrenade);
}

simulated function OnStingerWentOff(Pawn Thrower) {
	SquadBreachLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower, EquipmentSlot.Slot_StingGrenade);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadBreachLeaderThrowAndClear"
}
