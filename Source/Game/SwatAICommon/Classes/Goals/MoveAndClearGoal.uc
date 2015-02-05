///////////////////////////////////////////////////////////////////////////////
// MoveAndClearGoal.uc - MoveAndClearGoal class
// this goal is given to Officers when they should move and clear a room

class MoveAndClearGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// copied to our action
var(parameters) ClearPoint	TargetClearPoint;
var(parameters) vector		CommandOrigin;
var(parameters) bool		bShouldAnnounceClear;


///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, ClearPoint inClearPoint, vector inCommandOrigin, bool bInShouldAnnounceClear)
{
    Super.construct(r);

    assert(inClearPoint != None);
    TargetClearPoint = inClearPoint;

	bShouldAnnounceClear = bInShouldAnnounceClear;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority   = 90
    goalName   = "MoveAndClear"
}