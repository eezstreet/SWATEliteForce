//=====================================================================
// Tyrion_ActionBase
// Base class that permits AI_Action's to be set inside Pawn
//=====================================================================

class Tyrion_ActionBase extends Core.RefCount
	native
	abstract
	native
	threaded
	hidecategories(Object, InternalParameters)
	collapsecategories
	dependsOn(Tyrion_ResourceBase);
 
//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Return the resource class for this action

static function class<Tyrion_ResourceBase> getResourceClass();

//---------------------------------------------------------------------
// Depending on the type of action, find the resource the action should
// be attached to

static function Tyrion_ResourceBase findResource( Pawn p );

//---------------------------------------------------------------------
// return pertinent information about an action for debugging
// (override in individual actions)

function string actionDebuggingString()
{
	return String(name);
}

