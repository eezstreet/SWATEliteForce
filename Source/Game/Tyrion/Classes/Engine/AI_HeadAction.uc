//=====================================================================
// AI_HeadAction
// Actions that involve a character's head
//=====================================================================

class AI_HeadAction extends AI_Action
	abstract;

#if 0
//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Accessor function for resource

function AI_HeadResource headResource()
{
	return AI_HeadResource(resource);
}

//---------------------------------------------------------------------
// Return the ResourceType for this action

static function Tyrion_ResourceBase.ResourceTypes getResourceType()
{
	return RT_HEAD;
}

//---------------------------------------------------------------------
// Depending on the type of action, find the resource the action should
// be attached to

static function Tyrion_ResourceBase findResource( Pawn p )
{
	return AI_HeadResource(p.headAI);
}

//---------------------------------------------------------------------
// Run an action
// Typically called by the resource
// 
// Note: The "head" resource is considered "used" when an action running
//       on this resource declares it needs it

function runAction()
{
	Super.runAction();

	if ( (resourceUsage & class'AI_Resource'.const.RU_HEAD) != 0 )
		resource.usedByAction = self;
}

//=======================================================================

function classConstruct()
{
	resourceUsage = class'AI_Resource'.const.RU_HEAD;
}

//=======================================================================
defaultproperties
{
}
#endif