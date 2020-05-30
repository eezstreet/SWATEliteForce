///////////////////////////////////////////////////////////////////////////////
// TargetSensorAction.uc - the TargetSensorAction class
// works in parallel with the TargetSensor to determine if a Target can be hit

class TargetSensorAction extends Tyrion.AI_SensorCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var TargetSensor TargetSensor;
var private	bool bCurrentlyCanHitTarget;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function setupSensors( AI_Resource resource )
{
	TargetSensor = TargetSensor(addSensorClass( class'TargetSensor' ));

}

function cleanup()
{
	super.cleanup();

	if (TargetSensor != None)
	{
		TargetSensor = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function TestCanHitTarget()
{
	local bool bCanHitTarget;

	bCanHitTarget = m_Pawn.CanHit(TargetSensor.Target);

	if (TargetSensor.bCanHitTarget && !bCanHitTarget)
	{
		TargetSensor.NotifyCannotHitTarget();
	}
	else if (!TargetSensor.bCanHitTarget && bCanHitTarget)
	{
		TargetSensor.NotifyCanHitTarget();
	}
}

state Running
{
 Begin:
	assert(m_Pawn != None);

	if (m_Pawn.logTyrion)
		log(Name $ " running!");

	// if the target actor is a pawn, make sure it's conscious
	// in addition we should only be running while someone is interested in our value
	while (((TargetSensor.TargetPawn == None) || class'Pawn'.static.checkConscious(TargetSensor.TargetPawn)) &&
		   (TargetSensor.queryUsage() > 0))
	{
		TestCanHitTarget();
		yield();
	}

	// make sure someone cares
	if (TargetSensor.queryUsage() > 0)
	{
		// the guy's dead, so we can no longer hit them
		if (m_Pawn.logTyrion)
			log(Name $ " says target dead! Notifying sensor!");

		TargetSensor.NotifyCannotHitTarget();
	}

	// wait until we're told to start again
	pause();

	goto('Begin');
}
