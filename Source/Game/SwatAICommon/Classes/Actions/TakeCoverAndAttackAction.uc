///////////////////////////////////////////////////////////////////////////////
// PlaceWedgeGoal.uc - PlaceWedgeGoal class
// this goal is given to a Officer to place a wedge on a particular door

class TakeCoverAndAttackAction extends TakeCoverAction
    native;
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;
import enum ELeanState from Engine.Pawn;
import enum EAICoverLocationType from AICoverFinder;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private AttackTargetGoal			CurrentAttackTargetGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private MoveToOpponentGoal			CurrentMoveToOpponentGoal;
var private AimAroundGoal				CurrentAimAroundGoal;

var config private float				LowSkillAttackWhileTakingCoverChance;
var config private float				MediumSkillAttackWhileTakingCoverChance;
var config private float				HighSkillAttackWhileTakingCoverChance;

var config private float				MinCrouchTime;
var config private float				MaxCrouchTime;
var config private float				MinStandTime;
var config private float				MaxStandTime;

var config private float				MinLeanTime;
var config private float				MaxLeanTime;

var config private float				MinPassiveTakeCoverAndAttackPercentageChance;
var config private float				MaxPassiveTakeCoverAndAttackPercentageChance;
var config private float				MinAggressiveTakeCoverAndAttackPercentageChance;
var config private float				MaxAggressiveTakeCoverAndAttackPercentageChance;

var config private float				LowSkillSuccessAfterFiringChance;
var config private float				MediumSkillSuccessAfterFiringChance;
var config private float				HighSkillSuccessAfterFiringChance;

var private Rotator						AttackRotation;
var private ELeanState					AttackLeanState;
var private EAICoverLocationType		AttackCoverLocationType;

var private array<Pawn>					CachedSeenPawns;

var private DistanceToOfficersSensor	DistanceToOfficersSensor;
var config private float				MinDistanceToOfficersWhileTakingCover;

var private float						MoveBrieflyChance;
var config private float				MoveBrieflyChanceIncrement;
var config private float				AimAroundInnerFovDegrees;
var config private float				AimAroundOuterFovDegrees;
var config private float				AimAroundMinAimTime;
var config private float				AimAroundMaxAimTime;

const kMoveTowardMinTime = 1.0;
const kMoveTowardMaxTime = 2.0;

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

private function bool CanTakeCoverAndAttack()
{
	local Hive HiveMind;

	HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();
	assert(HiveMind != None);
	assert(m_Pawn != None);

	// if we have a weapon, cover is available, the distance is greater than the minimum required
	// between us and the officers, and we can find cover to attack from
	return (ISwatAI(m_Pawn).HasUsableWeapon() && AICoverFinder.IsCoverAvailable() &&
		!HiveMind.IsPawnWithinDistanceOfOfficers(m_Pawn, MinDistanceToOfficersWhileTakingCover, true) &&
		FindBestCoverToAttackFrom() &&
		!CoverIsInBadPosition());
}

private function bool CoverIsInBadPosition()
{
	local int i;

	for(i=0; i<CachedSeenPawns.Length; ++i)
	{
		// if the cover is too close to anyone we've seen, we can't use it
		if (VSize(CoverResult.CoverLocation - CachedSeenPawns[i].Location) < MinDistanceToOfficersWhileTakingCover)
		{
//			log("Cover is too close to a pawn we've seen");
			return true;
		}

		// if the cover is behind anyone we've seen, we can't use it
		if ((Normal(m_Pawn.Location - CachedSeenPawns[i].Location) Dot Normal(CoverResult.CoverLocation - CachedSeenPawns[i].Location)) < 0.0)
		{
//			log("Cover is behind a pawn we've seen");
			return true;
		}
	}

	return false;
}

function float selectionHeuristic( AI_Goal goal )
{
	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	assert(m_Pawn.IsA('SwatEnemy'));
	AICoverFinder = ISwatAI(m_Pawn).GetCoverFinder();
	assert(AICoverFinder != None);

	if (CanTakeCoverAndAttack())
	{
		if (ISwatAI(m_Pawn).IsAggressive())
		{
			// return a random value that is above the minimum chance
			return FClamp(FRand(), MinAggressiveTakeCoverAndAttackPercentageChance, MaxAggressiveTakeCoverAndAttackPercentageChance);
		}
		else
		{
			// return a random value that is at least the minimum chance
			return FClamp(FRand(), MinPassiveTakeCoverAndAttackPercentageChance, MaxPassiveTakeCoverAndAttackPercentageChance);
		}
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentMoveToOpponentGoal != None)
	{
		CurrentMoveToOpponentGoal.Release();
		CurrentMoveToOpponentGoal = None;
	}

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}

	if (DistanceToOfficersSensor != None)
	{
		DistanceToOfficersSensor.deactivateSensor(self);
		DistanceToOfficersSensor = None;
	}

	// make sure we're not leaning
	StopLeaning();
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// if the attacking fails, we fail as well
	InstantFail(errorCode);
}

