//=====================================================================
// AI_Sensor
// The Tyrion Sensor class
//
// A sensor that gets updated by calls to setxxxValue
//=====================================================================

class AI_Sensor extends Core.DeleteableObject implements ISensorNotification
	native
	abstract;

//=====================================================================
// Constants

const ONLY_NONE_VALUE = 1;					// for object sensors: send message only when object value is None
const ONLY_NON_NONE_VALUE = 2;				// for object sensors: send message only when object value is non-None

//=====================================================================
// Variables

var AI_SensorAction sensorAction;			// the action that is updating this sensor
var array<AI_SensorRecipient> recipients;	// actions/sensors who are waiting for messages from this sensor 
var AI_SensorData value;					// the value of the sensor
var bool bNotifyOnValueChange;				// notify recipients only when the sensor value changes
var bool bNotifyIfResourceInactive;			// notify even if resource is inactive

//=====================================================================
// Functions

//---------------------------------------------------------------------
// ISensorNotification implementation

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData );

function AI_Resource getResource()
{
	return sensorAction.resource;
}

//---------------------------------------------------------------------
// Constructor

overloaded function construct( AI_SensorAction action )
{
	sensorAction = action;
	value = new class'AI_SensorData';
}

//---------------------------------------------------------------------
// Create a new sensor (or find pre-existing one)
// Called by runnableActions
// 'action' is the action setting up the sensor
// 'resource' is what resource the sensor is collecting data on (can be None)
// 'lowerbound' and 'upperbound' specify the range of values the action is interested in
//    (if 'upperbound' is not specified or 0, it is set to 'lowerbound')

static function AI_Sensor activateSensor( ISensorNotification recipient,
								   class<AI_Sensor> sensorClass,
								   AI_Resource resource,
								   optional float lowerBound,
								   optional float upperBound,
								   optional Object userData )
{
//	log("activateSensor called for " $ recipient $ " sensorClass: " $ sensorClass $ " resource: " $resource);
	return sensorClass.static.activateSensorInternal( sensorClass, resource, lowerBound, upperBound, userData, recipient );
}

//---------------------------------------------------------------------
// Create a new sentinel (or find pre-existing one)
// Called by goal construct's
// 'goal' is the goal setting up the sensor
// 'resource' is what resource the sensor is collecting data on (can be None)
// 'lowerbound' and 'upperbound' specify the range of values the action is interested in
//    (if 'upperbound' is not specified or 0, it is set to 'lowerbound')

static function AI_Sensor activateSentinel( AI_Goal goal,
									   class<AI_Sensor> sentinelClass,
									   AI_Resource resource,
									   optional float lowerBound,
									   optional float upperBound,
									   optional Object userData )
{
	return sentinelClass.static.activateSensorInternal( sentinelClass, resource, lowerBound, upperBound, userData, goal );
}

//---------------------------------------------------------------------
// Remove a sensor
// Called by RunnableActions when they are no longer interested in a sensor value

function deactivateSensor( ISensorNotification recipient, optional float lowerBound, optional float upperBound )
{
//	log(Name $ " deactivateSensor called for recipient " $ recipient);
	deactivateSensorInternal( recipient, lowerBound, upperBound );
}

//---------------------------------------------------------------------
// Remove a sentinel
// Called by goals when they are no longer interested in a sensor value

function deactivateSentinel( AI_Goal goal, optional float lowerBound, optional float upperBound )
{
	deactivateSensorInternal( goal, lowerBound, upperBound );
}

//---------------------------------------------------------------------
// perform sensor-specific startup initializations when sensor is first activated
// (called from "activateSensor")

function begin();

//---------------------------------------------------------------------
// perform sensor-specific cleanup when sensor has no more recipients

function cleanup();

//---------------------------------------------------------------------
// Notify the action / goal that set up the sensor of sensor's value

protected function sendSensorMessage( AI_SensorRecipient recipient, AI_SensorData value )
{
	//log( "1. Sending sensor message to" @ recipient.recipient.name @ "(" @ recipient.recipient.getResource().name @ ")" );
	if ( bNotifyIfResourceInactive || recipient.recipient.getResource().isActive() )
	{
		//log( "2. Sending sensor message to" @ recipient.recipient.name @ "(" @ recipient.recipient.getResource().name @ ")" );
		recipient.recipient.onSensorMessage( self, value, recipient.userData );
	}
}

//---------------------------------------------------------------------
// next time this recipient's value get updated, send a message
// regardless of whether the sensor value changed

