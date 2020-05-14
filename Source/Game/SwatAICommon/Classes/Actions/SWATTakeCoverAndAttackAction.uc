///////////////////////////////////////////////////////////////////////////////
// PlaceWedgeGoal.uc - PlaceWedgeGoal class
// this goal is given to a Officer to place a wedge on a particular door

class SWATTakeCoverAndAttackAction extends SWATTakeCoverAction;
///////////////////////////////////////////////////////////////////////////////

import enum ELeanState from Engine.Pawn;
import enum EAICoverLocationType from AICoverFinder;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var(parameters) protected Pawn Enemy;
var protected AttackTargetGoal			CurrentAttackTargetGoal;
var protected RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var protected MoveToOpponentGoal			CurrentMoveToOpponentGoal;
var protected AimAroundGoal				CurrentAimAroundGoal;

var config protected float				SWATAttackWhileTakingCoverChance;

var config protected float				MinCrouchTime;
var config protected float				MaxCrouchTime;
var config protected float				MinStandTime;
var config protected float				MaxStandTime;

var config protected float				MinLeanTime;
var config protected float				MaxLeanTime;

var config protected float				SWATMinTakeCoverAndAttackPercentageChance;
var config protected float				SWATMaxTakeCoverAndAttackPercentageChance;

var protected Rotator						AttackRotation;
var protected ELeanState					AttackLeanState;
var protected EAICoverLocationType		AttackCoverLocationType;

var protected array<Pawn>					CachedSeenPawns;

var protected DistanceSensor				DistanceSensor;
var config protected float				MinDistanceToSuspectsWhileTakingCover;

var protected float						MoveBrieflyChance;
var config protected float				MoveBrieflyChanceIncrement;
var config protected float				AimAroundInnerFovDegrees;
var config protected float				AimAroundOuterFovDegrees;
var config protected float				AimAroundMinAimTime;
var config protected float				AimAroundMaxAimTime;

const kMoveTowardMinTime = 1.0;
const kMoveTowardMaxTime = 2.0;

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

protected function bool ShouldMoveToCover() {
	local SwatAIRepository SwatAIRepo;
	SwatAIRepo = SwatAIRepository(Level.AIRepo);

	// test to see if we're moving and clearing
	return (!SwatAIRepo.IsOfficerMovingAndClearing(m_Pawn));
}

protected function bool CanTakeCoverAndAttack()
{
	local Hive HiveMind;

	HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();
	assert(HiveMind != None);
	assert(m_Pawn != None);

	// if we have a weapon, cover is available, the distance is greater than the minimum required
	// between us and the suspects, we can find cover to attack from and we are not currently moving and clearing
	return (ISwatAI(m_Pawn).HasUsableWeapon() && AICoverFinder.IsCoverAvailable() &&
		ShouldMoveToCover() &&
		FindBestCoverToAttackFrom() &&
		!CoverIsInBadPosition());
}

