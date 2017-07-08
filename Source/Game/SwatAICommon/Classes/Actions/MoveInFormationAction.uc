///////////////////////////////////////////////////////////////////////////////

class MoveInFormationAction extends MoveToActorAction;

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) float InnerMoveToThreshold;
var(parameters) float OuterMoveToThreshold;

var(parameters) float InnerWalkThreshold;
var(parameters) float OuterWalkThreshold;

// internal destination
var private Pawn	  FormationDestination;

const kDistanceSensorCollisionHeightMultiplier = 2.0;

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function Actor GetDestinationActor()
{
	assert(FormationDestination != None);

    return FormationDestination;
}

function vector GetDestination()
{
	return FormationDestination.Location;
}

///////////////////////////////////////////////////////////////////////////////
// 
// Distance Sensor

protected function SetDistanceSensorParameters()
{
	SetFormationDestination();

	WalkThresholdTarget = FormationDestination;
	DistanceSensor.setParameters( WalkThreshold, WalkThresholdTarget, ShouldUseNavigationDistanceOnSensor() );

	DistanceSensor.SetCollisionHeightMultiplier(kDistanceSensorCollisionHeightMultiplier);
	DistanceSensor.UpdateTarget = UpdateDistanceSensorTarget;
}

private function SetFormationDestination()
{
	local Formation CurrentFormation;

	CurrentFormation = ISwatOfficer(m_Pawn).GetCurrentFormation();
	assert(CurrentFormation != None);

	FormationDestination = CurrentFormation.GetDestinationForMember(m_Pawn);
	assert(FormationDestination != None);
}

function UpdateDistanceSensorTarget()
{
	SetFormationDestination();

	WalkThresholdTarget = FormationDestination;
	DistanceSensor.ResetTargetActor(WalkThresholdTarget);
}

// allows us to run/walk based on the guy in front of us
function HandleDistanceSensorMessage(AI_SensorData value)
{
	local Formation CurrentFormation;
	local Pawn PawnInFront;
	local bool bWillWalk, bPawnInFrontIsMoving, bIsWithinRequiredDistance;

	CurrentFormation = ISwatOfficer(m_Pawn).GetCurrentFormation();
	assert(CurrentFormation != None);

	// if we're the leader
	if (CurrentFormation.IsLeader(m_Pawn))
	{
//		log(" is leader " );
		// TODO: handle the AI being the leader
	}
	else
	{
		PawnInFront               = FormationDestination;
		bIsWithinRequiredDistance = DistanceSensor.IsWithinRequiredDistance();
		WalkThresholdTarget       = PawnInFront;

//		log("handle distance sensor message - PawnInFront: " $ PawnInFront.Name $ " - bIsWithinRequiredDistance: " $ bIsWithinRequiredDistance $ " value.integerData: " $ value.integerData $ " bPawnInFrontIsMoving: " $ bPawnInFrontIsMoving $ " PawnInFront.bIsWalking: " $ PawnInFront.bIsWalking);

		if (! bIsWithinRequiredDistance)
		{
			OverriddenMoveToThreshold = OuterMoveToThreshold;
			WalkThreshold             = OuterWalkThreshold;

			// we will run
			bWillWalk = false;
		}
		else if (bIsWithinRequiredDistance && (!bPawnInFrontIsMoving || !PawnInFront.IsAtRunningSpeed())) // if we're close enough and the pawn in front is not moving or walking
		{
			OverriddenMoveToThreshold = InnerMoveToThreshold;
			WalkThreshold             = InnerWalkThreshold;

			// we will walk
			bWillWalk = true;
		}

//		log("OverriddenMoveToThreshold is: " $ OverriddenMoveToThreshold $ " WalkThreshold is: " $ WalkThreshold);
		DistanceSensor.ResetRequiredDistance(WalkThreshold);
	}

	MoveToGoalBase(achievingGoal).SetShouldWalk(bWillWalk);
	SetMovement(bWillWalk, bShouldCrouch);
}

///////////////////////////////////////////////////////////////////////////////
// 
// Notifications

function NotifyFinishedMovingToLocation()
{
	local Pawn Leader;
	local Formation CurrentFormation;

	// while we're within the required distance, check if the leader is walking (so we walk too)
	if (DistanceSensor.IsWithinRequiredDistance())
	{
		CurrentFormation = ISwatOfficer(m_Pawn).GetCurrentFormation();
		assert(CurrentFormation != None);

		if (CurrentFormation.IsLeader(m_Pawn))
		{
			// TODO: handle the AI being the leader
		}
		else
		{
			Leader = CurrentFormation.GetLeader();

			// if the leader is not at running speed but we are, we should walk
			if (! Leader.IsAtRunningSpeed() && !m_Pawn.bIsWalking)
			{
				MoveToGoalBase(achievingGoal).SetShouldWalk(true);
				SetMovement(true, bShouldCrouch);
			}
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

state Running
{
 Begin:
    MoveToActor();
	NotifyFinishedMovingToLocation();
	yield();
	goto('Begin');
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'MoveInFormationGoal'
}