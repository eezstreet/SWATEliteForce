//=====================================================================
// AI_CharacterGoal
// Goals for the Character Resource
//=====================================================================

class AI_CharacterGoal extends AI_Goal
#if IG_SWAT
	native
#endif
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Return the resource class for this goal

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_CharacterResource';
}

//---------------------------------------------------------------------
// Depending on the type of goal, find the resource the goal should be
// attached to (if you happen to have an instance of the goal pass it in)

static function Tyrion_ResourceBase findResource( Pawn p, optional Tyrion_GoalBase goal )
{
	return p.characterAI;
}



