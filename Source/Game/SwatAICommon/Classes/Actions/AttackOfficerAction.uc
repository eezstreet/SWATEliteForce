///////////////////////////////////////////////////////////////////////////////
// AttackOfficerAction.uc - AttackOfficerAction class
// The action that causes the AI to attack a particular enemy with any weapon it
// has

class AttackOfficerAction extends SwatCharacterAction dependsOn(ISwatEnemy);
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// AttackOfficerAction variables

// behaviors we use
var protected MoveToAttackOfficerGoal   CurrentMoveToAttackOfficerGoal;
var protected AttackTargetGoal			CurrentAttackTargetGoal;

// config variables
var config private float				MinPassiveAttackOfficerPercentageChance;
var config private float				MaxPassiveAttackOfficerPercentageChance;
var config private float				MinAggressiveAttackOfficerPercentageChance;
var config private float				MaxAggressiveAttackOfficerPercentageChance;

var config private float				LowSkillSuccessAfterFiringChance;
var config private float				MediumSkillSuccessAfterFiringChance;
var config private float				HighSkillSuccessAfterFiringChance;

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
	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}
	assert(m_Pawn.IsA('SwatEnemy'));

	if (ISwatAI(m_Pawn).HasUsableWeapon() && (GetOfficerTarget() != None))
	{
		if (ISwatAI(m_Pawn).IsAggressive())
		{
			// return a random value that is above the minimum chance
			return FClamp(FRand(), MinAggressiveAttackOfficerPercentageChance, MaxAggressiveAttackOfficerPercentageChance);
		}
		else
		{
			// return a random value that is at least the minimum chance
			return FClamp(FRand(), MinPassiveAttackOfficerPercentageChance, MaxPassiveAttackOfficerPercentageChance);
		}
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToAttackOfficerGoal != None)
	{
		CurrentMoveToAttackOfficerGoal.Release();
		CurrentMoveToAttackOfficerGoal = None;
	}

	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Attack Target Success Chance

function float GetSkillSpecificSuccessAfterFiringChance()
{
	local EnemySkill CurrentEnemySkill;

	CurrentEnemySkill = ISwatEnemy(m_Pawn).GetEnemySkill();

	switch(CurrentEnemySkill)
	{
		case EnemySkill_Low:
            return LowSkillSuccessAfterFiringChance;
        case EnemySkill_Medium:
            return MediumSkillSuccessAfterFiringChance;
        case EnemySkill_High:
            return HighSkillSuccessAfterFiringChance;
        default:
            assert(false);
            return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveToAttackEnemy()
{
    CurrentMoveToAttackOfficerGoal = new class'MoveToAttackOfficerGoal'(movementResource(), achievingGoal.Priority, GetOfficerTarget());
    assert(CurrentMoveToAttackOfficerGoal != None);
	CurrentMoveToAttackOfficerGoal.AddRef();

	CurrentMoveToAttackOfficerGoal.SetRotateTowardsPointsDuringMovement(true);

	// we want to use cover while moving
	CurrentMoveToAttackOfficerGoal.SetUseCoveredPaths();

    // post the move to goal
    CurrentMoveToAttackOfficerGoal.postGoal(self);
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None))
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
	}
}

latent function AttackEnemyWithWeapon()
{
    CurrentAttackTargetGoal = new class'AttackTargetGoal'(weaponResource(), GetOfficerTarget());
    assert(CurrentAttackTargetGoal != None);
	CurrentAttackTargetGoal.AddRef();

	// set the chance that the attack target completes after firing once
	CurrentAttackTargetGoal.SetChanceToSucceedAfterFiring(GetSkillSpecificSuccessAfterFiringChance());

    // post the attack target goal
	waitForGoal(CurrentAttackTargetGoal.postGoal(self));
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None))
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
	}
	CurrentAttackTargetGoal.unPostGoal(self);

	if (! class'Pawn'.static.checkConscious(GetOfficerTarget()))
	{
		ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerDownedOfficerSpeech();
	}
}

private latent function FinishUpMoveToAttackBehavior()
{
	if (CurrentMoveToAttackOfficerGoal != None)
	{
		if (CurrentMoveToAttackOfficerGoal.achievingAction != None)
		{
			MoveToAttackOfficerAction(CurrentMoveToAttackOfficerGoal.achievingAction).FinishUp();
			WaitForGoal(CurrentMoveToAttackOfficerGoal);
		}

		CurrentMoveToAttackOfficerGoal.unPostGoal(self);
		CurrentMoveToAttackOfficerGoal.Release();
		CurrentMoveToAttackOfficerGoal = None;
	}
}


state Running
{
 Begin:
	waitForResourcesAvailable(achievingGoal.priority, achievingGoal.priority);

	MoveToAttackEnemy();
    AttackEnemyWithWeapon();

	FinishUpMoveToAttackBehavior();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageOfficerGoal'
}
