///////////////////////////////////////////////////////////////////////////////
// DoorOpeningSensor.uc - the DoorOpeningSensor class
// a sensor that keeps track of a door and lets us know when the door opens

class DoorOpeningSensor extends Tyrion.AI_Sensor
	implements IInterestedInDoorOpening;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var array<Door> TargetDoors;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();
	
	ClearDoors();
}

///////////////////////////////////////////////////////////////////////////////
//
// IInterestedInDoorOpening Notifications

// notification that a door has opened
function NotifyDoorOpening(Door TargetDoor)
{
	setObjectValue(TargetDoor);
}


// Initialize set the sensor's parameters
// 'target': the pawn this sensor is interested in
function setParameters(Door inTargetDoor)
{
	AddDoor(inTargetDoor);
}

function AddDoor(Door inTargetDoor)
{
	assertWithDescription((inTargetDoor != None), "DoorSensor::AddDoor - inTargetDoor passed in is None!");

	// register with the door to find out when it openes
	TargetDoors[TargetDoors.Length] = inTargetDoor;
	ISwatDoor(inTargetDoor).RegisterInterestedInDoorOpening(self);
}

function ClearDoors()
{
	while (TargetDoors.Length > 0)
	{
		ISwatDoor(TargetDoors[0]).UnRegisterInterestedInDoorOpening(self);
		TargetDoors.Remove(0, 1);
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}