function sendMessageOnNextValueUpdate( ISensorNotification recipient )
{
	local int i;
	local AI_SensorRecipient sensorRecipient;

	for ( i = 0; i < recipients.length; i++ )
	{
		sensorRecipient = recipients[i];

		if ( sensorRecipient.recipient == recipient )
			 sensorRecipient.bNotify = true;
	}
}

//---------------------------------------------------------------------
// Set a sensor's value
// Called by sensors - sets the sensors value and notifies waiting
// actions appropriately

function setIntegerValue( int newValue )
{
	local int i;
	local AI_SensorRecipient sensorRecipient;
	local int oldValue;
	local array<AI_SensorRecipient> sendList;	// place to collect recipient who will receive a message (can't send message directly because recipients may modify the array) 

	oldValue = value.integerData;
	value.dataType = SDT_INTEGER;
	value.integerData = newValue;

	// check if newValue in range and no notification was sent before
	for ( i = 0; i < recipients.length; i++ )
	{
		sensorRecipient = recipients[i];

		//log( name @ "setIntegerValue: Checking" @ sensorRecipient.recipient.name );
		//log( "newvalue:" @ newValue @ " oldvalue:" @ oldValue @
		//	"(" @ sensorRecipient.lowerbound $ ", " $ sensorRecipient.upperbound @ ")" );

		if ( newValue >= sensorRecipient.lowerBound &&
			 newValue <= sensorRecipient.upperBound && 
			 ( sensorRecipient.bNotify || !bNotifyOnValueChange ||
			   oldValue < sensorRecipient.lowerBound ||
			   oldValue > sensorRecipient.upperBound ))
		{
			sensorRecipient.bNotify = false;
			sendList[sendList.length] = sensorRecipient;
		}
	}

	for ( i = 0; i < sendList.length; i++ )
		sendSensorMessage( sendList[i], value );
}

//---------------------------------------------------------------------

function setFloatValue( float newValue )
{
	local int i;
	local AI_SensorRecipient sensorRecipient;
	local float oldValue;
	local array<AI_SensorRecipient> sendList;	// place to collect recipient who will receive a message (can't send message directly because recipients may modify the array) 

	oldValue = value.floatData;
	value.dataType = SDT_FLOAT;
	value.floatData = newValue;

	// check if newValue in range and no notification was sent before
	for ( i = 0; i < recipients.length; i++ )
	{
		sensorRecipient = recipients[i];

		if ( newValue >= sensorRecipient.lowerBound &&
			 newValue <= sensorRecipient.upperBound && 
			 ( sensorRecipient.bNotify || !bNotifyOnValueChange ||
			   oldValue < sensorRecipient.lowerBound ||
			   oldValue > sensorRecipient.upperBound ))
		{
			//log( name @ "recipient (" @ sensorRecipient.lowerBound @ sensorRecipient.upperBound @ ") :" @ sensorRecipient @ " value" @ newValue );

			sensorRecipient.bNotify = false;
			sendList[sendList.length] = sensorRecipient;
		}
	}

	for ( i = 0; i < sendList.length; i++ )
		sendSensorMessage( sendList[i], value );
}

//---------------------------------------------------------------------

function setCategoricalValue( int newValue )
{
	log( "setCategoricalValue: Not yet implemented" );
}

//---------------------------------------------------------------------
// Note: if the upperbound is non-zero, a message is only sent when
//       the object value is non-None

function setObjectValue( Object newValue )
{
	local int i;
	local AI_SensorRecipient sensorRecipient;
	local Object oldValue;
	local array<AI_SensorRecipient> sendList;	// place to collect recipient who will receive a message (can't send message directly because recipients may modify the array) 

	oldValue = value.objectData;
	value.dataType = SDT_OBJECT;
	value.objectData = newValue;

	// check if newValue in range and no notification was sent before
	for ( i = 0; i < recipients.length; i++ )
	{
		sensorRecipient = recipients[i];
		//log( "--" @ name @ ":" @ sensorRecipient.recipient.name @ "; oldvalue:" @ oldValue @ "; newValue:" @ newValue @ "; upperBound:" @ sensorRecipient.upperBound );

		if ( ( sensorRecipient.upperBound != ONLY_NON_NONE_VALUE || newValue != None ) &&
			 ( sensorRecipient.upperBound != ONLY_NONE_VALUE || newValue == None ) &&
			(!bNotifyOnValueChange || newValue != oldValue || sensorRecipient.bNotify) &&
			bSendMessage( newValue ))
		{
			//log( name @ "recipient:" @ sensorRecipient.recipient.name @ "; value" @ newValue );

			sensorRecipient.bNotify = false;
			sendList[sendList.length] = sensorRecipient;
		}
	}

	for ( i = 0; i < sendList.length; i++ )
		sendSensorMessage( sendList[i], value );
}

