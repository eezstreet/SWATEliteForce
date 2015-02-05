///////////////////////////////////////////////////////////////////////////////
// AimAtPointGoal.uc - AimAtPointGoal class
// The goal that causes the weapon resource to aim at a particular point with
// the current weapon

class AimAtPointGoal extends SwatWeaponGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// copied to our action
var(parameters) vector	Point;

///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, vector inPoint)
{
    Super.construct(r, priority);

	Point = inPoint;
}

overloaded function construct( AI_Resource r, int pri, vector inPoint)
{
    Super.construct(r, pri);

	Point = inPoint;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority = 75
    GoalName = "AimAtPoint"
}

