///////////////////////////////////////////////////////////////////////////////
// AttackEnemyAction.uc - AttackEnemyAction class
// The action that causes the AI to attack a particular enemy with any weapon it 
// has

class AttackEnemyAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var(parameters) Pawn Enemy;

///////////////////////////////////////////////////////////////////////////////
//
// AttackEnemyAction variables

// behaviors we use
var protected MoveOfficerToEngageGoal   CurrentMoveOfficerToEngageGoal;
var protected AttackTargetGoal			CurrentAttackTargetGoal;
var private ReportGoal CurrentReportGoal;

// constants
const kMinAttackEnemyUpdateTime = 0.1;
const kMaxAttackEnemyUpdateTime = 0.25;

///////////////////////////////////////////////////////////////////////////////
// 
// Selection Heuristic

function float selectionHeuristic( AI_Goal goal )
{
	return FRand();
}

function Pawn GetEnemy()
{
    // If this behavior was created for a specific enemy target, return that enemy.
    if (Enemy != None)
        return Enemy;

	return ISwatOfficer(m_Pawn).GetOfficerCommanderAction().GetCurrentAssignment();
}

///////////////////////////////////////////////////////////////////////////////
// 
// Init / Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveOfficerToEngageGoal != None)
	{
		CurrentMoveOfficerToEngageGoal.Release();
		CurrentMoveOfficerToEngageGoal = None;
	}

	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}
	if(CurrentReportGoal != None)
	{
		CurrentReportGoal.Release();
		CurrentReportGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if ((goal == CurrentAttackTargetGoal) || (goal == CurrentMoveOfficerToEngageGoal))
	{
		// if the attacking or movement fails, we succeed so we don't get reposted, 
		// the OfficerCommanderAction will figure out what to do
		InstantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// we only move to attack the enemy if we should 
// (not in the middle of executing a move and clear!)
function bool ShouldMoveToAttackEnemy()
{
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	// test to see if we're moving and clearing
	return (! SwatAIRepo.IsOfficerMovingAndClearing(m_Pawn));
}

// returns true if we're moving and clearing, or if our move to engage goal hasn't completed
// returns false otherwise
function bool IsMovingToAttack()
{
	return (!ShouldMoveToAttackEnemy() || ((CurrentMoveOfficerToEngageGoal != None) && !CurrentMoveOfficerToEngageGoal.hasCompleted()));
}

private function MoveToAttackEnemy()
{
	// only move to attack the enemy if we should
	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " will move to attack the enemy");

	CurrentMoveOfficerToEngageGoal = new class'MoveOfficerToEngageGoal'(movementResource(), achievingGoal.Priority, GetEnemy());
	assert(CurrentMoveOfficerToEngageGoal != None);
	CurrentMoveOfficerToEngageGoal.AddRef();

	CurrentMoveOfficerToEngageGoal.SetRotateTowardsPointsDuringMovement(true);

	// post the move to goal
	CurrentMoveOfficerToEngageGoal.postGoal(self);
}

private function AttackEnemyWithWeapon()
{
    CurrentAttackTargetGoal = new class'AttackTargetGoal'(weaponResource(), GetEnemy());
    assert(CurrentAttackTargetGoal != None);
	CurrentAttackTargetGoal.AddRef();

    // post the attack target goal
	CurrentAttackTargetGoal.postGoal(self);
}

latent function ReportTarget()
{
	local ISwatAI target;

	target = ISwatAI(Enemy);
	if(target.CanBeUsedNow()) {
		CurrentReportGoal = new class 'ReportGoal'(characterResource(), target, m_Pawn.controller);
		assert(CurrentReportGoal != None);
		CurrentReportGoal.AddRef();

		CurrentReportGoal.postGoal(self);
		WaitForGoal(CurrentReportGoal);
		CurrentReportGoal.unPostGoal(self);

		CurrentReportGoal.Release();
		CurrentReportGoal = None;
	}
}

state Running
{
 Begin:
	waitForResourcesAvailable(achievingGoal.priority, achievingGoal.priority);

    AttackEnemyWithWeapon();

	// while the attacking goal hasn't completed
	while (! CurrentAttackTargetGoal.hasCompleted())
	{
		// if we aren't moving the officer to engage (if we were moving and clearing)
		// try to move to attack the enemy
		if ((CurrentMoveOfficerToEngageGoal == None) && ShouldMoveToAttackEnemy())
		{
			MoveToAttackEnemy();
		}

		sleep(RandRange(kMinAttackEnemyUpdateTime, kMaxAttackEnemyUpdateTime));
	}
	
	// enemy must be dead
	ReportTarget();
	succeed();
	
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'AttackEnemyGoal'
}