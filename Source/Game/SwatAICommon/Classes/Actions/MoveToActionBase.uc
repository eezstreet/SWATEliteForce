///////////////////////////////////////////////////////////////////////////////

class MoveToActionBase extends SwatMovementAction
	implements Tyrion.ISensorNotification
    native
    abstract;

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;

///////////////////////////////////////////////////////////////////////////////

var protected bool			bHasRotatedTowardFirstPoint;
var protected bool			bWasAvoidingCollision;

// this is a hack until we're able to test whether we are currently in one of the latent MoveTo functions
var protected bool			bIsMoving;						

// allows us to complete moving when reachability says we won't hit anything but we end up hitting something
var private float			MovementTimeOut;
const kMovementTimeOutFudge = 2.0;

// Copied from our goal
var(parameters) bool		bShouldCrouch;
var(parameters) float		MoveToThreshold;
var(parameters) bool		bRotateTowardsFirstPoint;
var(parameters) bool		bRotateTowardsPointsDuringMovement;
var(parameters) bool		bAcceptNearbyPath;
var(parameters) bool		bShouldCloseOpenedDoors;
var(parameters) bool		bShouldNotCloseInitiallyOpenDoors;
var(parameters) bool		bAllowDirectMoveFailure;
var(parameters) bool		bUseCoveredPaths;
var(parameters) bool		bOpenDoorsFrantically;
var(parameters) bool		bUseNavigationDistanceOnSensor;
var(parameters) bool		bShouldSucceedWhenDestinationBlocked;
var(parameters) float		WalkThreshold;
var(parameters) Actor		WalkThresholdTarget;

// overriding movement thresholds
var private float			OriginalMoveToThreshold;
var protected float			OverriddenMoveToThreshold;

// behaviors we can use
var private OpenDoorGoal	CurrentOpenDoorGoal;
var private CloseDoorGoal	CurrentCloseDoorGoal;

// our sensors
var DistanceSensor			DistanceSensor;

const kMovementPointZOffset = 32.0;

///////////////////////////////////////////////////////////////////////////////
//
// selection heuristic

