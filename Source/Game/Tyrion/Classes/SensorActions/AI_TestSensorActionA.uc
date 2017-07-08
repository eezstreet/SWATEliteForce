//=====================================================================
// AI_TestSensorActionA
// Test Class for sensor actions
//=====================================================================

class AI_TestSensorActionA extends AI_SensorCharacterAction;

//=====================================================================
// Variables.

var AI_Sensor sensor1;

//=====================================================================
// Functions.

//---------------------------------------------------------------------
// set up the sensors this action may update

function setupSensors( AI_Resource resource )
{
	// construct all sensors, add them to resource's sensor list
	sensor1 = addSensorClass( class'AI_TestSensorA' );

	// repeat if there are more sensors this sensorAction updates
}

//---------------------------------------------------------------------

state Running
{
Begin:
	sensor1.setIntegerValue( 55 );

	while ( true )
	{
		if ( sensor1.queryUsage() > 0 )	// check only meaningful for sensor actions with more than one sensor - but this is how it would look
			sensor1.setIntegerValue( sensor1.value.integerData - 1 );
		log( "AI_TestSensorA says value is" @ sensor1.value.integerData);
		sleep(3.0);
	}
}

//=====================================================================

defaultproperties
{
}