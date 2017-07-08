//=====================================================================
// AI_SensorCharacterAction
// The Tyrion SensorAction class for character resources
//=====================================================================

class AI_SensorCharacterAction extends AI_SensorAction
	abstract;

//=====================================================================
// Variables

//=====================================================================
// Functions

//---------------------------------------------------------------------
// Accessor function for resources

#if IG_SWAT
function Pawn Pawn()
{
	return AI_CharacterResource(resource).m_pawn;
}
#endif

function AI_CharacterResource characterResource()
{
	return AI_CharacterResource(resource);
}

//---------------------------------------------------------------------
// Return the resource class for this action

static function class<Tyrion_ResourceBase> getResourceClass()
{
	return class'AI_CharacterResource';
}

//=====================================================================
