///////////////////////////////////////////////////////////////////////////////
// EnemyCowerAction.uc - EnemyCowerAction class
// Action class that causes an Enemy to cower when they don't have any usable weapons

class EnemyCowerAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// config variables
var config array<name>				CrouchedInitialEnemyCowerAnimations;

// behaviors we use
var private RotateTowardActorGoal	CurrentRotateTowardActorGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}
}

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

	if (! ISwatAI(m_Pawn).HasUsableWeapon())
	{
		// if we have already fled without a usable weapon, we need to be chosen
		// otherwise, randomly let us choose between fleeing and regrouping
		if (ISwatEnemy(m_Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon())
		{
			return 1.0;
		}
		else
		{
			return FRand();
		}
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

function name GetInitialCowerAnimation()
{
	return CrouchedInitialEnemyCowerAnimations[Rand(CrouchedInitialEnemyCowerAnimations.Length)];
}

latent function DropTheWeapon()
{
	ISwatEnemy(m_Pawn).ThrowWeaponDown();
}

latent function PlayCowerAnimation()
{
	local int IdleChannel;
	local name InitialCowerAnimation;
	
	// Play the animation and wait for it to finish
	if (InitialCowerAnimation != '')
	{
		IdleChannel = m_Pawn.AnimPlaySpecial(GetInitialCowerAnimation(), 0.2);    
		m_Pawn.FinishAnim(IdleChannel);
	}
    

	ISwatAI(m_Pawn).SetIdleCategory('Cower');
	// Below stops officers from killing cowering enemies
	if (m_Pawn.IsA('SwatEnemy') && ISwatEnemy(m_Pawn).IsAThreat())
	{
		ISwatEnemy(m_Pawn).UnbecomeAThreat();
	}
}

private function bool ShouldFaceTargetOfficer()
{
	return (class'Pawn'.static.checkConscious(GetOfficerTarget()) && m_Pawn.LineOfSightTo(GetOfficerTarget()));
}

private latent function FaceTargetOfficer()
{
	CurrentRotateTowardActorGoal = new class'RotateTowardActorGoal'(movementResource(), achievingGoal.priority, GetOfficerTarget());
	assert(CurrentRotateTowardActorGoal != None);
	CurrentRotateTowardActorGoal.AddRef();

	CurrentRotateTowardActorGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardActorGoal);
	CurrentRotateTowardActorGoal.unPostGoal(self);

	CurrentRotateTowardActorGoal.Release();
	CurrentRotateTowardActorGoal = None;
}

state Running
{
 Begin:
	waitForResourcesAvailable(achievingGoal.priority, achievingGoal.priority);

	useResources(class'AI_Resource'.const.RU_ARMS);
	
	DropTheWeapon();

	if (ShouldFaceTargetOfficer())
	{
		FaceTargetOfficer();
	}

	useResources(class'AI_Resource'.const.RU_LEGS);

	m_Pawn.ShouldCrouch(true);
	yield();						// wait one tick to allow us to crouch.

	PlayCowerAnimation();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageOfficerGoal'
}
