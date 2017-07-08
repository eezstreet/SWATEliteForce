//=====================================================================
// AI_TestSensorActionB
// Test Class for sentinels (sensors that monitor for goal activation/deactivation)
//=====================================================================

class AI_TestSensorActionB extends AI_SensorMovementAction;

//=====================================================================
// Variables.

var AI_TestSentinelA sentinel1;
var AI_TestSentinelB sentinel2;

//=====================================================================
// Functions.

//---------------------------------------------------------------------
// set up the sensors this action may update
// (can't do this in constructor because this class isn't known at
// compile time when AI_Resource postBeginPlay new's sensorActions)

function setupSensors( AI_Resource resource )
{
	// construct all sensors, add them to resource's sensor list
	sentinel1 = AI_TestSentinelA(addSensorClass( class'AI_TestSentinelA' ));
	sentinel2 = AI_TestSentinelB(addSensorClass( class'AI_TestSentinelB' ));

	// repeat if there are more sensors this sensorAction updates
}

//---------------------------------------------------------------------

state Running
{
Begin:
	sentinel1.setIntegerValue( -5 );
	sentinel2.setIntegerValue( -10 );

	while ( true )
	{
		sentinel1.setIntegerValue( sentinel1.value.integerData + 1 );
		log( "AI_TestSentinelA says value is" @ sentinel1.value.integerData );

		sentinel2.setIntegerValue( sentinel2.value.integerData + 1 );
		log("AI_TestSentinelB says value is " $ sentinel2.value.integerData);

		sleep(3.0);
	}
}

//=====================================================================

defaultproperties
{
}