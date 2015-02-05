//=====================================================================
// ISensorNotification
//
// A class that implements this interface can start sensors and
// be notified of their value changes
//=====================================================================

interface ISensorNotification;

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Callback for a sensor value update

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData );

//---------------------------------------------------------------------
// Return the AI_Resouce associated with the sensor recipient

function AI_Resource getResource();
