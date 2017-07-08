///////////////////////////////////////////////////////////////////////////////
// CompliantSensor.uc - the CompliantSensor class
// a sensor that notifies interested parties when a target is compliant (or no longer alive)

class CompliantSensor extends Tyrion.AI_Sensor;
///////////////////////////////////////////////////////////////////////////////

var Pawn Target;

///////////////////////////////////////////////////////////////////////////////
//
// Notifications

function NotifyTargetCompliant()
{
	SetObjectValue(None);
}

// either the target died or became a threat
function NotifyFailed()
{
	SetObjectValue(None);
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
function setParameters( Pawn inTarget )
{
	assert(inTarget != None);

	Target = inTarget;

	sensorAction.runAction();
}
