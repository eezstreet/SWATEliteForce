///////////////////////////////////////////////////////////////////////////////
// PlaceWedgeGoal.uc - PlaceWedgeGoal class
// this goal is given to a Officer to place a wedge on a particular door

class PlaceWedgeGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// PlaceWedgeGoal variables

// copied to our action
var(parameters) Door TargetDoor;


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
    goalName   = "PlaceWedge"
}