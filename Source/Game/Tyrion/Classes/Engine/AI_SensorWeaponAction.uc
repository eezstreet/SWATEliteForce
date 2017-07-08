//=====================================================================
// AI_SensorWeaponAction
// The Tyrion SensorAction class for movement resources
//=====================================================================

class AI_SensorWeaponAction extends AI_SensorAction
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Return the resource class for this action

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_WeaponResource';
}

//=====================================================================
