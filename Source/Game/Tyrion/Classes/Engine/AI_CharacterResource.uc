//=====================================================================
// AI_CharacterResource
// Specialized AI_Resource for characters
//=====================================================================

class AI_CharacterResource extends AI_Resource;
	
//=====================================================================
// Variables

var Pawn m_pawn;								// reference to the pawn this resource is operating on
#if IG_TRIBES3
var AI_CommonSenseSensorAction commonSenseSensorAction;	// reference to the common sense sensor action
var AI_GoalSpecificSensorAction goalSpecificSensorAction;
#endif

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Store a back pointer to the actor (pawn or squad) that this resource is attached to

function setResourceOwner( Engine.Actor p )
{
	m_pawn = Pawn(p);
}

//---------------------------------------------------------------------
// Called explicitly at start of gameplay

event init()
{
#if IG_TRIBES3
	commonSenseSensorAction = AI_CommonSenseSensorAction(addSensorActionClass( class'AI_CommonSenseSensorAction' ));
	goalSpecificSensorAction = AI_GoalSpecificSensorAction(addSensorActionClass( class'AI_GoalSpecificSensorAction' ));
	addSensorActionClass( class'AI_PlayerSensorAction' );
#endif
	addSensorActionClass( class'AI_TestSensorActionA' );

	super.init();
}

//---------------------------------------------------------------------
// perform resource-specific cleanup before resource is deleted

function cleanup()
{
	// Set sensorActions to None
#if IG_TRIBES3
	commonSenseSensorAction = None;
	goalSpecificSensorAction = None;
#endif
	super.cleanup();

	m_pawn = None;
}

//---------------------------------------------------------------------
// Should this resource be trying to satisfy goals?

#if IG_SWAT
event bool isActive()
{
//	log("isActive - m_pawn: " $ m_Pawn.Name $ " m_Pawn.IsIncapacitated(): " $ m_Pawn.IsIncapacitated() $ " m_Pawn.ShouldBecomeIncapacitated(): " $ m_Pawn.ShouldBecomeIncapacitated());

	// if the pawn is alive or incapacitated, match goals
	return (class'Pawn'.static.checkAlive( m_pawn ) || 
		   ((m_pawn != None) && m_Pawn.IsIncapacitated() && m_Pawn.ShouldBecomeIncapacitated()));
}
#else
event bool isActive()
{
	return class'Pawn'.static.checkAlive( m_pawn ) &&
#if IG_TRIBES3
		m_pawn.Controller != None &&
#endif
		m_pawn.AI_LOD_Level >= AILOD_NORMAL;
}
#endif

//---------------------------------------------------------------------
// Does the resource have the sub-resources available to run an action?
// legsPriority:  priority of the sub-goal that will be posted on the legs (0 if no goal)
// armsPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
// headPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)

function bool requiredResourcesAvailable( int legsPriority, int armsPriority, optional int headPriority )
{
	return m_pawn.movementAI.requiredResourcesAvailable( legsPriority, armsPriority, headPriority ) &&
		   m_pawn.weaponAI.requiredResourcesAvailable( legsPriority, armsPriority, headPriority )
#if !IG_SWAT
           && m_pawn.headAI.requiredResourcesAvailable( legsPriority, armsPriority, headPriority )
#endif
           ;
}

//---------------------------------------------------------------------
// Accessor function

function Pawn pawn()
{
	return m_pawn;
}

//----------------------------------------------------------------------
// Return the corresponding action class for this type of resource

function class<AI_RunnableAction> getActionClass()
{
	return class'AI_CharacterAction';
}

//=====================================================================

defaultproperties
{
}