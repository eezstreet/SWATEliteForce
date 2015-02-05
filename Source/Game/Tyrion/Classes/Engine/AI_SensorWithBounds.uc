//=====================================================================
// AISensorWithBounds
//
// Simply an AI_sensor packaged up with the value bounds the recipient
// is interested in; allows the unique identification of the recipient
// in the sensor's recipient list.
// You want to use an "AI_SensorWithBounds" when you create multiple
// sensors of the same type inside one action/goal.
//=====================================================================

class AI_SensorWithBounds extends Core.DeleteableObject
	native;

//=====================================================================
// Variables

var AI_Sensor sensor;
var float lowerBound;
var float upperBound;

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Create a new sensor (or find pre-existing one)
// Called by runnableActions
// 'action' is the action setting up the sensor
// 'resource' is what resource the sensor is collecting data on (can be None)
// 'lowerbound' and 'upperbound' specify the range of values the action is interested in
//    (if 'upperbound' is not specified or 0, it is set to 'lowerbound')

function activateSensor( ISensorNotification recipient,
							class<AI_Sensor> sensorClass,
							AI_Resource resource,
							optional float lowerBound,
							optional float upperBound,
							optional Object userData )
{
	self.lowerBound = lowerBound;
	self.upperBound = upperBound;
	sensor = class'AI_Sensor'.static.activateSensor( recipient, sensorClass, resource, lowerBound, upperBound, userData );
}

//---------------------------------------------------------------------
// Create a new sentinel (or find pre-existing one)
// Called by goal construct's
// 'goal' is the goal setting up the sensor
// 'resource' is what resource the sensor is collecting data on (can be None)
// 'lowerbound' and 'upperbound' specify the range of values the action is interested in
//    (if 'upperbound' is not specified or 0, it is set to 'lowerbound')

function activateSentinel( AI_Goal goal,
							class<AI_Sensor> sentinelClass,
							AI_Resource resource,
							optional float lowerBound,
							optional float upperBound,
							optional Object userData )
{
	self.lowerBound = lowerBound;
	self.upperBound = upperBound;
	sensor = class'AI_Sensor'.static.activateSensor( goal, sentinelClass, resource, lowerBound, upperBound, userData );
}

//---------------------------------------------------------------------
// Remove a sensor
// Called by RunnableActions when they are no longer interested in a sensor value

function deactivateSensor( ISensorNotification recipient )
{
	sensor.deactivateSensor( recipient, lowerBound, upperBound );
}

//---------------------------------------------------------------------
// Remove a sentinel
// Called by goals when they are no longer interested in a sensor value

function deactivateSentinel( AI_Goal goal )
{
	sensor.deactivateSensor( goal, lowerBound, upperBound );
}


