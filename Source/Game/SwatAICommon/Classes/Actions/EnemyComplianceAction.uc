///////////////////////////////////////////////////////////////////////////////
// EnemyComplianceAction.uc - EnemyComplianceAction class
// The action that causes the AI to be compliant

class EnemyComplianceAction extends ComplianceAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var config array<name>	CrouchedComplianceDropWeaponAnimations;
var config array<name>	StandingComplianceDropWeaponAnimations;

var config array<name>	CrouchedStunnedComplianceDropWeaponAnimations;
var config array<name>	StandingStunnedComplianceDropWeaponAnimations;

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function name GetPreComplyAnimation()
{
	if (m_Pawn.GetActiveItem() != None)
	{
		if (m_Pawn.bIsCrouched)
		{
			if (m_Pawn.IsStunned())
			{
				return CrouchedStunnedComplianceDropWeaponAnimations[Rand(CrouchedStunnedComplianceDropWeaponAnimations.Length)];
			}
			else
			{
				return CrouchedComplianceDropWeaponAnimations[Rand(CrouchedComplianceDropWeaponAnimations.Length)];
			}
		}
		else
		{
			if (m_Pawn.IsStunned())
			{
				return StandingStunnedComplianceDropWeaponAnimations[Rand(StandingStunnedComplianceDropWeaponAnimations.Length)];
			}
			else
			{
				return StandingComplianceDropWeaponAnimations[Rand(StandingComplianceDropWeaponAnimations.Length)];	
			}
		}
	}
	else
	{
		// call down the chain to do the normal arms up animation
		return Super.GetPreComplyAnimation();
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'ComplianceGoal'
}