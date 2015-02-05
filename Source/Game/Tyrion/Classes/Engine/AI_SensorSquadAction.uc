//=====================================================================
// AI_SensorSquadAction
// The Tyrion SensorAction class for squad resources
//=====================================================================

class AI_SensorSquadAction extends AI_SensorAction
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Return the resource class for this action

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_SquadResource';
}

//=====================================================================
