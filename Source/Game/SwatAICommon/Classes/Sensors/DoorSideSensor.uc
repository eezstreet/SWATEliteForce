///////////////////////////////////////////////////////////////////////////////
// DoorSideSensor.uc - the DoorSideSensor class
// a sensor that notifies interested parties when a target is on a particular 
// side (left or right) of a door

class DoorSideSensor extends Tyrion.AI_Sensor;
///////////////////////////////////////////////////////////////////////////////

var Actor Target;
var Door  Door;
var bool  bNotifyOnLeftSide;

///////////////////////////////////////////////////////////////////////////////
//
// Notifications

function NotifyTargetOnSide()
{
	SetObjectValue(Target);
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	Target = None;
}

///////////////////////////////////////////////////////////////////////////////
//
// Setup

// Initialize set the sensor's parameters
// 'target': the pawn this sensor is interested in
function setParameters( Actor inTarget, Door inDoor, bool inNotifyOnLeftSide )
{
	assert(inTarget != None);
	Target = inTarget;

	assert(inDoor != None);
	Door = inDoor;

	bNotifyOnLeftSide = inNotifyOnLeftSide;

	sensorAction.runAction();
}
