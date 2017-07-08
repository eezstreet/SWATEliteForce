///////////////////////////////////////////////////////////////////////////////
// CompliantSensorAction.uc - the CompliantSensorAction class
// lets us know when a specified has become compliant

class CompliantSensorAction extends Tyrion.AI_SensorCharacterAction;
///////////////////////////////////////////////////////////////////////////////

var CompliantSensor CompliantSensor;

///////////////////////////////////////////////////////////////////////////////
// 
// Initialization / Cleanup

function setupSensors( AI_Resource resource )
{
	CompliantSensor = CompliantSensor(addSensorClass( class'CompliantSensor' ));
}

function cleanup()
{
	super.cleanup();

	if (CompliantSensor != None)
	{
		CompliantSensor = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
// 
// State Code

state Running
{
 Begin:
	assert(m_Pawn != None);

	// while the the target we're watching is alive, not compliant, and not a threat (if a SwatEnemy)
	while (class'Pawn'.static.checkConscious(CompliantSensor.Target) && (CompliantSensor.queryUsage() > 0) &&
			! ISwatAI(CompliantSensor.Target).IsCompliant() &&
			(!CompliantSensor.Target.IsA('SwatEnemy') || ! ISwatEnemy(CompliantSensor.Target).IsAThreat()))
	{
		// do nothing
		yield();
	}

	// make sure someone cares.
	if (CompliantSensor.queryUsage() > 0)
	{
		if (class'Pawn'.static.checkConscious(CompliantSensor.Target) && ISwatAI(CompliantSensor.Target).IsCompliant())
		{
			// if we got out of the above loop, than we are no longer threatened, let the sensor know
			CompliantSensor.NotifyTargetCompliant();
		}
		else
		{
			CompliantSensor.NotifyFailed();
		}
	}

	// wait until it's time to start again, we'll be notified
	pause();
	goto('Begin');
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}