//---------------------------------------------------------------------
// If the sensor value is set to this object, should the sensor send a notification?
// Overriden by individual sensors.

function bool bSendMessage( Object object )
{
	return true;
}

//---------------------------------------------------------------------
// Query a sensor's value

function AI_SensorData queryValue()
{
	return value;
}

function int queryIntegerValue()
{
	return value.integerData;
}

function float queryFloatValue()
{
	return value.floatData;
}

function Object queryObjectValue()
{
	return value.objectData;
}

//---------------------------------------------------------------------
// Clear a sensor's value

function clearValue()
{
	value.clear();
}

//---------------------------------------------------------------------
// How many actions are using this sensor?

function int queryUsage()
{
	return recipients.length;
}

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
	local int i;
	local AI_Sensor sensor;
	local AI_SensorRecipient sensorRecipient;

	//log( "-> Sensor" @ sensorClass.name @ "requested by" @ recipient.name @ "on" @ r.name );

	if ( r == None )
		r = AI_SensorResource( class'Setup'.default.sensorResource );
 
	if ( r == None )
		log( "AI Error: Couldn't retrieve sensorResource in 'createSensorInternal'" );

	// log( "## Looking for sensors...." );

	// Check if this sensor already exists (possible optimization: use a hashTable for quicker lookup?)
	for ( i = 0; i < r.sensors.length; i++ )
	{
		// log( "---> Looking at" @ r.sensors[i] );
		if ( sensorClass == r.sensors[i].class )
		{
			sensor = r.sensors[i];
			break;
		}
	}

	if ( sensor == None )
	{
		log( "AI WARNING: Sensor" @ sensorClass.name @ "requested by" @ recipient.name @ "but not found!" );
		log( "AI WARNING: Check that the corresponding sensorAction has been set up for" @ r.name );
	}
	else
	{
		//for ( i = 0; i < sensor.recipients.length; i++ )
		//	if ( sensor.recipients[i].recipient == recipient ) 
		//	{
		//		log( "AI WARNING: Activating already existing sensor" @ sensor.name @ "in" @ r );
		//		return sensor;
		//	}

		// Set up new SensorRecipient
		sensorRecipient = new(r) class'AI_SensorRecipient';
		sensorRecipient.userData = userData;
		sensorRecipient.recipient = recipient;

		sensorRecipient.lowerBound = lowerBound;
		if ( upperBound == 0.0 )
			sensorRecipient.upperBound = lowerBound;
		else
			sensorRecipient.upperBound = upperBound;

		// add it to the list of recipients
		// recipients.Push(sensorRecipient)
		sensor.recipients[sensor.recipients.length] = sensorRecipient;

		if ( sensor.sensorAction.bCallBegin )
		{
			sensor.sensorAction.bCallBegin = false;
			sensor.sensorAction.begin();
		}

		if ( sensor.recipients.length == 1 )
			sensor.begin();

		//if ( sensor.class == class'AI_TargetSensor' )
		//	log( "=>" @ sensor.name @ sensor.recipients.length );
	}

	return sensor;
}

//---------------------------------------------------------------------
// Remove a sensor
// low-level function called by deactivateSensor and deactivateSentinel

protected function deactivateSensorInternal( ISensorNotification recipient, optional float lowerBound, optional float upperBound )
{
	local int i;
	local AI_SensorRecipient sensorRecipient;

	// log("----> Deactivating" @ name ); 

	for ( i = 0; i < recipients.length; i++ )
	{
		sensorRecipient = recipients[i];

		if ( sensorRecipient.recipient == recipient &&
			(upperBound == 0 || sensorRecipient.upperBound == upperBound) &&
			(lowerBound == 0 || sensorRecipient.lowerBound == lowerBound) ) 
		{
			//log("----> Removing recipient" @ recipient.name @ "(length:" @ recipients.length-1 $ ")" @ "from" @ name );
			recipients[i].Delete();
			recipients.remove(i, 1);		// removes element - shifts the rest
			break;
		}
	}

	//if ( class == class'AI_TargetSensor' )
	//	log( "<=" @ name @ recipients.length );

	if ( recipients.length == 0 )
		cleanup();
}

//=====================================================================

defaultproperties
{
	bNotifyOnValueChange = false
}