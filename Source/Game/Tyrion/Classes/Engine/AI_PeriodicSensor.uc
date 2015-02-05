//=====================================================================
// AI_PeriodicSensor
// A sensor that gets updated by sensor action's state code
//
// By default, periodic sensors send a sensor message only when
// their value changes.
//=====================================================================

class AI_PeriodicSensor extends AI_Sensor
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Create a new sensor (or find a pre-existing one)
// low-level function called by activateSensor and activateSentinel

protected static function AI_Sensor activateSensorInternal( class<AI_Sensor> sensorClass,
														  AI_Resource r,
														  optional float lowerBound,
														  optional float upperBound,
														  optional Object userData,
														  optional ISensorNotification recipient)
{
	local AI_PeriodicSensor sensor;

	sensor = AI_PeriodicSensor(super.activateSensorInternal( sensorClass, r, lowerBound, upperBound, userData, recipient ));

	if ( sensor != None )
	{
		sensor.sensorAction.usageCount++;
		if ( sensor.sensorAction.usageCount == 1 )
			sensor.sensorAction.runAction();
	}

	return sensor;
}

//---------------------------------------------------------------------
// Remove a sensor
// low-level function called by deactivateSensor and deactivateSentinel

protected function deactivateSensorInternal( ISensorNotification recipient, optional float lowerBound, optional float upperBound )
{
	super.deactivateSensorInternal( recipient, lowerBound, upperBound );

	sensorAction.usageCount--;

	// stop sensorAction?
	if ( recipients.length == 0 && sensorAction.usageCount == 0 )
	{
		//log( "----> Pausing" @ sensorAction.name @ "(" @ name @ "deactivated )" );
		sensorAction.pauseAction();
	}
}

//=====================================================================

defaultproperties
{
	bNotifyOnValueChange = true
}