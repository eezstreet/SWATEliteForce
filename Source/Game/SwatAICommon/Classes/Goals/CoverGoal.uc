///////////////////////////////////////////////////////////////////////////////
// CoverGoal.uc - the CoverGoal class
// behavior that causes the Officer AI to cover a particular location

class CoverGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// copied to our action
var(parameters) vector	CoverLocation;
var(parameters) vector  CoverFromLocation;
var(parameters) vector  CommandOrigin;
var(parameters) bool	bShouldAimAround;

///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, vector inCoverLocation, vector inCoverCommandOrigin, vector inCoverFromLocation, bool bInShouldAimAround )
{
    Super.construct(r);

    CoverLocation     = inCoverLocation;
    CommandOrigin     = inCoverCommandOrigin;
	CoverFromLocation = inCoverFromLocation;
	bShouldAimAround  = bInShouldAimAround;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority = 60
    GoalName = "Cover"
}
