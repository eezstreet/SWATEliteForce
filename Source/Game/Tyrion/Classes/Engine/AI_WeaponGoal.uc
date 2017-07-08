//=====================================================================
// AI_WeaponGoal
// Goals for the Weapon Resource
//=====================================================================

class AI_WeaponGoal extends AI_Goal
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Return the resource class for this goal

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_WeaponResource';
}

//---------------------------------------------------------------------
// Depending on the type of goal, find the resource the goal should be
// attached to (if you happen to have an instance of the goal pass it in)

static function Tyrion_ResourceBase findResource( Pawn p, optional Tyrion_GoalBase goal )
{
	return p.WeaponAI;
}

//---------------------------------------------------------------------
// Get the character resource for this goal

function AI_CharacterResource characterResource()
{
	 return AI_CharacterResource(AI_WeaponResource(resource).m_pawn.characterAI);
}
