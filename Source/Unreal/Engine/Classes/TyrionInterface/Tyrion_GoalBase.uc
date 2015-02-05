//=====================================================================
// Tyrion_GoalBase
// Base class that permits AI_Goal's to be set inside Pawn
//=====================================================================

class Tyrion_GoalBase extends Core.RefCount
	native
	abstract
	hidecategories(Object, InternalParameters)
	collapsecategories
	dependsOn(Tyrion_ResourceBase);

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Return the resource class for this goal

static function class<Tyrion_ResourceBase> getResourceClass();

//---------------------------------------------------------------------
// Depending on the type of goal, find the resource the goal should be
// attached to (if you happen to have an instance of the goal pass it in)

static function Tyrion_ResourceBase findResource( Pawn p, optional Tyrion_GoalBase goal );

//---------------------------------------------------------------------
// return pertinent information about a goal for debugging
// (override in individual goals)

function string goalDebuggingString()
{
	return String(name);
}

