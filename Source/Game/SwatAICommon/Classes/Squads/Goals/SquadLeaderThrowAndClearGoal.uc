///////////////////////////////////////////////////////////////////////////////
// SquadLeaderThrowAndClearGoal.uc - SquadLeaderThrowAndClearGoal class
// this goal is used to organize the Officer's throw & clear behavior

class SquadLeaderThrowAndClearGoal extends SquadMoveAndClearGoal
	implements Engine.ICareAboutGrenadesGoingOff;
///////////////////////////////////////////////////////////////////////////////

simulated function OnFlashbangWentOff(Pawn Thrower) {
	SquadLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower);
}

simulated function OnCSGasWentOff(Pawn Thrower) {
	SquadLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower);
}

simulated function OnStingerWentOff(Pawn Thrower) {
	SquadLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadLeaderThrowAndClear"
}
