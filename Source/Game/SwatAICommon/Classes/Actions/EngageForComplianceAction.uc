///////////////////////////////////////////////////////////////////////////////
// EngageForComplianceAction.uc - EngageTargetAction class
// The Action that causes an Officer AI to engage a target for compliance

class EngageForComplianceAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Pawn					TargetPawn;

// our behaviors
//var private SWATTakeCoverAndAimGoal		CurrentSWATTakeCoverAndAimGoal;
var private OrderComplianceGoal			CurrentOrderComplianceGoal;
var protected MoveOfficerToEngageGoal   CurrentMoveOfficerToEngageGoal;
var private bool        				bTriedAlternatives;

// config variables
var config float						MinComplianceOrderSleepTime;
var config float						MaxComplianceOrderSleepTime;

const kMinComplianceUpdateTime = 0.1;
const kMaxComplianceUpdateTime = 0.25;

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

function float selectionHeuristic( AI_Goal Goal )
{
	// If we are falling in or moving, use the specialized actions instead
	if(IsMovingTo() || IsFallingIn())
	{
		return 0.0;
	}
	return 1.0;
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentOrderComplianceGoal != None)
	{
		CurrentOrderComplianceGoal.Release();
		CurrentOrderComplianceGoal = None;
	}
	
	if (CurrentMoveOfficerToEngageGoal != None)
	{
		CurrentMoveOfficerToEngageGoal.Release();
		CurrentMoveOfficerToEngageGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	log(name$"...goalNotAchievedCB");

	if (goal == CurrentOrderComplianceGoal || goal == CurrentMoveOfficerToEngageGoal)
	{
		// if ordering compliance or movement fails, we succeed so we don't get reposted, 
		// the OfficerCommanderAction will figure out what to do.
		// The one exception to this logic is if the Order Compliance goal fails,
		// in which case, we will want to pursue other means
		if (goal != CurrentOrderComplianceGoal || errorCode != ACT_TIME_LIMIT_EXCEEDED)
		{
			InstantSucceed();
		}
	}
}

private function bool ShouldTaserAsFollowUp()
{
	local FiredWeapon MainWeapon, BackupWeapon;

	MainWeapon = ISwatOfficer(m_Pawn).GetPrimaryWeapon();
	BackupWeapon = ISwatOfficer(m_Pawn).GetBackupWeapon();

	return (MainWeapon.IsA('Taser') && MainWeapon.ShouldOfficerUseAgainst(TargetPawn, 0)) ||
		(BackupWeapon.IsA('Taser') && BackupWeapon.ShouldOfficerUseAgainst(TargetPawn, 0));
}

private function bool ShouldPepperSprayAsFollowUp()
{
	local HandheldEquipment Equipment;

	if (TargetPawn.IsA('SwatEnemy'))
	{
		// too dicey honestly
		return false;
	}

	Equipment = ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_PepperSpray);
	return Equipment != None && Equipment.IsA('PepperSpray') && VSize(m_Pawn.Location - TargetPawn.Location) < 512.0f;
}

private function bool ShouldPepperBallAsFollowUp()
{
	local FiredWeapon MainWeapon, BackupWeapon;

	MainWeapon = ISwatOfficer(m_Pawn).GetPrimaryWeapon();
	BackupWeapon = ISwatOfficer(m_Pawn).GetBackupWeapon();

	return (MainWeapon.IsA('CSBallLauncher') && MainWeapon.ShouldOfficerUseAgainst(TargetPawn, 0)) ||
		(BackupWeapon.IsA('CSBallLauncher') && BackupWeapon.ShouldOfficerUseAgainst(TargetPawn, 0));
}

private function bool ShouldBeanbagAsFollowUp()
{
	local FiredWeapon MainWeapon, BackupWeapon;

	if (TargetPawn.IsA('SwatHostage'))
	{
		// too dicey honestly
		return false;
	}

	MainWeapon = ISwatOfficer(m_Pawn).GetPrimaryWeapon();
	BackupWeapon = ISwatOfficer(m_Pawn).GetBackupWeapon();

	return (MainWeapon.IsA('BeanbagShotgunBase') && MainWeapon.ShouldOfficerUseAgainst(TargetPawn, 0)) ||
		(BackupWeapon.IsA('BeanbagShotgunBase') && BackupWeapon.ShouldOfficerUseAgainst(TargetPawn, 0));
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// we only move to engage the target for compliance if we should 
// (not in the middle of executing a move and clear!)
private function bool ShouldMoveTowardsComplianceTarget()
{
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	// test to see if we're moving and clearing

	return (! SwatAIRepo.IsOfficerMovingAndClearing(m_Pawn));
}

private function MoveTowardsComplianceTarget()
{
	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " will move to engage the target for compliance");

	assert(CurrentMoveOfficerToEngageGoal == None);

	CurrentMoveOfficerToEngageGoal = new class'MoveOfficerToEngageGoal'(movementResource(), achievingGoal.Priority, TargetPawn);
	assert(CurrentMoveOfficerToEngageGoal != None);
	CurrentMoveOfficerToEngageGoal.AddRef();

	CurrentMoveOfficerToEngageGoal.SetRotateTowardsPointsDuringMovement(true);

	// post the move to goal and wait for it to complete
	CurrentMoveOfficerToEngageGoal.postGoal(self);
}

private function OrderTargetToComply()
{
	assert(CurrentOrderComplianceGoal == None);

	CurrentOrderComplianceGoal = new class'OrderComplianceGoal'(weaponResource(), TargetPawn);
	assert(CurrentOrderComplianceGoal != None);
	CurrentOrderComplianceGoal.AddRef();

	CurrentOrderComplianceGoal.postGoal(self);
}

state Running
{
 Begin:
	log(Name$"....started running");
	OrderTargetToComply();
	
	while (! CurrentOrderComplianceGoal.hasCompleted())
	{
		if ((CurrentMoveOfficerToEngageGoal == None) && ShouldMoveTowardsComplianceTarget())
		{
			MoveTowardsComplianceTarget();
		}

		sleep(RandRange(kMinComplianceUpdateTime, kMaxComplianceUpdateTime));
	}

	succeed();
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'EngageForComplianceGoal'
}
