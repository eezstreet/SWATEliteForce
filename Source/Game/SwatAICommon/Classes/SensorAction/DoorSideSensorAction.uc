///////////////////////////////////////////////////////////////////////////////
// DoorSideSensorAction.uc - the DoorSideSensorAction class
// lets us know when a particular target is on a particular side of a door

class DoorSideSensorAction extends Tyrion.AI_SensorCharacterAction;
///////////////////////////////////////////////////////////////////////////////

var DoorSideSensor DoorSideSensor;

///////////////////////////////////////////////////////////////////////////////
// 
// Initialization / Cleanup

function setupSensors( AI_Resource resource )
{
	DoorSideSensor = DoorSideSensor(addSensorClass( class'DoorSideSensor' ));
}

function cleanup()
{
	super.cleanup();

	if (DoorSideSensor != None)
	{
		DoorSideSensor = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
// 
// State Code

state Running
{
 Begin:
	assert(m_Pawn != None);

	// while someone is waiting for the info, test to see if we're on the left side
	while (DoorSideSensor.queryUsage() > 0)
	{
		if (DoorSideSensor.bNotifyOnLeftSide == ISwatDoor(DoorSideSensor.Door).ActorIsToMyLeft(DoorSideSensor.Target))
		{
			DoorSideSensor.NotifyTargetOnSide();
		}

		// do nothing
		yield();
	}

	// wait until it's time to start again, we'll be notified
	pause();
	goto('Begin');
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}