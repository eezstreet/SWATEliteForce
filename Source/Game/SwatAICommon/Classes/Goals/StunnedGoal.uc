///////////////////////////////////////////////////////////////////////////////
// StunnedGoal.uc - StunnedGoal class
// this goal that causes an AI to react to being stunned

class StunnedGoal extends SwatCharacterGoal
	abstract;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) vector	StunningDeviceLocation;
var(parameters) float	StunnedDuration;
var(parameters) bool	bShouldRunFromStunningDevice;
var(parameters) bool	bPlayedReaction;
var(parameters) bool    bComplexFlee;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct(AI_Resource r)
{
    // don't use this constructor
    assert(false);
}

overloaded function construct(AI_Resource r, vector inStunningDeviceLocation, float inStunnedDuration)
{
	super.construct(r);

    StunningDeviceLocation = inStunningDeviceLocation;
	StunnedDuration        = inStunnedDuration;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority = 95
	bShouldRunFromStunningDevice=true
	bComplexFlee=false
}
