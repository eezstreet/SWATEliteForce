///////////////////////////////////////////////////////////////////////////////
// SquadLeaderThrowAndClearGoal.uc - SquadLeaderThrowAndClearGoal class
// this goal is used to organize the Officer's throw & clear behavior

class SquadLeaderThrowAndClearGoal extends SquadMoveAndClearGoal
	implements Engine.ICareAboutGrenadesGoingOff;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

simulated function OnFlashbangWentOff(Pawn Thrower) {
	SquadLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower, EquipmentSlot.Slot_Flashbang);
}

simulated function OnCSGasWentOff(Pawn Thrower) {
	SquadLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower, EquipmentSlot.Slot_CSGasGrenade);
}

simulated function OnStingerWentOff(Pawn Thrower) {
	SquadLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower, EquipmentSlot.Slot_StingGrenade);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadLeaderThrowAndClear"
}
