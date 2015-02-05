///////////////////////////////////////////////////////////////////////////////
// WildGunnerAdjustAimGoal.uc
// this goal is always present on the WildGunner AI class;
// it will cause the AI to aim around while firing;
// it uses no resources

class WildGunnerAdjustAimGoal extends SwatCharacterGoal;

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "WildGunnerAdjustAim"
	priority = 90
}