///////////////////////////////////////////////////////////////////////////////
// IdleAimAroundAction.uc - IdleAimAroundAction class
// Causes the AI to aim around it's current position when Idle

class IdleAimAroundAction extends AimAroundAction;

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

function float selectionHeuristic( AI_Goal goal )
{
	if (m_Pawn == None)
	{
		m_Pawn = AI_WeaponResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	if (Level == None)
	{
		Level = m_Pawn.Level;
	}

	// we only use the idle aim around behavior if the officer isn't moving and clearing
	if (! SwatAIRepository(Level.AIRepo).IsOfficerMovingAndClearing(m_Pawn))
	{
		return super.selectionHeuristic(goal);
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'IdleAimAroundGoal'
}
