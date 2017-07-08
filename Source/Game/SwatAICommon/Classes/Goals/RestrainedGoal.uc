///////////////////////////////////////////////////////////////////////////////
// RestrainedGoal.uc - RestrainedGoal class
// The goal that causes the AI to be restrained

class RestrainedGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters)	Pawn	Restrainer;	// pawn that we will be working with

///////////////////////////////////////////////////////////////////////////////
//
// Constructor

overloaded function construct( AI_Resource r, Pawn inRestrainer)
{
	super.construct( r );

	assert(inRestrainer != None);
	Restrainer = inRestrainer;
}

///////////////////////////////////////////////////////////////////////////////

// Restrained needs to be permanent because if it is interrupted (like by being shot),
// the restrained behavior needs to restart

defaultproperties
{
	priority   = 98
	goalName   = "Restrained"
	bPermanent = true
}