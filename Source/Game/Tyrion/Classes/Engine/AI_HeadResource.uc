//=====================================================================
// AI_HeadResource
// Specialized AI_Resource for character's head
//=====================================================================

class AI_HeadResource extends AI_Resource;

#if !IG_SWAT // swat doesn't use head resources

//=====================================================================
// Variables

var Pawn m_pawn;		// reference to the pawn is this resource is operating on

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
	super.init();
}
 
//---------------------------------------------------------------------
// Should this resource be trying to satisfy goals?

event bool isActive()
{
	return class'Pawn'.static.checkAlive( m_pawn );
}

//---------------------------------------------------------------------
// Does the resource have the sub-resources available to run an action?
// legsPriority:  priority of the sub-goal that will be posted on the legs (0 if no goal)
// armsPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
// headPriority:  priority of the sub-goal that will be posted on the arms (0 if no goal)
//
// Note: the head is considered exclusive - so even an action that doesn't declare it needs
//   this resource won't run unless it has higher priority than an already running action

function bool requiredResourcesAvailable( int legsPriority, int armsPriority, optional int headPriority )
{
	return usedByAction == None ||
		usedByAction.achievingGoal.priorityFn() < headPriority; 

	//this would be the check if heads were non-exclusive:
	//return headPriority == 0 ||					// head not required
	//	usedByAction == None ||						// head not in use
	//	usedByAction.achievingGoal.priorityFn() < headPriority; // head doing something less important
}

//---------------------------------------------------------------------
// Can this resource run "action" if it's already being used?
//
// Note: head are considered exclusive - so even an action that doesn't declare it needs
//   this resource won't run unless it has higher priority than an already running action

event bool multipleActionsCheck( AI_Action action )
{
	return false; 

	//this would be the check if heads were non-exclusive:
	//return (resourceUsage & RU_HEAD) == 0;		// head not required
}

//----------------------------------------------------------------------
// Is the parent of this action already using a leaf resource?

event bool doesParentHaveResource( AI_Action parentAction )
{
	return parentAction != None &&
			ClassIsChildOf( parentAction.class, class'AI_HeadAction' ) &&
			(parentAction.resourceUsage & RU_HEAD) != 0;
}

//---------------------------------------------------------------------
// Accessor function

function Pawn pawn()
{
	return m_pawn;
}

//---------------------------------------------------------------------
// Return the ResourceType for this resource

static function ResourceTypes getResourceType()
{
	return RT_HEAD;
}

//----------------------------------------------------------------------
// Return the corresponding action class for this type of resource

function class<AI_RunnableAction> getActionClass()
{
	return class'AI_HeadAction';
}

//=====================================================================

defaultproperties
{
}

#endif // !IG_SWAT