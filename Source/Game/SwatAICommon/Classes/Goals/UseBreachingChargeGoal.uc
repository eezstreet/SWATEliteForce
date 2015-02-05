///////////////////////////////////////////////////////////////////////////////
// UseBreachingChargeGoal.uc - UseBreachingChargeGoal class
// this goal causes the AI to place a breaching charge on a door, move to a 
//  safe location, and then blow the door.

class UseBreachingChargeGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var(parameters) private Door					TargetDoor;
var(parameters) private	NavigationPoint			SafeLocation;
var(parameters) IInterestedInDetonatorEquipping InterestedInDetonatorEquippingClient;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

// do not use this constructor!
overloaded function construct( AI_Resource r, int pri)	{ assert(false); }

// use this one
overloaded function construct( AI_Resource r, Door inTargetDoor, NavigationPoint inSafeLocation)
{
	super.construct( r, priority );
	
	assert(inTargetDoor != None);
	TargetDoor = inTargetDoor;
	
	SafeLocation = inSafeLocation;
}

///////////////////////////////////////////////////////////////////////////////
//
// Detonator Equipping
function SetInterestedInDetonatorEquippingClient(IInterestedInDetonatorEquipping inClient)
{
	assert(InClient != None);
	InterestedInDetonatorEquippingClient = inClient;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 60
	goalName = "UseBreachingCharge"
}
