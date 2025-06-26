///////////////////////////////////////////////////////////////////////////////
// IdleAimAroundGoal.uc - IdleAimAroundGoal class
// this low priority goal is a permanent goal that causes the AI to look in a different
// location every once in a while

class IdleAimAroundGoal extends AimAroundGoal;
///////////////////////////////////////////////////////////////////////////////

// @NOTE: The idle aim around goal should not procedurally use the upper body!

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	// we never stop
    bPermanent = true

    priority   = 30
    goalName   = "IdleAimAround"

	ExtraDoorWeight   = 0.5
	bUseUpperBodyProcedurally = false
    UpperBodyAnimBehaviorClientId = kUBABCI_IdleAimAround
	bAimOnlyIfCharacterResourcesAvailable = true

	bInitialDelay=true
	MinInitialDelayTime=1.0
	MaxInitialDelayTime=3.0
}
