///////////////////////////////////////////////////////////////////////////////
// RemoveWedgeGoal.uc - RemoveWedgeGoal class
// this goal is given to a Officer to Remove a wedge on a particular door

class RemoveWedgeGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// RemoveWedgeGoal variables

// copied to our action
var(parameters) Door	TargetDoor;


///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, Door inTargetDoor )
{
    Super.construct(r);

    assert(inTargetDoor != None);
    TargetDoor = inTargetDoor;
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority   = 80
    goalName   = "RemoveWedge"
}