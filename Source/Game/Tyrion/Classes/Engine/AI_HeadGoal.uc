//=====================================================================
// AI_HeadGoal
// Goals for the Head Resource
//=====================================================================

class AI_HeadGoal extends AI_Goal
	abstract;

#if 0
//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Return the ResourceType for this goal

static function Tyrion_ResourceBase.ResourceTypes getResourceType()
{
	return RT_HEAD;
}

//---------------------------------------------------------------------
// Depending on the type of goal, find the resource the goal should be
// attached to (if you happen to have an instance of the goal pass it in)

static function Tyrion_ResourceBase findResource( Pawn p, optional Tyrion_GoalBase goal )
{
	return AI_HeadResource(p.HeadAI);
}

//---------------------------------------------------------------------
// Get the character resource for this goal

function AI_CharacterResource characterResource()
{
	 return AI_CharacterResource(AI_HeadResource(resource).m_pawn.characterAI);
}
#endif // IG_SWAT