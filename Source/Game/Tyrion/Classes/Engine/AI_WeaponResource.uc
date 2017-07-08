//=====================================================================
// AI_WeaponResource
// Specialized AI_Resource for characters' weapon systems
//=====================================================================

class AI_WeaponResource extends AI_Resource;

//=====================================================================
// Variables

var Pawn m_pawn;		// reference to the rook is this resource is operating on

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
	// sensors are created here....

	super.init();
}
 
//---------------------------------------------------------------------
// perform resource-specific cleanup before resource is deleted

function cleanup()
{
	// Set sensorActions to None
	// ...

	super.cleanup();

	m_pawn = None;
}

//---------------------------------------------------------------------
// Should this resource be trying to satisfy goals?

event bool isActive()
{
	return class'Pawn'.static.checkAlive( m_pawn )
#if IG_TRIBES3
		m_pawn.Controller != None && m_pawn.AI_LOD_Level >= AILOD_NORMAL
#endif
    ;
		
}

//---------------------------------------------------------------------
// Does the resource have the sub-resources available to run an action?
// legsPriority:  priority of the sub-goal that will be posted on the legs (0 if no goal)
// armsPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
// headPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
//
// Note: arms are considered exclusive - so even an action that doesn't declare it needs
//   this resource won't run unless it has higher priority than an already running action

function bool requiredResourcesAvailable( int legsPriority, int armsPriority, optional int headPriority )
{
	return usedByAction == None ||
		usedByAction.achievingGoal.priorityFn() < armsPriority; 

	//this would be the check if weapons were non-exclusive:
	//return armsPriority == 0 ||					// arms not required
	//	usedByAction == None ||						// arms not in use
	//	usedByAction.achievingGoal.priorityFn() < armsPriority; // arms doing something less important
}

//---------------------------------------------------------------------
// Can this resource run "action" if it's already being used?
//
// Note: arms are considered exclusive - so even an action that doesn't declare it needs
//   this resource won't run unless it has higher priority than an already running action

event bool multipleActionsCheck( AI_Action action )
{
	return false; 

	//this would be the check if weapons were non-exclusive:
	//return (resourceUsage & RU_ARMS) == 0;		// arms not required
}

//----------------------------------------------------------------------
// Is the parent of this action already using a leaf resource?

event bool doesParentHaveResource( AI_Action parentAction )
{
	return parentAction != None &&
			ClassIsChildOf( parentAction.class, class'AI_WeaponAction' ) &&
			(parentAction.resourceUsage & RU_ARMS ) != 0;
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
	return class'AI_WeaponAction';
}

//=====================================================================

defaultproperties
{
}