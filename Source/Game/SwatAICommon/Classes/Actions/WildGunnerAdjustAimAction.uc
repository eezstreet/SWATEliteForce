///////////////////////////////////////////////////////////////////////////////
// WildGunnerAdjustAimAction.uc
// The action that causes the WildGunner to aim around erratically while shooting
// his primary weapon

class WildGunnerAdjustAimAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// AWildGunnerAdjustAimAction variables

var float degrees;			// where the gun is pointing this tick

var config private float	WildGunnerFiringArc;
var config private float	WildGunnerSweepSpeed;

///////////////////////////////////////////////////////////////////////////////
//
// Officer Target

function Pawn GetOfficerTarget()
{
	return ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();
}

///////////////////////////////////////////////////////////////////////////////
// 
// Selection Heuristic

function float selectionHeuristic( AI_Goal goal )
{
	return 1.0;
}

///////////////////////////////////////////////////////////////////////////////
//
// Common function for "WildGunner" AI

function float AdjustWildGunnerAim(float inDegrees)
{
	local Rotator RotAdjust;	// aim direction is adjusted by this each tick
	local bool LockAimValue;

	// adjust aim
	LockAimValue = ISwatAI(m_pawn).GetLockAim();
	ISwatAI(m_pawn).UnLockAim();

	RotAdjust.Yaw = WildGunnerFiringArc * sin(inDegrees);
	inDegrees += WildGunnerSweepSpeed; 
	ISwatAI(m_pawn).AimToRotation(Rotator(GetOfficerTarget().Location - m_pawn.Location) + RotAdjust);

	ISwatAI(m_pawn).SetLockAim(LockAimValue);

	return inDegrees;
}


///////////////////////////////////////////////////////////////////////////////
//
// State Code

state Running
{
 Begin:
	degrees = 0;

	while (true)
	{
		// primary weapon equipped and currently firing
		if (ISwatWildGunner(m_pawn).IsFiring() && ISwatAI(m_pawn).FireWhereAiming())
		{
			degrees = AdjustWildGunnerAim(degrees);
		}
		Sleep(0.05f);
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'WildGunnerAdjustAimGoal'
}