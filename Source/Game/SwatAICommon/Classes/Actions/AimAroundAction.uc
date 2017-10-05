///////////////////////////////////////////////////////////////////////////////
// AimAroundAction.uc - AimAroundAction class
// Causes the AI to aim around its location (somewhat randomly) in a natural fashion

class AimAroundAction extends SwatWeaponAction
    implements Engine.IInterestedPawnDied, Engine.IInterestedActorDestroyed
    native
    dependson(UpperBodyAnimBehaviorClients)
    dependson(ISwatAI);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////
//
// AimAroundAction variables

enum EAimFov
{
    kAimFovNone,
    kAimFovOuter,
    kAimFovInner,
};

enum EStaircaseTravelDirection
{
    kStaircaseTravelDirectionNone,
    kStaircaseTravelDirectionUp,
    kStaircaseTravelDirectionDown,
};

// copied from AimAroundGoal
var(Parameters) private float							MinAimAtPointTime;
var(Parameters) private float							MaxAimAtPointTime;

var(Parameters) private float							MinWaitForNewPointTime;
var(Parameters) private float							MaxWaitForNewPointTime;

var(Parameters) private bool							bDoOnce;
var(Parameters) private bool							bOnlyAimIfMoving;
var(Parameters) private float							ExtraDoorWeight;
var(Parameters) private bool							bAimWeapon;
var(Parameters) private bool							bUseUpperBodyProcedurally;
var(Parameters) private bool							bAimOnlyIfCharacterResourcesAvailable;

var(Parameters) private EUpperBodyAnimBehaviorClientId	UpperBodyAnimBehaviorClientId;

// Points are weighted differently depending on whether the point is within
// the inner fov or the outer fov
var(Parameters) private float							AimInnerFovDot;
var(Parameters) private float							AimOuterFovDot;
var(Parameters) private float							PointTooCloseRadius;

var(Parameters) protected bool							bInitialDelay;
var(Parameters) protected float							MinInitialDelayTime;
var(Parameters) protected float							MaxInitialDelayTime;

var private float										StairCasePointWeight;// @NOTE: Should be a goal-specified parameter

// internal
var private bool										bForceReevaluation;
var private float										AimAtPointDuration;
var private Actor										CurrentAimPoint;
var private EUpperBodyAnimBehavior                      CurrentUpperBodyAnimBehavior;
var private array<Pawn>									FriendlyPawns;

// Set if the pawn is aiming at a staircase aim point
var private EStaircaseTravelDirection					StaircaseTravelDirectionForCurrentAimPoint;

// Data we cache while determining the next point to aim at
var private bool										PawnIsMoving;
var private vector										PawnDirectionNormal;
var private vector										CurrentAimDirectionNormal;
var private array<vector>								FriendlyPawnDirectionNormals;

// The minimum z difference for a staircase aim point to be considered for
// aiming at.
const kStaircaseAimPointMinZDiff = 64.0;
// A somewhat arbitrary small value for use when determining the direction of
// staircase travel. Unit differences smaller than this are considered
// negligible.
const kStaircaseTravelDirectionSmallValue = 8.0;

// Cap the FindAndAimAtPoint loop attempts, as a fail-safe measure to avoid
// infinite looping.
const kMaxFindAndAimAtPointAttempts = 10;

// Points within this distance get a penalty * the confidence applied to their
// aim weight, to dissuade guys looking at high-confidence points that are
// right next to them.
const kAwarenessPointClosePenaltyDistance = 192.0;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
    local Pawn OtherPawn;

    super.initAction(r, goal);

	m_Pawn.Level.RegisterNotifyPawnDied(self);
	m_Pawn.Level.RegisterNotifyActorDestroyed(self);

    // Cache the friendly pawns in the world, for use when choosing an aim
    // point.
    for (OtherPawn = m_Pawn.Level.PawnList; OtherPawn != None; OtherPawn = OtherPawn.NextPawn)
    {
        if (OtherPawn != m_Pawn &&
            !ISwatAI(m_Pawn).IsOtherActorAThreat(OtherPawn))
        {
            FriendlyPawns[FriendlyPawns.length] = OtherPawn;
        }
    }

	if (bAimWeapon)
	{
        CurrentUpperBodyAnimBehavior = kUBAB_AimWeapon;
	}
	else
	{
        CurrentUpperBodyAnimBehavior = kUBAB_LowReady;
	}
    SetCurrentUpperBodyAnimBehavior();
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
    super.cleanup();

	m_Pawn.Level.UnregisterNotifyPawnDied(self);
	m_Pawn.Level.UnregisterNotifyActorDestroyed(self);

    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(UpperBodyAnimBehaviorClientId);
}

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