function goalAchievedCB( AI_Goal goal, AI_Action action )
{
	super.goalAchievedCB(goal, action);

	if (goal == CurrentAttackTargetGoal)
	{
		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Messages

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if (m_Pawn.logTyrion)
		log("TakeCoverAndAttackAction received sensor message from " $ sensor.name $ " value is "$ value.integerData);

	// we only (currently) get messages from a distance sensor
	assert(sensor == DistanceToOfficersSensor);

	if (value.integerData == 1)
	{
		if (m_Pawn.logTyrion)
			log(m_Pawn.Name $ " is too close while " $ Name $ " taking cover.  failing!");

		instantFail(ACT_TOO_CLOSE_TO_OFFICERS);
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
// Attacking While Taking Cover

function float GetSkillSpecificAttackChance()
{
	local EnemySkill CurrentEnemySkill;

	CurrentEnemySkill = ISwatEnemy(m_Pawn).GetEnemySkill();

	switch(CurrentEnemySkill)
	{
		case EnemySkill_Low:
            return LowSkillAttackWhileTakingCoverChance;
        case EnemySkill_Medium:
            return MediumSkillAttackWhileTakingCoverChance;
        case EnemySkill_High:
            return HighSkillAttackWhileTakingCoverChance;
        default:
            assert(false);
            return 0.0;
	}
}

function bool ShouldAttackWhileTakingCover()
{
	assert(ISwatAI(m_Pawn).HasUsableWeapon());

	return (FRand() < GetSkillSpecificAttackChance());
}

// easier than writing the accessor to commander
private function Pawn GetEnemy()
{
	return ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();
}

private function StopAttacking()
{
	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.unPostGoal(self);
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}
}

private function Attack(Pawn Enemy, bool bCanSucceedAfterFiring)
{
  if(Enemy == None) {
    return;
  }

	if (CurrentAttackTargetGoal == None)
	{
		CurrentAttackTargetGoal = new class'AttackTargetGoal'(weaponResource(), Enemy);
		assert(CurrentAttackTargetGoal != None);
		CurrentAttackTargetGoal.AddRef();

		if (bCanSucceedAfterFiring)
		{
			// set the chance that the attack target completes after firing once
			CurrentAttackTargetGoal.SetChanceToSucceedAfterFiring(GetSkillSpecificSuccessAfterFiringChance());
		}

		CurrentAttackTargetGoal.postGoal(self);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function bool IsRotatedToAttackRotation()
{
	// note, this requires that the pawn's rotation be the aim rotation
	return (m_Pawn.Rotation.Yaw == AttackRotation.Yaw);
}

latent private function RotateToAttackRotation(Pawn Enemy)
{
	assert(CurrentRotateTowardRotationGoal == None);

	if ((Enemy != None) && !IsRotatedToAttackRotation() && !m_Pawn.CanHit(Enemy))
	{
		CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, AttackRotation);
		assert(CurrentRotateTowardRotationGoal != None);
		CurrentRotateTowardRotationGoal.AddRef();

		CurrentRotateTowardRotationGoal.postGoal(self);
		WaitForGoal(CurrentRotateTowardRotationGoal);
		CurrentRotateTowardRotationGoal.unPostGoal(self);

		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}
}

private function bool CanLeanAtCoverResult()
{
	assertWithDescription((CoverResult.coverLocationInfo == kAICLI_InCover), "TakeCoverAndAttackAction::CanLeanAtCoverResult - expected coverLocationInfo to be kAICLI_InCover, got " $ CoverResult.coverLocationInfo) ;
	assert(CoverResult.coverSide != kAICLS_NotApplicable);

	if (CoverResult.coverSide == kAICLS_Left)
	{
		// we will check and see if we can lean left
		AttackLeanState = kLeanStateLeft;
	}
	else
	{
		// we will check and see if we can lean right
		AttackLeanState = kLeanStateRight;
	}

	return m_Pawn.CanLean(AttackLeanState, CoverResult.coverLocation, AttackRotation);
}

// tests the current value in the cover result value to determine if a piece of cover is usable
private function bool CanUseCover()
{
	// if the cover result says we have cover and it's low cover,
	// or it's normal cover and we can lean at that point
	if ((CoverResult.coverActor != None) &&
		((CoverResult.coverLocationInfo == kAICLI_InLowCover) ||
		 ((CoverResult.coverLocationInfo == kAICLI_InCover) && CanLeanAtCoverResult())))
	{
		return true;
	}
	else
	{
		return false;
	}
}


// returns true when we find cover and want to use it
protected function bool FindBestCoverToAttackFrom()
{
#if !IG_THIS_IS_SHIPPING_VERSION
    // Used to track down a difficult-to-repro error
    local Actor CoverActor;
#endif

    m_tookCover = false;

	assert(m_Pawn != None);
	assert(SwatCharacterResource(m_Pawn.characterAI).CommonSensorAction != None);
	assert(SwatCharacterResource(m_Pawn.characterAI).CommonSensorAction.GetVisionSensor() != None);

	CachedSeenPawns = SwatCharacterResource(m_Pawn.characterAI).CommonSensorAction.GetVisionSensor().Pawns;
	AttackCoverLocationType = kAICLT_NearestFront;
    CoverResult = AICoverFinder.FindCover(CachedSeenPawns, AttackCoverLocationType);

	if (m_Pawn.logAI)
		log("CoverResult.coverLocationInfo is: "$CoverResult.coverLocationInfo$"  CoverResult.coverActor is: " $CoverResult.coverActor);

	// there's no cover to use
	if (CoverResult.coverActor == None)
		return false;

#if !IG_THIS_IS_SHIPPING_VERSION
    // Used to track down a difficult-to-repro error
    CoverActor = CoverResult.coverActor;
#endif

    if (! CanUseCover())
	{

		AttackCoverLocationType = kAICLT_NearFrontCorner;
		CoverResult = AICoverFinder.FindCoverBehindActor(CachedSeenPawns, CoverResult.coverActor, AttackCoverLocationType);

	    // Unexpected. This happens so infrequently, we should notify in non-
        // shipping builds, but fail gracefully and not hard-assert.
	    if (CoverResult.coverActor == None)
        {
#if !IG_THIS_IS_SHIPPING_VERSION
            ReportUnexpectedFindCoverError(CoverActor);
#endif
		    return false;
        }

        if (! CanUseCover())
		{
			AttackCoverLocationType = kAICLT_FarFrontCorner;
			CoverResult = AICoverFinder.FindCoverBehindActor(CachedSeenPawns, CoverResult.coverActor, AttackCoverLocationType);
			return CanUseCover();
		}
		else
		{
			return true;
		}
	}

	// found cover!
	return true;
}

#if !IG_THIS_IS_SHIPPING_VERSION
protected native function ReportUnexpectedFindCoverError(Actor CoverActor);
#endif

protected latent function TakeCoverAtInitialCoverLocation()
{
    m_tookCover = false;

	assert(m_Pawn != None);
	assert(CoverResult.coverLocationInfo != kAICLI_NotInCover);

	TakeCover();
}

protected latent function TakeCover()
{
//  log("Taking cover at: "$CoverResult.coverLocation);

	if (ShouldAttackWhileTakingCover())
	{
		Attack(GetEnemy(), false);
	}
	else
	{
		SwapInFullBodyTakeCoverAnimations();
	}

	MoveToTakeCover(CoverResult.coverLocation);

	StopAttacking();
	ResetFullBodyAnimations();

    // if we're in low cover, we should crouch before rotation
    if (CoverResult.coverLocationInfo == kAICLI_InLowCover)
    {
        m_pawn.ShouldCrouch(true);
    }

	m_tookCover = true;
}


private latent function MoveTowardEnemyBriefly(Pawn Enemy)
{
	CurrentMoveToOpponentGoal = new class'MoveToOpponentGoal'(movementResource(), achievingGoal.priority, Enemy);
	assert(CurrentMoveToOpponentGoal != None);
	CurrentMoveToOpponentGoal.AddRef();

	CurrentMoveToOpponentGoal.SetAcceptNearbyPath(true);
	CurrentMoveToOpponentGoal.SetShouldCrouch(true);
	CurrentMoveToOpponentGoal.SetUseCoveredPaths();

	// post the goal and wait for a period time, then remove the goal.
	CurrentMoveToOpponentGoal.postGoal(self);
	sleep(RandRange(kMoveTowardMinTime, kMoveTowardMaxTime));
	CurrentMoveToOpponentGoal.unPostGoal(self);

	CurrentMoveToOpponentGoal.Release();
	CurrentMoveToOpponentGoal = None;
}

private latent function AimAroundBriefly()
{
	CurrentAimAroundGoal = new class'AimAroundGoal'(weaponResource(), CurrentAttackTargetGoal.priority - 1);
	assert(CurrentAimAroundGoal != None);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.SetAimWeapon(true);
	CurrentAimAroundGoal.SetAimInnerFovDegrees(AimAroundInnerFovDegrees);
	CurrentAimAroundGoal.SetAimOuterFovDegrees(AimAroundOuterFovDegrees);
	CurrentAimAroundGoal.SetAimAtPointTime(AimAroundMinAimTime, AimAroundMaxAimTime);
	CurrentAimAroundGoal.SetDoOnce(true);

	CurrentAimAroundGoal.postGoal(self);
	WaitForGoal(CurrentAimAroundGoal);

	CurrentAimAroundGoal.unPostGoal(self);
	CurrentAimAroundGoal.Release();
	CurrentAimAroundGoal = None;
}

private latent function AttackWhileCrouchingBehindCover(Pawn Enemy)
{
	// stand up if we can't see our enemy and we can't hit them
	if (! m_Pawn.CanHit(Enemy))
	{
		// stop crouching
		m_pawn.ShouldCrouch(false);

		// stand up for a bit
		sleep(RandRange(MinStandTime, MaxStandTime));

		// if we can't currently attack our enemy, aim around or move briefly
		if (! m_Pawn.CanHit(Enemy))
		{
			if (FRand() > MoveBrieflyChance)
			{
				AimAroundBriefly();

				MoveBrieflyChance += MoveBrieflyChanceIncrement;
			}
			else
			{
				MoveTowardEnemyBriefly(Enemy);
			}
		}

		// start crouching again
		m_pawn.ShouldCrouch(true);

		sleep(RandRange(MinCrouchTime, MaxCrouchTime));
	}
}

private function Lean()
{
	if (AttackLeanState == kLeanStateLeft)
	{
		m_Pawn.ShouldLeanRight(false);
		m_Pawn.ShouldLeanLeft(true);
	}
	else
	{
		m_Pawn.ShouldLeanLeft(false);
		m_Pawn.ShouldLeanRight(true);
	}
}

private function StopLeaning()
{
	m_Pawn.ShouldLeanLeft(false);
	m_Pawn.ShouldLeanRight(false);
}

private latent function ReEvaluateCover()
{
	if (FindBestCoverToAttackFrom())
	{
		TakeCover();
	}
	else
	{
		fail(ACT_NO_COVER_FOUND);
	}
}

private latent function AttackWhileLeaningBehindCover(Pawn Enemy)
{
	local bool bReEvaluateCover;

	// lean out if we can't hit our enemy
	if (! m_Pawn.CanHit(Enemy))
	{
		// start leaning
		Lean();

		// lean for a bit
		sleep(RandRange(MinLeanTime, MaxLeanTime));

		// if we can't hit our current enemy, we should re-evaluate our cover
		if (! m_Pawn.CanHit(Enemy))
		{
			if (m_Pawn.logAI)
				log("re evaluate cover");

			bReEvaluateCover = true;
		}

		// stop leaning
		StopLeaning();

		if (! m_Pawn.CanHit(Enemy))
		{
			AimAroundBriefly();
		}

		if (bReEvaluateCover)
		{
			ReEvaluateCover();
		}
		else
		{
			// just stand for a bit
			sleep(RandRange(MinStandTime, MaxStandTime));
		}
	}
}

protected latent function AttackFromBehindCover()
{
	local Pawn Enemy;

	// while we can still attack (enemy is not dead)
	do
	{
		Enemy = GetEnemy();

		Attack(Enemy, true);

		// rotate to the attack orientation
		AttackRotation.Yaw = CoverResult.coverYaw;
		RotateToAttackRotation(Enemy);

		if (CoverResult.coverLocationInfo == kAICLI_InLowCover)
		{
			AttackWhileCrouchingBehindCover(Enemy);
		}
		else
		{
			AttackWhileLeaningBehindCover(Enemy);
		}

		yield();
	} until (! class'Pawn'.static.checkConscious(Enemy));
}

state Running
{
 Begin:
	waitForResourcesAvailable(achievingGoal.priority, achievingGoal.priority);

	// create a sensor so we fail if we get to close to the officers
	DistanceToOfficersSensor = DistanceToOfficersSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceToOfficersSensor', characterResource(), 0, 1000000 ));
	assert(DistanceToOfficersSensor != None);
	DistanceToOfficersSensor.SetParameters(MinDistanceToOfficersWhileTakingCover, true);

	// we must have found cover in our selection heuristic for this to work
	TakeCoverAtInitialCoverLocation();

	// TODO: handle leaning around edges of cover
	// for now we're just doing crouching
	if (m_tookCover)
	{
		// TODO: handle moving to the closest edge of the cover
		// currently we just move to the closest area of cover
		AttackFromBehindCover();

		succeed();
	}
	else
	{
		fail(ACT_NO_COVER_FOUND);
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'EngageOfficerGoal'
}
