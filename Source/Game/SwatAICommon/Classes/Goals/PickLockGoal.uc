///////////////////////////////////////////////////////////////////////////////
// PickLockGoal.uc - PickLockGoal class
// this goal causes the AI to use the toolkit to pick a lock on a door

class PickLockGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) Door			TargetDoor;
var(parameters) NavigationPoint PostPickLockDestination;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

// do not use this constructor!
overloaded function construct( AI_Resource r, int pri)	{ assert(false); }

// use this one
overloaded function construct( AI_Resource r, Door inTargetDoor, NavigationPoint inPostPickLockDestination)
{
	super.construct( r, priority );
	
	assert(inTargetDoor != None);
	TargetDoor = inTargetDoor;
	
	// if there's no post pick lock destination, then we don't move to it
	PostPickLockDestination = inPostPickLockDestination;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 80
	goalName = "PickLock"
}
