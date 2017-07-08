///////////////////////////////////////////////////////////////////////////////
// ProceduralIdleAction.uc - ProceduralIdleAction class
// Action class that uses programmer driven functions to do when Idling

class ProceduralIdleAction extends BaseIdleAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic Query

// returns true if all of the resources (movement/weapon/head) are available
function bool AreResourcesAvailableToIdle(AI_Goal goal)
{
	assert(m_Pawn != None);
	assert(AI_Resource(m_Pawn.characterAI) != None);

	// if we don't have all of the resources, then we cannot idle
	return (AI_Resource(m_Pawn.characterAI).requiredResourcesAvailable(goal.priority, goal.priority, goal.priority));
}


///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
    super.initAction(r, goal);

	// play an idle (for the legs to keep moving)
	if (m_Pawn.bIsCrouched)
	{
		ISwatAI(m_Pawn).AnimSetIdle('cFidgetMG', 0.1);
	}
	else
	{
		ISwatAI(m_Pawn).AnimSetIdle('sFidgetMG', 0.1);
	}
}

	///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
