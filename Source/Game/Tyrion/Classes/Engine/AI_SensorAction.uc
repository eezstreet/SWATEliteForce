//=====================================================================
// AI_SensorAction
// The Tyrion SensorAction class: Special actions that collect and report
// information
//=====================================================================

class AI_SensorAction extends AI_RunnableAction
	abstract;

// SensorActions don't achieve goals, they don't have a selection heuristic
// SensorActions aren't stored with a char's "abilities", for instead are globally available
// to any action (for now)
// I see no pressing need to add sensorActions to parent's "child" list, since sensors pass
//  their messages through their own methods anyway and they don't succeed/fail, so consequently
//  never need to be interrupted
// Really the only thing they have in common with actions is that they can start children,
//  and they can be idle/running

// Note on state code usage in sensor actions:
// - sensor actions update the sensors whose "queryUsage()" is > 0
// - when no sensors need updating, THE SENSOR ACTION WILL NOT RUN AT ALL
// - consequently, a sensor action that maintains non periodic sensors must not assume any of
//   its state code will ever get executed (which is why we have the "begin()" function)

// Ideas about finding sensorActions:
// 1. Always create all sensorActions and sensors for the resource when the resource is created,
//    but make the sensor action idle until sensor data is requested
//    - how? in the resource's default params, keep a list of sensor actions
//    - each sensor action creates all its sensors in a init function, and sticks them on the
//      resource sensor list (with a link back to the action)
// 2. Keep idle list around or make sensorAction list;
//    traverse it to see if sensorAction you want already exists

//=====================================================================
// Variables

var int usageCount;		// how many actions (in total) are using sensor values updated by this action?
var bool bCallBegin;	// need to call "begin()" function?

#if IG_SWAT
var Pawn m_Pawn;
#endif

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Constructor

overloaded function construct( AI_Resource r )
{
	resource = r;

#if IG_SWAT
	m_Pawn = r.pawn();
	assert(m_Pawn != None);
#endif

	GotoState( 'Running' );
}

//---------------------------------------------------------------------
// quick accessor to the pawn

#if IG_SWAT
function Pawn Pawn()
{
	return m_pawn;
}
#endif

//---------------------------------------------------------------------
// increments refCount and returns object

function AI_SensorAction myAddRef()
{
	AddRef();
	return self;
}

//---------------------------------------------------------------------
// set up the sensors this action may update

function setupSensors( AI_Resource r );

//---------------------------------------------------------------------
// do one time initializations before state code is run
// (called from "activateSensor")

function begin();

//---------------------------------------------------------------------
// Run an action

function runAction()
{
#if IG_TRIBES3
	if ( !resource.bUnInitialized && !resource.isActive() )
	{
		log( "AI WARNING: runAction called on" @ name @ "(" @ resource.pawn().name @ ") but resource is inactive" );
	}
#elif IG_SWAT
	if ( !resource.isActive() )
	{
		removeAction();
		return;
	}
#endif

	Super.runAction();
}

//---------------------------------------------------------------------
// Called by an action when it has failed at accomplishing its goal

event instantFail( ACT_ErrorCodes errorCode, optional bool bRemoveGoal )
{
	//log( "instantFail called on" @ name @ "(" @ resource.pawn() @ ")" );
	//removeAction();
}

//---------------------------------------------------------------------
// add a sensor to a sensor action

function AI_Sensor addSensorClass( class<AI_Sensor> sensorClass )
{
	local AI_Sensor sensor;

	sensor = new(resource) sensorClass( self );
	resource.sensors[resource.sensors.length] = sensor;	// push()

	//if ( resource.pawn() != None )
	//	log( "=> addSensorClass: adding" @ sensor.name @ "to" @ name @ "on" @ resource.name @ resource.pawn().name );

	return sensor;
}

//=====================================================================

defaultproperties
{
	bSensorAction	= true
	bCallBegin		= true
}