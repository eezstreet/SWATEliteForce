///////////////////////////////////////////////////////////////////////////////
// AvoidLocationGoal.uc - AvoidLocationGoal class
// this goal that causes an AI to avoid a particular location by running away from it

class AvoidLocationGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) vector	AvoidLocation;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct(AI_Resource r)
{
    // don't use this constructor
    assert(false);
}

overloaded function construct(AI_Resource r, vector inAvoidLocation)
{
	super.construct(r);

    AvoidLocation = inAvoidLocation;
}

overloaded function construct(AI_Resource r, int pri, vector inAvoidLocation)
{
	super.construct(r, pri);

    AvoidLocation = inAvoidLocation;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority = 89
	goalName = "AvoidLocation"
}