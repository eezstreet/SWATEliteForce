///////////////////////////////////////////////////////////////////////////////
// DistanceSensorAction.uc - the DistanceSensorAction class
// works in parallel with the DistanceSensor to determine if a Target can be hit

class DistanceSensorAction extends Tyrion.AI_SensorAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var DistanceSensor DistanceSensor;

///////////////////////////////////////////////////////////////////////////////
// 
// Initialization

function setupSensors( AI_Resource resource )
{
	DistanceSensor = DistanceSensor(addSensorClass( class'DistanceSensor' ));
}

function cleanup()
{
	super.cleanup();

	DistanceSensor = None;
}

///////////////////////////////////////////////////////////////////////////////
// 
// State Code

function TestWithinRequiredDistance()
{
	DistanceSensor.UpdateTarget();

	if (DistanceSensor.IsWithinRequiredDistance())
	{
		DistanceSensor.NotifyWithinRequiredDistance();
	}
	else
	{
		DistanceSensor.NotifyOutsideRequiredDistance();
	}
}

state Running
{
 Begin:
	assert(m_Pawn != None);

//	log(Name $ " running!");

	// wait one tick before starting
	yield();

	// while the moving pawn is alive and we are notifying someone
	while (class'Pawn'.static.checkConscious(pawn()) && (DistanceSensor.queryUsage() > 0))
	{
		TestWithinRequiredDistance();
		sleep(DistanceSensor.DistanceSensorUpdateRate);
	}

	// wait until we're told to start again
	pause();

	goto('Begin');
}
