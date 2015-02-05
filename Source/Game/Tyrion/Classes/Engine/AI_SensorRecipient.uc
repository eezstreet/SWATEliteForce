//=====================================================================
// AI_SensorRecipient
// a SensorRecipient contains the recipient action and information about
// the sensor values an action is interested in
//=====================================================================

class AI_SensorRecipient extends Core.DeleteableObject;

//=====================================================================
// Variables

var ISensorNotification recipient;	// the objects that will be sent update messages
var bool bNotify;					// set to true when recipient first created or when notification should be sent regardless of whether value changed
var float lowerBound;				// range of sensor value the action is interested in
var float upperBound;
var Object userData;				// information to passed along when messages are sent

//=====================================================================
// Functions

//=====================================================================

defaultproperties
{
	bNotify = true
}