// try to match exactly for movement behaviors
function float selectionHeuristic( AI_Goal goal )
{
	if (satisfiesGoal == goal.class)
	{
		return 1.0;
	}
	else
	{
		return 0.1;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// we try again if our open door behavior was not interrupted
	if ((errorCode != ACT_INTERRUPTED) &&
		((goal == CurrentOpenDoorGoal) || (goal == CurrentCloseDoorGoal)))
	{
		instantFail(errorCode);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Generic Destination Accessor

function vector GetDestination()
{
	assert(IMoveToInformation(achievingGoal) != none);
	return IMoveToInformation(achievingGoal).GetDestination();
}

///////////////////////////////////////////////////////////////////////////////
//
// Should Stop Moving

// called during a MoveToward call, in case we want to interrupt it for some reason
event bool ShouldStopMoving()
{
	assert(achievingGoal != None);
	assertWithDescription(achievingGoal.IsA('MoveToGoalBase'), "achievingGoal is:"@achievingGoal);

    return MoveToGoalBase(achievingGoal).ShouldStopMovingDelegate(m_Pawn) || IsInPosition();
}

protected function bool IsInPosition()
{
	return false;
}

event bool ShouldWalk()
{
	assert(achievingGoal != None);
	assertWithDescription(achievingGoal.IsA('MoveToGoalBase'), "achievingGoal is:"@achievingGoal);

    return MoveToGoalBase(achievingGoal).ShouldWalkDelegate();
}

///////////////////////////////////////////////////////////////////////////////
//
// Distance Sensor

protected function ActivateDistanceSensor()
{
	DistanceSensor = DistanceSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceSensor', movementResource(), 0, 1000000 ));
	assert(DistanceSensor != None);

	// call to subclasses to set the distance sensor parameters
	SetDistanceSensorParameters();
}

protected function SetDistanceSensorParameters()
{
	assert(false); // must be overridden
}

protected function bool ShouldUseNavigationDistanceOnSensor()
{
	return bUseNavigationDistanceOnSensor;
}

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if (m_Pawn.logTyrion)
		log("MoveToActionBase received sensor message from " $ sensor.name $ " value is "$ value.integerData);

	// we only (currently) get messages from a distance sensor
	assert(sensor == DistanceSensor);

	HandleDistanceSensorMessage(value);
}

// subclasses should override completely.
function HandleDistanceSensorMessage(AI_SensorData value)
{
	local bool bShouldWalk;

	// only determine if we should walk based on distance if we haven't been told to walk the entire time
	if (! MoveToGoalBase(achievingGoal).ShouldWalkEntireMove())
	{
		if (value.integerData == 1)
		{
			bShouldWalk = true;
		}
		else
		{
			bShouldWalk = false;
		}

		// determine walking based on our distance sensor
		MoveToGoalBase(achievingGoal).SetShouldWalk(bShouldWalk);
				
		SetMovement(bShouldWalk, bShouldCrouch);
	}
}

///////////////////////////////////////////////////////////////////////////////

// by default we run, and by default we don't crouch
event SetMovement(bool bWalkWhileMoving, bool bCrouchWhileMoving)
{
//	log("MoveToActionBase::SetMovement - bWalkWhileMoving: " $ bWalkWhileMoving $ " bCrouchWhileMoving: " $ bCrouchWhileMoving);

	if (m_pawn.bIsWalking != bWalkWhileMoving)
	{
		m_pawn.bIsWalking = bWalkWhileMoving;
	}
	
	if (m_pawn.bWantsToCrouch != bCrouchWhileMoving)
	{
		m_pawn.ShouldCrouch(bCrouchWhileMoving);
	}
}

///////////////////////////////////////////////////////////////////////////////

native final latent function MoveTowardActor(Actor actor, optional Actor viewFocus, optional float destinationOffset, optional bool bUseStrafing);

native final latent function MoveTowardLocation(vector location, optional Actor ViewFocus);

native final function Actor FindPathToActor(Actor actor, bool bAcceptNearbyPath);

native final function Actor FindPathToLocation(vector location, bool bAcceptNearbyPath);

///////////////////////////////////////////////////////////////////////////////
//
// Initialization / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	local EUpperBodyAnimBehavior MovementUpperBodyAimBehavior;

    super.initAction(r, goal);

	OriginalMoveToThreshold   = m_Pawn.ReachedDestinationThreshold;
	OverriddenMoveToThreshold = MoveToThreshold;

	if (bUseCoveredPaths)
	{
		ISwatAI(m_pawn).EnableFavorCoveredPath(SwatCharacterResource(m_Pawn.characterAI).CommonSensorAction.GetVisionSensor().Pawns);
	}

	ActivateDistanceSensor();

	MovementUpperBodyAimBehavior = ISwatAI(m_Pawn).GetMovementUpperBodyAimBehavior();
    ISwatAI(m_pawn).SetUpperBodyAnimBehavior(MovementUpperBodyAimBehavior, kUBABCI_MoveToActionBase);
}

function cleanup()
{
	super.cleanup();

    ISwatAI(m_pawn).UnsetUpperBodyAnimBehavior(kUBABCI_MoveToActionBase);

    if (CurrentOpenDoorGoal != None)
	{
		CurrentOpenDoorGoal.Release();
		CurrentOpenDoorGoal = None;
	}

	if (CurrentCloseDoorGoal != None)
	{
		CurrentCloseDoorGoal.Release();
		CurrentCloseDoorGoal = None;
	}

    if (DistanceSensor != None)
	{
		DistanceSensor.UpdateTarget = None;		// unsets the delegate in case it was set
		DistanceSensor.deactivateSensor(self);
		DistanceSensor = None;
	}

	// make sure the delegates in goal get unset
	MoveToGoalBase(achievingGoal).ShouldStopMovingDelegate = None;
	MoveToGoalBase(achievingGoal).ShouldWalkDelegate       = None;

	// in case the moveto threshold is not reset
	ResetOverriddenMoveToThreshold();

	// in case we have been set to use covered paths
	ISwatAI(m_Pawn).DisableFavorCoveredPath();

	// clear out the route cache because we are done using pathfinding
	m_pawn.ClearRouteCache();
}

///////////////////////////////////////////////////////////////////////////////

protected function SetOverriddenMoveToThreshold()
{
	if (OverriddenMoveToThreshold > 0.0)
	{
		m_Pawn.ReachedDestinationThreshold = OverriddenMoveToThreshold;
	}
}

protected function ResetOverriddenMoveToThreshold()
{
	m_Pawn.ReachedDestinationThreshold = OriginalMoveToThreshold;
}

///////////////////////////////////////////////////////////////////////////////

latent overloaded function RotateTowardsMovementActor(Actor MovementActor)
{
    assert(MoveToGoalBase(achievingGoal) != None);

	if (ShouldRotateTowardsPointsDuringMovement())
	{
		// if we're not already aiming, or if we're aiming something else, don't override it
		if (bRotateTowardsFirstPoint && ! bHasRotatedTowardFirstPoint)
		{
			RotateTowardActor(MovementActor);

			// we've done it!
			bHasRotatedTowardFirstPoint = true;
		}

		if (bRotateTowardsPointsDuringMovement)
		{
			ISwatAI(m_Pawn).AimAtActor(MovementActor);
		}
	}
}

latent overloaded function RotateTowardsMovementPoint(vector MovementPoint)
{
    assert(MoveToGoalBase(achievingGoal) != None);

    if (ShouldRotateTowardsPointsDuringMovement())
    {
	    // make sure we even off the point (like we do for navigation points, pawns, etc.)
	    MovementPoint.Z += kMovementPointZOffset;

	    // if we're not already aiming, or if we're aiming something else, don't override it
	    if (bRotateTowardsFirstPoint && ! bHasRotatedTowardFirstPoint)
	    {
		    RotateTowardPoint(MovementPoint);

		    // we've done it!
		    bHasRotatedTowardFirstPoint = true;
	    }

	    if (bRotateTowardsPointsDuringMovement)
	    {
		    ISwatAI(m_Pawn).AimAtPoint(MovementPoint);
	    }
    }
}

private function bool ShouldRotateTowardsPointsDuringMovement()
{
    // Only rotate towards points if the aim around action is not active
    local AI_Goal AimAroundGoal;
    AimAroundGoal = AI_Resource(m_Pawn.weaponAI).findGoalByName("AimAround");
    return AimAroundGoal == None || AimAroundGoal.HasCompleted() || !AimAroundGoal.beingAchieved();
}

///////////////////////////////////////////////////////////////////////////////

// returns true if we will accept a nearby path when a location (vector) can't be reached
// and we have move to and reached to that nearby path
function bool HasReachedNearbyPath(Actor ReachedActor)
{
	return (bAcceptNearbyPath && m_pawn.controller.bNearbyPathFound &&
		   (ReachedActor == m_Pawn.controller.RouteGoal) && m_Pawn.ReachedDestination(ReachedActor));
}

///////////////////////////////////////////////////////////////////////////////

protected latent function ReportMoveToOutcome(bool succeeded)
{
    if (succeeded == true)
    {
        Succeed();
    }
    else
    {
		if (m_Pawn.logTyrion)
			log("[AI WARNING] - " $ m_Pawn.Name $ " cannot pathfind to our current destination!");

        Fail(ACT_CANT_FIND_PATH);
    }
}

///////////////////////////////////////////////////////////////////////////////

private latent function PostOpenDoorGoal(Door Target)
{
	if (CurrentOpenDoorGoal != None)
	{
		CurrentOpenDoorGoal.unPostGoal(self);
		CurrentOpenDoorGoal.Release();
		CurrentOpenDoorGoal = None;
	}

	// priority of the open door behavior needs to be greater than this behavior's priority
	CurrentOpenDoorGoal = new class'OpenDoorGoal'(AI_Resource(m_pawn.movementAI), achievingGoal.priority+1, Target);
	assert(CurrentOpenDoorGoal != None);
	CurrentOpenDoorGoal.AddRef();

	CurrentOpenDoorGoal.SetShouldWalkEntireMove(ShouldWalk());

	// no walk threshold for opening doors (we set should walk instead)
	CurrentOpenDoorGoal.SetWalkThreshold(0.0);
	CurrentOpenDoorGoal.SetOpenFrantically(bOpenDoorsFrantically);
	CurrentOpenDoorGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentOpenDoorGoal.postGoal(self);
	WaitForGoal(CurrentOpenDoorGoal);
	CurrentOpenDoorGoal.unPostGoal(self);

	CurrentOpenDoorGoal.Release();
	CurrentOpenDoorGoal = None;
}

function bool ShouldCloseDoor(Actor Destination)
{
	local ISwatDoor SwatDoorDestination;
	local Door DoorDestination;
	local bool bPointAheadToLeft;

	if (Destination.IsA('Door') && bShouldCloseOpenedDoors)
	{
		assert(Destination.IsA('ISwatDoor'));
		SwatDoorDestination = ISwatDoor(Destination);
		DoorDestination     = Door(Destination);

		// only try and close normal doors that are open and not broken
		if (! Door(Destination).IsEmptyDoorway() && ! SwatDoorDestination.IsBroken() && (DoorDestination.IsOpen() || DoorDestination.IsOpening()))
		{
			// if we're not supposed to close initially open doors (doors that were set 
			// by the designer to be open from the beginning of the map), we don't close them
			// otherwise we do.
			if (!bShouldNotCloseInitiallyOpenDoors || !ISwatDoor(Destination).WasDoorInitiallyOpen())
			{
				// only try and close a door if we know where we're going
				if (Destination == m_Pawn.Controller.RouteCache[0])
				{
					if (m_Pawn.Controller.RouteCache[1] != None)
					{
						// only try and close a door while moving if it's open to the side we're going to
						bPointAheadToLeft = SwatDoorDestination.ActorIsToMyLeft(m_Pawn.Controller.RouteCache[1]);
						return ((DoorDestination.IsOpen() && (DoorDestination.IsOpenLeft() == bPointAheadToLeft)) || 
								(DoorDestination.IsOpening() && (DoorDestination.IsOpeningLeft() == bPointAheadToLeft)));
					}
					else if (Destination.Location != GetDestination())
					{
						// only try and close a door while moving if it's open to the side we're going to
						bPointAheadToLeft = SwatDoorDestination.PointIsToMyLeft(GetDestination());
						return ((DoorDestination.IsOpen() && (DoorDestination.IsOpenLeft() == bPointAheadToLeft)) ||
								(DoorDestination.IsOpening() && (DoorDestination.IsOpeningLeft() == bPointAheadToLeft)));
					}
				}
			}
		}
	}

	return false;
}

protected latent function PostCloseDoorGoal(Door Target, bool bCloseFromLeft)
{
	if (CurrentCloseDoorGoal != None)
	{
		CurrentCloseDoorGoal.unPostGoal(self);
		CurrentCloseDoorGoal.Release();
		CurrentCloseDoorGoal = None;
	}

	// priority of the open door behavior needs to be greater than this behavior's priority
	CurrentCloseDoorGoal = new class'CloseDoorGoal'(AI_Resource(m_pawn.movementAI), achievingGoal.priority+1, Target);
	assert(CurrentCloseDoorGoal != None);
	CurrentCloseDoorGoal.AddRef();

	CurrentCloseDoorGoal.SetShouldWalkEntireMove(ShouldWalk());
	CurrentCloseDoorGoal.SetCloseDoorFromBehind(true);
	CurrentCloseDoorGoal.SetCloseDoorFromLeft(bCloseFromLeft);
	CurrentCloseDoorGoal.SetRotateTowardsPointsDuringMovement(true);

	// no walk threshold for closing doors (we set should walk instead)
	CurrentCloseDoorGoal.SetWalkThreshold(0.0);

	CurrentCloseDoorGoal.postGoal(self);
	WaitForGoal(CurrentCloseDoorGoal);
	CurrentCloseDoorGoal.unPostGoal(self);

	CurrentCloseDoorGoal.Release();
	CurrentCloseDoorGoal = None;
}

protected latent function NavigateThroughDoor(Door Target)
{
	local ISwatDoor SwatDoorTarget;
	local Pawn PendingDoorInteractor;

	SwatDoorTarget = ISwatDoor(Target);
	assert(SwatDoorTarget != None);

	PendingDoorInteractor = SwatDoorTarget.GetPendingInteractor();

	if (m_Pawn.logTyrion)
		log(m_Pawn.Name $ " attempting to navigate through door " $ Target.Name $ " IsClosed() " $ Target.IsClosed() $ " IsClosing() " $ Target.IsClosing() $ " IsBroken " $ SwatDoorTarget.IsBroken() $ " PendingDoorInteractor: " $ PendingDoorInteractor);

	// wait for the door to finish closing (if it is)
	while (Target.IsClosing())
		yield();

//	log(m_Pawn.Name $ " finished waiting - PendingDoorInteractor " $ PendingDoorInteractor $ " IsClosed " $ Target.IsClosed() $ " IsBroken " $ SwatDoorTarget.IsBroken() $ " IsOpening " $ Target.IsOpening());

	if (Target.IsClosed() && !SwatDoorTarget.IsBroken() && !Target.IsOpening() &&
		((PendingDoorInteractor == None) || (PendingDoorInteractor == m_Pawn)))
	{
		PostOpenDoorGoal(Target);
	}
}