///////////////////////////////////////////////////////////////////////////////

class UseBreachingShotgunGoal extends OfficerCommandGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var(parameters) private Door TargetDoor;
var(parameters) private NavigationPoint PostBreachPoint;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

// do not use this constructor!
overloaded function construct(AI_Resource r, int pri)	{ assert(false); }

// use this one
overloaded function construct(AI_Resource r, Door inTargetDoor, optional NavigationPoint inPostBreachPoint)
{
    super.construct( r, priority );

    assert(inTargetDoor != None);
    TargetDoor = inTargetDoor;
    PostBreachPoint = inPostBreachPoint;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	priority = 80
	goalName = "UseBreachingShotgun"
}

///////////////////////////////////////////////////////////////////////////////
