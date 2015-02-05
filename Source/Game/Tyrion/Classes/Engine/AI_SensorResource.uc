//=====================================================================
// AI_SensorResource
// Specialised AI_Resource for sensors not attached to character resources
//=====================================================================

class AI_SensorResource extends AI_Resource;

//=====================================================================
// Variables

#if IG_TRIBES3
	var AI_GlobalSensorAction globalSensorAction;
#endif

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Called explicitly at start of gameplay

event init()
{
#if IG_TRIBES3
	globalSensorAction = AI_GlobalSensorAction(addSensorActionClass( class'AI_GlobalSensorAction' ));
#endif
 
	super.init();
}

//---------------------------------------------------------------------
// perform resource-specific cleanup before resource is deleted

function cleanup()
{
	// Set sensorActions to None
#if IG_TRIBES3
	globalSensorAction = None;
#endif
	super.cleanup();
}

//=======================================================================

defaultproperties
{
}