///////////////////////////////////////////////////////////////////////////////
// TargetSensor.uc - the TargetSensor class
// a sensor that keeps track of whether or not a particular target can be hit by the AI

class TargetSensor extends Tyrion.AI_Sensor;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var Actor	Target;
var Pawn	TargetPawn;
var bool	bCanHitTarget;

///////////////////////////////////////////////////////////////////////////////
//
// Vision Notifications

function NotifyCanHitTarget()
{
	bCanHitTarget = true;
	setObjectValue( Target );
}

function NotifyCannotHitTarget()
{
	bCanHitTarget = false;
	setObjectValue( None );
}

// Initialize set the sensor's parameters
// 'target': the pawn this sensor is interested in
function setParameters( Actor inTarget )
{
	assertWithDescription((inTarget != None), "TargetSensor::setParameters - inTarget passed in is None!");

	if (Target != inTarget)
	{
		Target     = inTarget;
		TargetPawn = Pawn(Target);

		if (TargetSensorAction(sensorAction).pawn().CanHitTarget(target))
			NotifyCanHitTarget();
		else
			NotifyCannotHitTarget();
	}

	// start the sensor!
	assert(sensorAction != None);
	assert(sensorAction.IsA('TargetSensorAction'));

	if (sensorAction.IsIdle())
	{
		if (sensorAction.m_Pawn.logTyrion)
			log(sensorAction.Name $ " told to run by " $ name);

		sensorAction.runAction();
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}