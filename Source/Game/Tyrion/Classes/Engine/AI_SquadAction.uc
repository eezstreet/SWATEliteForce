//=====================================================================
// AI_SquadAction
// Actions that involve teams of characters
//=====================================================================

class AI_SquadAction extends AI_Action
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Accessor function for resources

function SquadInfo squad()
{
	return AI_SquadResource(resource).squad;
}

function AI_SquadResource squadResource()
{
	return AI_SquadResource(resource);
}

//---------------------------------------------------------------------
// Return the resource class for this action

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_SquadResource';
}

//---------------------------------------------------------------------
// Depending on the type of action, find the resource the action should
// be attached to

static function Tyrion_ResourceBase findResource( Pawn p )
{
	assert(false);	// can't get a squad resource from a pawn
	return None;
}

//=======================================================================

function classConstruct()
{
	// squad actions use all of a character's sub-resources by default
	resourceUsage = class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS | class'AI_Resource'.const.RU_HEAD;
}

defaultproperties
{
	//resourceUsage = 7 // should be RU_HEAD | RU_ARMS | RU_LEGS - can't access or use or's here;
}