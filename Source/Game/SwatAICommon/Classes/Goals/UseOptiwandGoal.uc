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
var(parameters) bool	bCheckingForTrap;
var(parameters) ISwatDoor	TargetDoor;	// NOTE: only currently hooked up to CheckTrapsAction.
var(parameters) bool	bTrapAndMirror;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct( AI_Resource r, vector inOptiwandViewDirection,
	optional bool bTrap, optional ISwatDoor Door, optional bool bAlsoMirror )
{
	super.construct( r, priority );

	OptiwandViewDirection = inOptiwandViewDirection;
	bCheckingForTrap = bTrap;
	TargetDoor = Door;
	bTrapAndMirror = bAlsoMirror;
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