protected function bool CoverIsInBadPosition()
{
	local int i;

	for(i=0; i<CachedSeenPawns.Length; ++i)
	{
		// if the cover is too close to anyone we've seen, we can't use it
		if (VSize(CoverResult.CoverLocation - CachedSeenPawns[i].Location) < MinDistanceToSuspectsWhileTakingCover)
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
	if(IsFallingIn())
	{	// Is handled by AttackEnemyWhileFallingInAction
		return 0.0;
	}

	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	assert(m_Pawn.IsA('SwatOfficer'));
	AICoverFinder = ISwatAI(m_Pawn).GetCoverFinder();
	assert(AICoverFinder != None);

	if (CanTakeCoverAndAttack())
	{
		// return a random value that is above the minimum chance
		return FClamp(FRand(), SWATMinTakeCoverAndAttackPercentageChance, SWATMaxTakeCoverAndAttackPercentageChance);
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

	if (DistanceSensor != None)
	{
		DistanceSensor.deactivateSensor(self);
		DistanceSensor = None;
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
	assert(sensor == DistanceSensor);

	if (value.integerData == 1)
	{
		if (m_Pawn.logTyrion)
			log(m_Pawn.Name $ " is too close while " $ Name $ " taking cover.  failing!");

		instantFail(ACT_TOO_CLOSE_TO_OFFICERS);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Attacking While Taking Cover

function float GetSWATAttackChance()
{

	if (m_Pawn.IsA('SwatOfficer'))
	{
		return SWATAttackWhileTakingCoverChance;
	}            
    default:
        assert(true);
        return 0.9;

}

function bool ShouldAttackWhileTakingCover()
{
	assert(ISwatAI(m_Pawn).HasUsableWeapon());

	return (FRand() < GetSWATAttackChance());
}

// easier than writing the accessor to commander
protected function Pawn GetEnemy()
{
	return ISwatOfficer(m_Pawn).GetOfficerCommanderAction().GetCurrentAssignment();
}

protected function StopAttacking()
{
	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.unPostGoal(self);
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}
}

protected function Attack(Pawn Target, bool bCanSucceedAfterFiring)
{
  if(Target == None) {
    return;
  }

	if (CurrentAttackTargetGoal == None)
	{
		CurrentAttackTargetGoal = new class'AttackTargetGoal'(weaponResource(), Target);
		assert(CurrentAttackTargetGoal != None);
		CurrentAttackTargetGoal.AddRef();
		
		CurrentAttackTargetGoal.postGoal(self);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

protected function bool IsRotatedToAttackRotation()
{
	// note, this requires that the pawn's rotation be the aim rotation
	return (m_Pawn.Rotation.Yaw == AttackRotation.Yaw);
}

latent protected function RotateToAttackRotation(Pawn Target)
{
	assert(CurrentRotateTowardRotationGoal == None);

	if ((Target != None) && !IsRotatedToAttackRotation() && !m_Pawn.CanHit(Target))
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

protected function bool CanLeanAtCoverResult()
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
protected function bool CanUseCover()
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


protected latent function MoveTowardEnemyBriefly(Pawn Target)
{
	CurrentMoveToOpponentGoal = new class'MoveToOpponentGoal'(movementResource(), achievingGoal.priority, Target);
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

protected latent function AimAroundBriefly()
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

protected latent function AttackWhileCrouchingBehindCover(Pawn Target)
{
	// stand up if we can't see our Target and we can't hit them
	if (! m_Pawn.CanHit(Target))
	{
		// stop crouching
		m_pawn.ShouldCrouch(false);

		// stand up for a bit
		sleep(RandRange(MinStandTime, MaxStandTime));

		// if we can't currently attack our Target, aim around or move briefly
		if (! m_Pawn.CanHit(Target))
		{
			if (FRand() > MoveBrieflyChance)
			{
				AimAroundBriefly();

				MoveBrieflyChance += MoveBrieflyChanceIncrement;
			}
			else
			{
				MoveTowardEnemyBriefly(Target);
			}
		}

		// start crouching again
		m_pawn.ShouldCrouch(true);

		sleep(RandRange(MinCrouchTime, MaxCrouchTime));
	}
}

protected function Lean()
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

protected function StopLeaning()
{
	m_Pawn.ShouldLeanLeft(false);
	m_Pawn.ShouldLeanRight(false);
}

protected latent function ReEvaluateCover()
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

protected latent function AttackWhileLeaningBehindCover(Pawn Target)
{
	local bool bReEvaluateCover;

	// lean out if we can't hit our Target
	if (! m_Pawn.CanHit(Target))
	{
		// start leaning
		Lean();

		// lean for a bit
		sleep(RandRange(MinLeanTime, MaxLeanTime));

		// if we can't hit our current Target, we should re-evaluate our cover
		if (! m_Pawn.CanHit(Target))
		{
			if (m_Pawn.logAI)
				log("re evaluate cover");

			bReEvaluateCover = true;
		}

		// stop leaning
		StopLeaning();

		if (! m_Pawn.CanHit(Target))
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
	local Pawn Target;

	// while we can still attack (Target is not dead)
	do
	{
		Target = GetEnemy();

		Attack(Target, true);

		// rotate to the attack orientation
		AttackRotation.Yaw = CoverResult.coverYaw;
		RotateToAttackRotation(Target);

		if (CoverResult.coverLocationInfo == kAICLI_InLowCover)
		{
			AttackWhileCrouchingBehindCover(Target);
		}
		else
		{
			AttackWhileLeaningBehindCover(Target);
		}

		yield();
	} until (! class'Pawn'.static.checkConscious(Target));
}

state Running
{
 Begin:
	waitForResourcesAvailable(achievingGoal.priority, achievingGoal.priority);

	// create a sensor so we fail if we get to close to the suspects
	DistanceSensor = DistanceSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceSensor', characterResource(), 0, 1000000 ));
	assert(DistanceSensor != None);
	DistanceSensor.SetParameters(MinDistanceToSuspectsWhileTakingCover, GetEnemy(), false);

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
	satisfiesGoal = class'AttackEnemyGoal'
}
