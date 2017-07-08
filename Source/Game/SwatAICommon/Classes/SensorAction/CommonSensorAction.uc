///////////////////////////////////////////////////////////////////////////////
//
class CommonSensorAction extends Tyrion.AI_SensorCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

var private VisionSensor		VisionSensor;
var private HearingSensor		HearingSensor;
var private ComplySensor		ComplySensor;

var private DoorOpeningSensor	DoorOpeningSensor;

///////////////////////////////////////////////////////////////////////////////
// 
// Initialization / Cleanup

function setupSensors( AI_Resource resource )
{
	super.setupSensors(resource);

	VisionSensor      = VisionSensor(addSensorClass( class'VisionSensor' ));
	HearingSensor     = HearingSensor(addSensorClass( class'HearingSensor' ));
	ComplySensor	  = ComplySensor(addSensorClass( class'ComplySensor' ));
	DoorOpeningSensor = DoorOpeningSensor(addSensorClass( class'DoorOpeningSensor' ));
}

function cleanup()
{
	super.cleanup();

	VisionSensor = None;
	HearingSensor = None;
	ComplySensor = None;
	DoorOpeningSensor = None;
}


///////////////////////////////////////////////////////////////////////////////
// 
// Accessors

function VisionSensor GetVisionSensor()
{
	return VisionSensor;
}

function HearingSensor GetHearingSensor()
{
	return HearingSensor;
}

function ComplySensor GetComplySensor()
{
	return ComplySensor;
}

///////////////////////////////////////////////////////////////////////////////
// 
// State Code

state Running
{
Begin:
	log( self.name @ "!!! SHOULD NEVER BE CALLED !!!" );
	assert( false );
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}