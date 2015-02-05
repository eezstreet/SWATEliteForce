///////////////////////////////////////////////////////////////////////////////
// ArrestedSensorAction.uc - the ArrestedSensorAction class
// lets us know when a specified has become arrested

class ArrestedSensorAction extends Tyrion.AI_SensorCharacterAction;
///////////////////////////////////////////////////////////////////////////////

var ArrestedSensor ArrestedSensor;

///////////////////////////////////////////////////////////////////////////////
// 
// Initialization / Cleanup

function setupSensors( AI_Resource resource )
{
	ArrestedSensor = ArrestedSensor(addSensorClass( class'ArrestedSensor' ));
}

function cleanup()
{
	super.cleanup();

	if (ArrestedSensor != None)
	{
		ArrestedSensor = None;
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
	while (class'Pawn'.static.checkConscious(ArrestedSensor.Target) && (ArrestedSensor.queryUsage() > 0) &&
			! ISwatAI(ArrestedSensor.Target).IsArrested())
	{
		// do nothing
		yield();
	}

	// make sure someone cares.
	if (ArrestedSensor.queryUsage() > 0)
	{
		if (class'Pawn'.static.checkConscious(ArrestedSensor.Target) && ISwatAI(ArrestedSensor.Target).IsArrested())
		{
			// if we got out of the above loop, than we are no longer threatened, let the sensor know
			ArrestedSensor.NotifyTargetArrested();
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