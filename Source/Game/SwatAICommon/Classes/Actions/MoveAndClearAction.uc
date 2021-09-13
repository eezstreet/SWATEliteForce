///////////////////////////////////////////////////////////////////////////////
// MoveAndClearAction.uc - MoveAndClearAction class
// The Action that causes the Officers to move and clear a room

class MoveAndClearAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) ClearPoint							TargetClearPoint;
var(parameters) vector								CommandOrigin;
var(parameters) bool								bShouldAnnounceClear;

// behaviors we use
var private MoveToActorGoal							CurrentMoveToActorGoal;
var private RotateTowardActorGoal					CurrentRotateTowardActorGoal;
var private RotateTowardRotationGoal				CurrentRotateTowardRotationGoal;
var private AimAroundGoal							CurrentAimAroundGoal;

// internal move
var private array<NavigationPoint>					ClearRoute;
var private int										CurrentClearRouteIndex;
var private bool									bPauseMovement;

// internal hold
var private float									EndHoldClearPositionTime;

// config variables
var config float									DistanceToStopMovingWithUncompliantCharacter;

var config float									MoveAndClearMinAimHoldTime;
var config float									MoveAndClearMaxAimHoldTime;

var config float									MoveAndClearAimAroundInnerRadius;
var config float									MoveAndClearAimAroundOuterRadius;
var config float									MoveAndClearAimAroundPointTooCloseDistance;

var config float									MinHoldClearPositionTime;
var config float									MaxHoldClearPositionTime;

// our sensor
var private DistanceToUncomplaintCharactersSensor	DistanceToUncomplaintCharactersSensor; 

