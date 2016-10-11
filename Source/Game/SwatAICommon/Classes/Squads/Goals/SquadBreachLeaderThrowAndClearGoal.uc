///////////////////////////////////////////////////////////////////////////////
// SquadBreachLeaderThrowAndClearGoal.uc - SquadBreachLeaderThrowAndClearGoal class
// this goal is used to organize the Officer's breach, throw, & clear behavior

class SquadBreachLeaderThrowAndClearGoal extends SquadBreachAndClearGoal
	implements Engine.ICareAboutGrenadesGoingOff;
///////////////////////////////////////////////////////////////////////////////

simulated function OnFlashbangWentOff(Pawn Thrower) {
	SquadBreachLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower);
}

simulated function OnCSGasWentOff(Pawn Thrower) {
	SquadBreachLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower);
}

simulated function OnStingerWentOff(Pawn Thrower) {
	SquadBreachLeaderThrowAndClearAction(achievingAction).GrenadeGotDetonated(Thrower);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadBreachLeaderThrowAndClear"
}
