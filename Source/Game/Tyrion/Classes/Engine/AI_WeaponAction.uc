//=====================================================================
// AI_WeaponAction
// Actions that involve a character's weapon systems
//=====================================================================

class AI_WeaponAction extends AI_Action
#if IG_SWAT
	native
#endif
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Accessor function for resource

#if IG_TRIBES3
function Rook rook()
{
	return Rook(AI_WeaponResource(resource).m_pawn);
}

function Character character()
{
	return Character(AI_WeaponResource(resource).m_pawn);
}

function BaseAICharacter baseAIcharacter()
{
	return BaseAICharacter(AI_WeaponResource(resource).m_pawn);
}
#endif

function AI_WeaponResource weaponResource()
{
	return AI_WeaponResource(resource);
}

function AI_CharacterResource characterResource()
{
	return AI_CharacterResource(AI_WeaponResource(resource).m_pawn.characterAI);
}

//---------------------------------------------------------------------
// Return the resource class for this action

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_WeaponResource';
}

//---------------------------------------------------------------------
// Depending on the type of action, find the resource the action should
// be attached to

static function Tyrion_ResourceBase findResource( Pawn p )
{
	return p.weaponAI;
}

//---------------------------------------------------------------------
// Run an action
// Typically called by the resource
// 
// Note: The "arms" resource is considered "used" when an action running
//       on this resource declares it needs it

function runAction()
{
	Super.runAction();

	if ( resource.isActive() && (resourceUsage & class'AI_Resource'.const.RU_ARMS) != 0 && resource.usedByaction == None )
		resource.usedByAction = self;
}

//=======================================================================

function classConstruct()
{
	resourceUsage = class'AI_Resource'.const.RU_ARMS;
}

defaultproperties
{
	//resourceUsage = 2 // should be RU_ARMS - can't access
}