// constants
const kClearedRoomUpdateTime = 0.1;
const kDummyBehaviorPriority = 84;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}

	if (DistanceToUncomplaintCharactersSensor != None)
	{
		DistanceToUncomplaintCharactersSensor.deactivateSensor(self);
		DistanceToUncomplaintCharactersSensor = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion Events

function resourceStolenCB( AI_goal goal, AI_Resource stolenResource )
{
	// if we have a current assignment, and this is one of the dummy behaviors, ignore the fact that it was interrupted
	if (!HasCurrentAssignment() || (!goal.IsA('AI_DummyWeaponGoal') && !goal.IsA('AI_DummyMovementGoal')))
	{
		super.resourceStolenCB(goal, stolenResource);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor

private function SetupDistanceToUncomplaintCharactersSensor()
{
	DistanceToUncomplaintCharactersSensor = DistanceToUncomplaintCharactersSensor(class'AI_Sensor'.static.activateSensor(self, class'DistanceToUncomplaintCharactersSensor', characterResource(), 0, 1000000));
	assert(DistanceToUncomplaintCharactersSensor != None);
	DistanceToUncomplaintCharactersSensor.SetParameters(DistanceToStopMovingWithUncompliantCharacter);
}

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if (m_Pawn.logTyrion)
		log("MoveAndClearAction received sensor message from " $ sensor.name $ " value is "$ value.integerData);

	// we only (currently) get messages from a distance sensor
	assert(sensor == DistanceToUncomplaintCharactersSensor);

	if (value.objectData != None)
	{
//		log(m_Pawn.Name $ " is too close while moving and clearing.  stopping movement!");
		assert(value.objectData.IsA('Pawn'));

		PauseMovement(Pawn(value.objectData));
	}
	else if (value.objectData == None)
	{
//		log(m_Pawn.Name $ " has room to move and clear.  continuing movement!");

		// if we're paused, continue
		if (bPauseMovement)
		{
			UnPauseMovement();
		}
	}
}

private function PauseMovement(Pawn PausingCharacter)
{
	bPauseMovement = true;

	if ((CurrentMoveToActorGoal != None) && (CurrentMoveToActorGoal.achievingAction != None))
	{
		CurrentMoveToActorGoal.achievingAction.instantSucceed();
	}

	RotateToFacePausingCharacter(PausingCharacter);
}

private function UnPauseMovement()
{
	bPauseMovement = false;

	RemoveRotateToFacePausingCharacterGoal();

	if (isIdle())
		runAction();
}

private function RemoveRotateToFacePausingCharacterGoal()
{
	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.unPostGoal(self);
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}
}

function RotateToFacePausingCharacter(Pawn PausingCharacter)
{
	RemoveRotateToFacePausingCharacterGoal();	

	log("RotateToFacePausingCharacter() posted a RotateTowardActorGoal at "$PausingCharacter);
	CurrentRotateTowardActorGoal = new class'RotateTowardActorGoal'(movementResource(), achievingGoal.priority, PausingCharacter);
	assert(CurrentRotateTowardActorGoal != None);
	CurrentRotateTowardActorGoal.AddRef();

	CurrentRotateTowardActorGoal.postGoal(self);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function AimAround()
{
	CurrentAimAroundGoal = new class'AimAroundGoal'(weaponResource(), MoveAndClearMinAimHoldTime, MoveAndClearMaxAimHoldTime);
	assert(CurrentAimAroundGoal != None);
	CurrentAimAroundGoal.AddRef();

    CurrentAimAroundGoal.SetAimInnerFovDegrees(MoveAndClearAimAroundInnerRadius);
    CurrentAimAroundGoal.SetAimOuterFovDegrees(MoveAndClearAimAroundOuterRadius);
	CurrentAimAroundGoal.SetPointTooCloseRadius(MoveAndClearAimAroundPointTooCloseDistance);
	CurrentAimAroundGoal.SetOnlyAimIfMoving(true);

	CurrentAimAroundGoal.postGoal( self );
}

latent function RotateToClearPointRotation()
{
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.Priority, TargetClearPoint.Rotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

function BuildClearRoute()
{
	local int i;

	// add the clear route points to the clear route
	for(i=0; i<TargetClearPoint.ClearRoutePoints.Length; ++i)
	{
		ClearRoute[ClearRoute.Length] = TargetClearPoint.ClearRoutePoints[i];
	}

	// add the clear point to the clear route
	ClearRoute[ClearRoute.Length] = TargetClearPoint;

	assert(ClearRoute.Length > 0);
}

latent function MoveToClearRoutePoint(NavigationPoint ClearRoutePoint)
{
	assert(ClearRoutePoint != None);

	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, ClearRoutePoint);
    assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetShouldWalkEntireMove(false);
	CurrentMoveToActorGoal.SetWalkThreshold(0.0);
	
    // Let the aim around action perform the aiming and rotation for us
	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);

	// RoomName limiter is commented out for now until I have some error checking in place for clear points 
	// that would cause you to cross rooms
//	CurrentMoveToActorGoal.SetRoomNameLimiter(TargetClearPoint.GetRoomName(m_Pawn));

//	log(m_Pawn.Name $ " moving to NextClearRoutePoint " $ NextClearRoutePoint.Name);

    // post the move to goal and wait for it to complete
    CurrentMoveToActorGoal.postGoal(self);
    
    while (!CurrentMoveToActorGoal.hasCompleted())
    {
        if ((CurrentAimAroundGoal == None) && !HasCurrentAssignment() && m_Pawn.IsInRoom(TargetClearPoint.GetRoomName(m_Pawn)))
        {
            clearDummyWeaponGoal();
            AimAround();
        }
           
        yield();
    }

    CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

latent function MoveToNextClearRoutePoint()
{
	local NavigationPoint NextClearRoutePoint;

	NextClearRoutePoint = ClearRoute[CurrentClearRouteIndex];
	assert(NextClearRoutePoint != None);

	MoveToClearRoutePoint(NextClearRoutePoint);
}

latent function MoveToClearRoutePoints()
{
	// build the route we will take when we move
	BuildClearRoute();

	// setup the sensor to uncompliant characters
	SetupDistanceToUncomplaintCharactersSensor();

	CurrentClearRouteIndex = 0;

	while (CurrentClearRouteIndex < ClearRoute.Length)
	{
		// in case we're set to pause movement before the movement behavior starts
		if (! bPauseMovement)
			MoveToNextClearRoutePoint();

		if (bPauseMovement)
		{
			pause();
		}
		else
		{
			++CurrentClearRouteIndex;
		}
	}
}

private function bool IsClearPointOnSameSideAsCommandOrigin()
{
	local ISwatDoor Door;

	Door = ISwatDoor(TargetClearPoint.ParentDoor);
	assert(Door != None);

	if (Door.PointIsToMyLeft(CommandOrigin))
	{
		return (Door.GetLeftRoomName() == TargetClearPoint.GetRoomName(m_Pawn));
	}
	else
	{
		return (Door.GetRightRoomName() == TargetClearPoint.GetRoomName(m_Pawn));
	}
}

private function bool HasCurrentAssignment()
{
	local Pawn CurrentAssignment;

	CurrentAssignment = ISwatOfficer(m_Pawn).GetOfficerCommanderAction().GetCurrentAssignment();
	return (class'Pawn'.static.checkConscious(CurrentAssignment) &&
			(CurrentAssignment.IsA('SwatPlayer') ||
			 (!ISwatAI(CurrentAssignment).IsCompliant() &&
			  !ISwatAI(CurrentAssignment).IsArrested())));
}

// we only announce clear if we're told we should, and we don't have a current assignment
// or the current assignment is dead, compliant, or restrained
private function bool ShouldAnnounceClear()
{
	return (bShouldAnnounceClear && !HasCurrentAssignment());
}

function bool IsRotatedToClearPointRotation()
{
//	log("StackUpPoint.Rotation " $ StackUpPoint.Rotation $ " GetAimOrientation: " $ ISwatAI(m_Pawn).GetAimOrientation() $ " == " $ (WrapAngle0To2Pi(StackUpPoint.Rotation.Yaw) == WrapAngle0To2Pi(int(ISwatAI(m_Pawn).GetAnimBaseYaw())));

	return (WrapAngle0To2Pi(ISwatAI(m_Pawn).GetAimOrientation().Yaw) == WrapAngle0To2Pi(int(ISwatAI(m_Pawn).GetAnimBaseYaw())));
}

state Running
{
Begin:
	// If we should sweep the room, aim around in a limited fashion.  This shouldn't slow the AIs down too much.
	// If it does we can easily disable it again.

	if (! HasCurrentAssignment() && weaponResource().requiredResourcesAvailable(0, kDummyBehaviorPriority))
		useResources(class'AI_Resource'.const.RU_ARMS, kDummyBehaviorPriority);

//	log(m_Pawn.Name $ " starting move and clear action");

	MoveToClearRoutePoints();

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.unPostGoal(self);
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;

		if (! HasCurrentAssignment() && weaponResource().requiredResourcesAvailable(0, kDummyBehaviorPriority))
			useResources(class'AI_Resource'.const.RU_ARMS, kDummyBehaviorPriority);
	}

	// only rotate, announce clear, and/or hold position if we don't have a current assignment
	if (! HasCurrentAssignment())
	{
		RotateToClearPointRotation();

		if (! HasCurrentAssignment())
		{
			// play a sound if we're supposed to
			if (ShouldAnnounceClear())
			{
				ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerClearAnnouncement();
			}

			// delay a bit before we finish (and the idle aim around behavior kicks in)
			useResources(class'AI_Resource'.const.RU_LEGS, kDummyBehaviorPriority);

			EndHoldClearPositionTime = Level.TimeSeconds + RandRange(MinHoldClearPositionTime, MaxHoldClearPositionTime);

			while (class'Pawn'.static.checkConscious(m_Pawn) && (Level.TimeSeconds < EndHoldClearPositionTime) && !HasCurrentAssignment())
			{
				// if we've moved out of position, move back
				if (! m_Pawn.ReachedDestination(TargetClearPoint) && ! m_Pawn.IsAvoidingCollision())
				{
					clearDummyMovementGoal();
					MoveToClearRoutePoint(TargetClearPoint);
					useResources(class'AI_Resource'.const.RU_LEGS, kDummyBehaviorPriority);
				}
				
				if (! IsRotatedToClearPointRotation())
				{
					clearDummyMovementGoal();
					RotateToClearPointRotation();
					useResources(class'AI_Resource'.const.RU_LEGS, kDummyBehaviorPriority);
				}

				sleep(kClearedRoomUpdateTime);
			}
		}
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'MoveAndClearGoal'
}
