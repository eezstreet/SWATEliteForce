//=====================================================================
// Setup
// Performs one-time initializations/setup for Tyrion AI
//=====================================================================

class Setup extends Engine.Tyrion_Setup;

//=====================================================================
// Variables

var Tyrion_ResourceBase sensorResource;	// resource that sensors are attached to

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Called at start of gameplay.

function postBeginPlay()
{
	if ( sensorResource == None )
	{
		default.sensorResource = new(None) class'AI_SensorResource';
		sensorResource = default.sensorResource;
		//sensorResource.init( None );

		log( "AI_SensorResource created!" );
	}
}

//---------------------------------------------------------------------
// Called whenever time passes

function Tick( float deltaTime )
{
	sensorResource.Tick( deltaTime );
}

//=====================================================================
// defaults

defaultproperties
{
	sensorResource = None // just a hack - default variables can be used as static
}
