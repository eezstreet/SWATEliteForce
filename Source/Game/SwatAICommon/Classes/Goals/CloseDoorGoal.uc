///////////////////////////////////////////////////////////////////////////////
// CloseDoorGoal.uc - CloseDoorGoal class
// The goal that causes the AI to Close a door

class CloseDoorGoal extends MoveToDoorGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) bool CloseDoorFromBehind;			// tells us that we don't want to turn around while closing this door
var(parameters) bool CloseDoorFromLeft;				// tells us that we want to close the door from the left side

///////////////////////////////////////////////////////////////////////////////
// 
// Opposite Sides

function SetCloseDoorFromBehind(bool bInCloseDoorFromBehind)
{
	CloseDoorFromBehind = bInCloseDoorFromBehind;
}

function SetCloseDoorFromLeft(bool bInCloseDoorFromLeft)
{
	CloseDoorFromLeft = bInCloseDoorFromLeft;
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 75
	goalName = "CloseDoor"
}