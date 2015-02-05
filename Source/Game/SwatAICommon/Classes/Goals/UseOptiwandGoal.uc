///////////////////////////////////////////////////////////////////////////////
// UseOptiwandGoal.uc - UseOptiwandGoal class
// this goal causes the AI to use a mirror

class UseOptiwandGoal extends SwatWeaponGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) bool	bUseOverloadedViewOrigin;
var(parameters) vector  OverloadedViewOrigin;
var(parameters) bool	bMirrorAroundCorner;
var(parameters) vector  OptiwandViewDirection;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct( AI_Resource r, vector inOptiwandViewDirection )
{
	super.construct( r, priority );

	OptiwandViewDirection = inOptiwandViewDirection;
}

///////////////////////////////////////////////////////////////////////////////
//
// Behavior Manipulation

function SetOverloadedViewOrigin(vector inOverloadedViewOrigin)
{
	bUseOverloadedViewOrigin = true;
	OverloadedViewOrigin = inOverloadedViewOrigin;
}

function SetMirrorAroundCorner()
{
	bMirrorAroundCorner = true;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 80
	goalName = "UseOptiwand"
}
