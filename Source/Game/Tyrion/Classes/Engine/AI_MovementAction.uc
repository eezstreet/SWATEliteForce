//=====================================================================
// AI_MovementAction
// Actions that involve a character's movement systems
//=====================================================================

class AI_MovementAction extends AI_Action
    native
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Accessor function for resources

#if IG_TRIBES3
function Rook rook()
{
	return Rook(AI_MovementResource(resource).m_pawn);
}

function Character character()
{
	return Character(AI_MovementResource(resource).m_pawn);
}

function BaseAICharacter baseAIcharacter()
{
	return BaseAICharacter(AI_MovementResource(resource).m_pawn);
}
#endif

function AI_MovementResource movementResource()
{
	return AI_MovementResource(resource);
}

function AI_CharacterResource characterResource()
{
	return AI_CharacterResource(AI_MovementResource(resource).m_pawn.characterAI);
}

//---------------------------------------------------------------------
// Return the resource class for this action

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_MovementResource';
}

//---------------------------------------------------------------------
// Depending on the type of action, find the resource the action should
// be attached to

static function Tyrion_ResourceBase findResource( Pawn p )
{
	return p.movementAI;
}

//---------------------------------------------------------------------
// Run an action
// Typically called by the resource
//
// Note: The "legs" resource is considered "used" when an action running
//       on this resource declares it needs it

function runAction()
{
	Super.runAction();

	//log( "==" @ self.name $ ":" @ resource.isActive() @ resourceUsage @ resource.usedByAction.name );

	if ( resource.isActive() && (resourceUsage & class'AI_Resource'.const.RU_LEGS) != 0 && resource.usedByAction == None )
		resource.usedByAction = self;
}

//=======================================================================

function classConstruct()
{
	resourceUsage = class'AI_Resource'.const.RU_LEGS;
}

defaultproperties
{
	//resourceUsage = 4 // should be RU_LEGS - can't access
}