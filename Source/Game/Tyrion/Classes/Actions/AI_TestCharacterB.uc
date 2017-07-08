//=====================================================================
// AI_TestCharacterB
// Test Class for Actions - sensors test
//=====================================================================

class AI_TestCharacterB extends AI_CharacterAction
	editinlinenew;

//=====================================================================
// Variables

var AI_Sensor sensor1;

var int goalsAchievedN;						// counts how many goalAchievedCB's were received

//=====================================================================
// Functions

function onSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	log( self.name @ "sensorMessage called by" @ sensor.name @ "with value" @ value.integerData );
}

function goalAchievedCB( AI_Goal goal, AI_Action action )
{
	super.goalAchievedCB( goal, action );

	goalsAchievedN++;
	log( self.name @ "goalAchievedCB called for" @ goal.name @ "by" @ action.name );
}

//=====================================================================
// State code

state Running
{
Begin:
	log( self.name @ "started. Spawning a sensor." );

	sensor1 = class'AI_Sensor'.static.activateSensor( self, class'AI_TestSensorA', resource, 0, 50, );
	Sleep(5.0);
	log( self.name @ "is deactivating the sensor" );
	sensor1.deactivateSensor( self );
	sensor1 = None;

	Sleep(2.0);
	log( self.name @ "is spawning an inactive goal" );
	WaitForGoal( (new class'AI_TestInactiveAchievableGoal'( movementResource(), 99 )).postGoal( self ) );

	log( self.name @ "will terminate now." );

	if ( sensor1.queryIntegerValue() == 53 )
		succeed();
	else
		fail( ACT_ErrorCodes.ACT_GENERAL_FAILURE );
}

//=====================================================================

defaultproperties
{
	satisfiesGoal = class'AI_TestCharacterGoalB'
}