function float selectionHeuristic( AI_Goal goal )
{
	if (satisfiesGoal == goal.class)
	{
		return 1.0;
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////

function SetCurrentUpperBodyAnimBehavior()
{
    if (!bUseUpperBodyProcedurally || !ISwatAI(m_Pawn).HasUsableWeapon())
    {
        CurrentUpperBodyAnimBehavior = kUBAB_FullBody;
    }

    ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(CurrentUpperBodyAnimBehavior, UpperBodyAnimBehaviorClientId);
}

///////////////////////////////////////

function OnOtherPawnDied(Pawn DeadPawn)
{
    RemovePawnFromCachedData(DeadPawn);
}

///////////////////////////////////////

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
    if (ActorBeingDestroyed.IsA('Pawn'))
    {
        RemovePawnFromCachedData(Pawn(ActorBeingDestroyed));
    }
}

///////////////////////////////////////

function RemovePawnFromCachedData(Pawn Pawn)
{
    local int i;
    for (i = 0; i < FriendlyPawns.length; i++)
    {
        if (FriendlyPawns[i] == Pawn)
        {
            FriendlyPawns.remove(i, 1);
            break;
        }
    }
}

///////////////////////////////////////

function ForceReevaluation()
{
    bForceReevaluation = true;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// Sets the output 'result' variable with the direction normal. Returns the
// magnitude of the vector from the origin to the target.
function float GetAimDirectionNormal(Actor Target, out vector result)
{
    local vector PawnLocation;
    local float magnitude;

    assert(Target != None);

    PawnLocation = ISwatAI(m_Pawn).AnimGetAimOrigin();
    if (PawnIsMoving)
        PawnLocation += m_Pawn.Velocity * AimAtPointDuration;

    // Find the unnormalized vector, find the magnitude, then normalize, and
    // return the magnitude.
    result = Target.GetAimLocation(m_Pawn.GetActiveItem()) - PawnLocation;
    magnitude = VSize(result);
    result /= magnitude;
    return magnitude;
}

///////////////////////////////////////

native function bool  IsPointTooClose(Actor Point);
native function float GetZDiffFromPawnToActor(Actor Actor);

///////////////////////////////////////

function EAimFov GetAimDirectionFov(vector AimDirectionNormal)
{
    local float d;

    d = PawnDirectionNormal Dot AimDirectionNormal;

    // If the aim direction to this point is outside the aim fov, return a 0
    // weight.
    if (d >= AimInnerFovDot)
    {
        return kAimFovInner;
    }

    if (d >= AimOuterFovDot)
    {
        return kAimFovOuter;
    }

    return kAimFovNone;
}

///////////////////////////////////////

function ApplyConfidenceAndDistanceWeight(out float Weight, EAimFov AimFov, float Confidence, float Distance)
{
    local float ClosenessWeight;
    local float ConfidenceWeight;

    // Invert confidence, so that low confidence = higher aim weight
    ConfidenceWeight = 1.0 - Confidence;

    // If this point is in the close penalty distance, scale its weight down,
    // thus urging the pawn to only aim at it if it truly has a high weight
    // (low confidence)
    if (Distance < kAwarenessPointClosePenaltyDistance)
    {
        // .25 is as close as possible, 1 is at kAwarenessPointClosePenaltyDistance, then
        // square it to make the distance weight drop stronger.
        ClosenessWeight = ((Distance / kAwarenessPointClosePenaltyDistance) * 0.75) + 0.25;
        ClosenessWeight *= ClosenessWeight;

        // Apply it to the confidence weight
        ConfidenceWeight *= ClosenessWeight;
    }

    // If this point is in the outer fov, square it's weight. This will drop
    // low weights even lower, thus urging the pawn to only aim at an outer
    // fov point if it truly has a high weight (low confidence)
    if (AimFov == kAimFovOuter)
    {
        ConfidenceWeight *= ConfidenceWeight;
    }

    // Compress weight to between .1 and 1.0, to reserve 0.0 as being truly unaimable
    ConfidenceWeight = 0.9 * (ConfidenceWeight - 1.0) + 1.0;
    Weight += ConfidenceWeight;
}

///////////////////////////////////////

function ApplyThreatWeight(out float Weight, EAimFov AimFov, float Threat)
{
    local float ThreatWeight;
    ThreatWeight = Threat;

    // If this point is in the outer fov, square it's weight. This will drop
    // low weights even lower, thus urging the pawn to only aim at an outer
    // fov point if it truly has a high weight (low threat)
    if (AimFov == kAimFovOuter)
    {
        ThreatWeight = ThreatWeight * ThreatWeight;
    }

    // Quadruple the weight of threat, and add it to our total weight
    Weight += ThreatWeight * 4.0;
}

///////////////////////////////////////

function ApplyAimDirectionSimilarityWeight(out float Weight, EAimFov AimFov, vector AimDirectionNormal)
{
    local float AimDirectionSimilarity;

    // Only perform this weighting on inner fov points
    if (AimFov == kAimFovInner)
    {
        // Scale by the inverse dot product (clamped at 0) between the aim
        // direction to this point, and the pawn's current aim direction. This
        // favors points that are dissimilar to the current aim, so the pawn looks
        // more dynamic and active.
        // This scale factor is stretched to be within 0.5 to 2.0.
        AimDirectionSimilarity = CurrentAimDirectionNormal Dot AimDirectionNormal;
        if (AimDirectionSimilarity < 0.0)
        {
            AimDirectionSimilarity = 0.0;
        }
        AimDirectionSimilarity = 1.0 - AimDirectionSimilarity;
        AimDirectionSimilarity = (1.5 * AimDirectionSimilarity) + 0.5;
        Weight *= AimDirectionSimilarity;
    }
}

///////////////////////////////////////

function ApplyNearFriendlyPawnPenalty(out float Weight, EAimFov AimFov, vector AimDirectionNormal)
{
    local int i;
    local float Similarity;
    local float MinSimilarityDot;
    local float TotalSimilarity;

    // about 11.25 degree dot product
    MinSimilarityDot = 0.981;

    // For each direction to a friendly pawn, compare it to the aim direction.
    // If the angle is identical, weight the similarity 1.0. If the angle is
    // 11.25 degrees and above, weight the similarity 0.0. Linearly interpolate
    // for all angles in between.
    for (i = 0; i < FriendlyPawnDirectionNormals.length && TotalSimilarity < 1.0; i++)
    {
        Similarity = AimDirectionNormal Dot FriendlyPawnDirectionNormals[i];
        Similarity = (Similarity - MinSimilarityDot) / (1.0 - MinSimilarityDot);
        Similarity = FClamp(Similarity, 0.0, 1.0);
        TotalSimilarity += Similarity;
    }

    TotalSimilarity = FClamp(TotalSimilarity, 0.0, 1.0);

    // Multiply the weight by the inverse of the similarity. That is to say,
    // the more similar this aim direction is to the direction of one of our
    // friendly pawns, the less weight we want to give it.
    Weight *= 1.0 - TotalSimilarity;
}

///////////////////////////////////////

function ApplyExtraDoorWeight(out float Weight, EAimFov AimFov, AwarenessPoint AwarenessPoint)
{
    local NavigationPoint ClosestNavigationPointToAwarenessPoint;

    ClosestNavigationPointToAwarenessPoint = AwarenessPoint.GetClosestNavigationPoint();

    if (AimFov == kAimFovInner &&
        ClosestNavigationPointToAwarenessPoint != None &&
        ClosestNavigationPointToAwarenessPoint.IsA('Door'))
    {
        Weight += ExtraDoorWeight;
    }
}

///////////////////////////////////////

function float GetKnowledgeAimWeight(AwarenessProxy.AwarenessKnowledge Knowledge)
{
    local float  Weight;
    local float  Distance;
    local vector AimDirectionNormal;
    local EAimFov AimFov;

    // Set up some data we'll be using:
    Weight = 0.0;
    // The aim direction from the pawn to the point
    Distance = GetAimDirectionNormal(Knowledge.aboutAwarenessPoint, AimDirectionNormal);

    if (!IsPointTooClose(Knowledge.aboutAwarenessPoint))
    {
        AimFov = GetAimDirectionFov(AimDirectionNormal);

        if (AimFov != kAimFovNone)
        {
            // Weighting logic for points within the pawn's inner aim fov
			ApplyConfidenceAndDistanceWeight(Weight, AimFov, Knowledge.confidence, Distance);
//			log("weight after confidence test is: " $ Weight);

            ApplyThreatWeight(Weight, AimFov, Knowledge.threat);
//			log("weight after threat test is: " $ Weight);

			ApplyAimDirectionSimilarityWeight(Weight, AimFov, AimDirectionNormal);
//			log("weight after similarity test is: " $ Weight);

			ApplyNearFriendlyPawnPenalty(Weight, AimFov, AimDirectionNormal);
//			log("weight after near friendly pawn test is: " $ Weight);

			ApplyExtraDoorWeight(Weight, AimFov, Knowledge.aboutAwarenessPoint);
//			log("weight after near extra door weight test is: " $ Weight);
        }
    }

    return Weight;
}

///////////////////////////////////////

function CacheWeightProcessingData()
{
    local Pawn OtherPawn;
    local int i;

    // Calculated once and store as members. Used by GetKnowledgeAimWeight()
    PawnIsMoving = (VSize(m_Pawn.Velocity) > 0.0);
    if (PawnIsMoving)
        PawnDirectionNormal = Normal(m_Pawn.Velocity);
    else
        PawnDirectionNormal = Normal(vector(m_Pawn.Rotation));

    if (CurrentAimPoint != None)
        GetAimDirectionNormal(CurrentAimPoint, CurrentAimDirectionNormal);
    else
        CurrentAimDirectionNormal = PawnDirectionNormal;

    // Get the direction normals to each of the friendly pawns we have a line
    // of sight to
    FriendlyPawnDirectionNormals.remove(0, FriendlyPawnDirectionNormals.length);
    FriendlyPawnDirectionNormals.insert(0, FriendlyPawns.length);
    for (i = 0; i < FriendlyPawns.length; i++)
    {
        OtherPawn = FriendlyPawns[i];
        if (m_Pawn.LineOfSightTo(OtherPawn))
        {
            GetAimDirectionNormal(OtherPawn, FriendlyPawnDirectionNormals[i]);
        }
    }
}

///////////////////////////////////////

native function EStaircaseTravelDirection GetStaircaseTravelDirection();

///////////////////////////////////////

// Returns None if pawn is not on a staircase. Otherwise, returns the most
// desirable staircase point to aim at, depending on the direction of stair
// travel.
function StairCaseAimPoint GetStaircaseAimPoint()
{
    local ISwatAI SwatAI;

    local int i;
    local int NumTouchingStaircaseVolumes;
    local StaircaseAimVolume StaircaseAimVolume;

    local int j;
    local int NumStaircaseAimPoints;
    local StaircaseAimPoint StaircaseAimPoint;

    local EStaircaseTravelDirection StaircaseTravelDirection;
    local float ZDiff;

    local StairCaseAimPoint BestStairCaseAimPoint;
    local float BestStairCaseAimPointZDiff;

    SwatAI = ISwatAI(m_Pawn);
    assert(SwatAI != None);

    // Iterate over staircase aim volumes that the pawn is in
    NumTouchingStaircaseVolumes = SwatAI.GetNumTouchingStaircaseAimVolumes();

    // If we are in at least one staircase aim volume, calculate the staircase
    // travel direction
    StaircaseTravelDirection = kStaircaseTravelDirectionNone;
    if (NumTouchingStaircaseVolumes > 0)
    {
        StaircaseTravelDirection = GetStaircaseTravelDirection();
    }

    // Only find a staircase aim point if we can determine a valid direction
    // of travel.
    if (StaircaseTravelDirection != kStaircaseTravelDirectionNone)
    {
        for (i = 0; i < NumTouchingStaircaseVolumes; i++)
        {
            // Iterate over the staircase aim points for this volume
            StaircaseAimVolume = SwatAI.GetTouchingStaircaseAimVolumeAtIndex(i);
            NumStaircaseAimPoints = StaircaseAimVolume.GetNumStaircaseAimPoints();
            for (j = 0; j < NumStaircaseAimPoints; j++)
            {
                StaircaseAimPoint = StaircaseAimVolume.GetStaircaseAimPointAtIndex(j);
                ZDiff = GetZDiffFromPawnToActor(StaircaseAimPoint);

                if (!IsPointTooClose(StaircaseAimPoint))
                {
                    if (StaircaseTravelDirection == kStaircaseTravelDirectionUp)
                    {
                        // When moving up, use the point that has the greatest positive ZDiff
                        if (ZDiff > kStaircaseAimPointMinZDiff && (BestStairCaseAimPoint == None || ZDiff > BestStairCaseAimPointZDiff))
                        {
                            BestStairCaseAimPoint = StaircaseAimPoint;
                            BestStairCaseAimPointZDiff = ZDiff;
                        }
                    }
                    else if (StaircaseTravelDirection == kStaircaseTravelDirectionDown)
                    {
                        // When moving down, use the point that has the lowest negative ZDiff
                        if (ZDiff < -kStaircaseAimPointMinZDiff && (BestStairCaseAimPoint == None || ZDiff > BestStairCaseAimPointZDiff))
                        {
                            BestStairCaseAimPoint = StaircaseAimPoint;
                            BestStairCaseAimPointZDiff = ZDiff;
                        }
                    }
                }
            }
        }
    }

    StaircaseTravelDirectionForCurrentAimPoint = StaircaseTravelDirection;

    return BestStairCaseAimPoint;
}

///////////////////////////////////////

function FindBestPointToAimAt()
{
    local array<AwarenessProxy.AwarenessKnowledge> PotentiallyVisibleSet;
    local AwarenessProxy.AwarenessKnowledge Knowledge;

    local StairCaseAimPoint StairCaseAimPoint;

    // Used to track the best aim point we've found so far, and its weight
    local Actor BestAimPoint;
    local float BestAimPointWeight;
    local bool bLocalAimWeapon;

    local int i;
    local float Weight;

	local FiredWeapon CurrentWeapon;

    CacheWeightProcessingData();

    // Get the knowledge about the potentially visible set of awareness points
    PotentiallyVisibleSet = ISwatAI(m_Pawn).GetAwareness().GetPotentiallyVisibleKnowledge(m_Pawn);

    for(i = 0; i < PotentiallyVisibleSet.Length; ++i)
    {
        Knowledge = PotentiallyVisibleSet[i];

        // Avoid looking at the pawn's anchor, and make sure we can aim at the
        // point.
        if (Knowledge.aboutAwarenessPoint != m_Pawn.Anchor.GetClosestAwarenessPoint() &&
            ISwatAI(m_Pawn).AnimCanAimAtDesiredActor(Knowledge.aboutAwarenessPoint))
        {
//			log("testing weight for " $ Knowledge.aboutAwarenessPoint.Name);

            Weight = GetKnowledgeAimWeight(Knowledge);
            if (Weight > BestAimPointWeight)
            {
                BestAimPoint = Knowledge.aboutAwarenessPoint;
                BestAimPointWeight = Weight;
            }
        }
    }

    // Special case for stair aiming: if stair case aim point weight is
    // greater than the weight for our best point, use the stair case aim
    // point instead
    StairCaseAimPoint = GetStaircaseAimPoint();
    if (StairCaseAimPoint != None && StairCasePointWeight > BestAimPointWeight)
    {
        BestAimPoint = StairCaseAimPoint;
        bLocalAimWeapon = true;
    }

    // Pretty ugly. If we're not already aiming our weapon due to the action
    // behavior, there are situations where we want to temporarily raise or
    // lower our weapon.
	// Otherwise, if we're supposed to be aiming our weapon, make sure we can hit this point,
	// and if we can't hit the point use full body

	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

    if (!bAimWeapon)
    {
		if (CurrentWeapon == None && m_pawn.IsA('SwatOfficer'))
		{
			CurrentUpperBodyAnimBehavior = kUBAB_AimWeapon;
		}
		else if (CurrentWeapon == None)
		{
			CurrentUpperBodyAnimBehavior = kUBAB_FullBody;
		}
		else if (bLocalAimWeapon)
        {
            CurrentUpperBodyAnimBehavior = kUBAB_AimWeapon;
        }
        else
        {
            CurrentUpperBodyAnimBehavior = kUBAB_LowReady;
        }
    }
	else
	{
		// if we don't find a point, or we can't hit the point,
		// go low ready if possible, otherwise go full body
		if ((BestAimPoint == None) || (CurrentWeapon == None) || ! m_Pawn.CanHit(BestAimPoint))
		{
			if ((CurrentWeapon != None) && ISwatAI(m_Pawn).CanPawnUseLowReady())
			{
				CurrentUpperBodyAnimBehavior = kUBAB_LowReady;
			}
			else
			{
				CurrentUpperBodyAnimBehavior = kUBAB_FullBody;
			}
		}
	}

    // Store the best results as a member
    CurrentAimPoint = BestAimPoint;
}

///////////////////////////////////////

native function bool ShouldContinueAimingAtCurrentPoint();

///////////////////////////////////////

// Aims at CurrentAimPoint is it is valid.
// Sets CurrentAimPoint to None and returns if the pawn was unable to aim at
// the point for the entire duration,
latent function AimAtBestPoint()
{
    local ISwatAI SwatAI;
    local float EndAimTime;

    SwatAI = ISwatAI(m_Pawn);

    if (SwatAI != None)
    {
        // Only aim at if if we can
        if (CurrentAimPoint != None)
        {
            ISwatAI(m_pawn).AimAtActor(CurrentAimPoint);
            SetCurrentUpperBodyAnimBehavior();

            // Hold this aim for the timed duration, or until our aim point is too
            // close to us.
            EndAimTime = m_Pawn.Level.TimeSeconds + AimAtPointDuration;

            while (m_Pawn.Level.TimeSeconds < EndAimTime)
            {
                if (!ShouldContinueAimingAtCurrentPoint())
                {
                    CurrentAimPoint = None;
                    return;
                }

                yield();
            }
        }
        else
        {
            // Still set the upper body anim behavior accordingly, even if
            // we have no point to aim at
            SetCurrentUpperBodyAnimBehavior();
        }
    }
}

///////////////////////////////////////

private function bool CanAimAtNewPoint()
{
	local AI_MovementResource MovementResource;

	// if we can only aim if the movement resource is available
	// (obviously the weapon resource is available, otherwise we wouldn't be running!)
	if (bAimOnlyIfCharacterResourcesAvailable)
	{
		MovementResource = AI_MovementResource(m_Pawn.movementAI);
		assert(MovementResource != None);

		if (! MovementResource.requiredResourcesAvailable(achievingGoal.priority, 0))
			return false;
	}

	// by default we can aim at the new point
	return true;
}

latent function FindAndAimAtPoint()
{
    local bool tryAgain;
    local int  attempts;

    // first, pick the random aim time
    AimAtPointDuration = RandRange(MinAimAtPointTime, MaxAimAtPointTime);

	tryAgain = true;
//	log(m_Pawn.Name $ " CanAimAtNewPoint(): " $ CanAimAtNewPoint());
	while (CanAimAtNewPoint() && (tryAgain == true))
	{
		tryAgain = false;

		// Find point. This sets CurrentAimPoint
		FindBestPointToAimAt();
		if (CurrentAimPoint != None)
		{
			// If we found a valid point, aim at it
			AimAtBestPoint();
			// If AimAtBestPoint set CurrentAimPoint to None, that means it
			// could not aim at the point for the entire aim time duration.
			// Find a new point and try that
			if (CurrentAimPoint == None && ++attempts < kMaxFindAndAimAtPointAttempts)
			{
				tryAgain = true;
			}
		}
	}
}

///////////////////////////////////////

state Running
{
Begin:
	// if we're supposed to delay our first time, sleep for the delay amount and don't do it again
	if (bInitialDelay)
	{
		sleep(RandRange(MinInitialDelayTime, MaxInitialDelayTime));

		bInitialDelay = false;
	}

  if(AimAroundGoal(achievingGoal).CancelWhenCompliant && (ISwatAI(m_Pawn).IsCompliant() || ISwatAI(m_Pawn).IsArrested()))
  {
    instantSucceed();
  }

  if(AimAroundGoal(achievingGoal).CancelWhenStunned && false)
  {
    // FIXME: need a check here...
  }

    if (!bOnlyAimIfMoving || (VSize(m_Pawn.Velocity) > 0.0))
    {
		// now aim at the point
        FindAndAimAtPoint();
    }
    else
    {
        // if we're not going to choose to aim at anything based on our not moving,
        // we shouldn't have a current aim target
        CurrentAimPoint = None;
    }

    if (bDoOnce)
    {
        succeed();
    }
    else
    {
        if (CurrentAimPoint == None)
        {
            sleep(RandRange(MinWaitForNewPointTime, MaxWaitForNewPointTime));
        }

        yield();
        goto('Begin');
    }
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    satisfiesGoal=class'AimAroundGoal'
    StairCasePointWeight = 200.0 // Yikes.. for testing, and forcing staircase aiming behavior. Must be tuned
}

///////////////////////////////////////////////////////////////////////////////
