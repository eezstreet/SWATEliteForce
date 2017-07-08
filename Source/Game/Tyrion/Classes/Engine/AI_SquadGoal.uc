//=====================================================================
// AI_SquadGoal
// Goals for the Squad Resource
//=====================================================================

class AI_SquadGoal extends AI_Goal
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Return the resource class for this goal

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_SquadResource';
}

//---------------------------------------------------------------------
// Depending on the type of goal, find the resource the goal should be
// attached to (if you happen to have an instance of the goal pass it in)

static function Tyrion_ResourceBase findResource( Pawn p, optional Tyrion_GoalBase goal )
{
	assert(false);	// can't get a squad resource from a pawn
	return None;
}
