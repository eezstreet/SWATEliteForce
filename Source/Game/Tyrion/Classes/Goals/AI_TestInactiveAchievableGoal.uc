//=====================================================================
// AI_TestInactiveAchievableGoal
// Test Class for Goals - this is an inactive / achievable goal
//=====================================================================

class AI_TestInactiveAchievableGoal extends AI_MovementGoal
	editinlinenew;

//=====================================================================
// Variables

//=====================================================================
// Functions

overloaded function construct( AI_resource r, int pri )
{
	super.construct( r );

	priority = pri;
}

function init( AI_Resource r )
{
	super.init( r );

	// userData is always 'None' for deactivation sensors, and != None for activation sensors
	activationSentinel.activateSentinel( self, class'AI_TestSentinelA', r,,, self );
}

//---------------------------------------------------------------------
// Setup deactivation sentinel

function setUpDeactivationSentinel()
{
	deactivationSentinel.activateSentinel( self, class'AI_TestSentinelB', resource,,, None );
}

//=====================================================================

defaultproperties
{
	bInactive = true
	bPermanent = false
}
