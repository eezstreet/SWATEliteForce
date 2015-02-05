///////////////////////////////////////////////////////////////////////////////
// MoveToDoorAction.uc - MoveToDoorAction class
// The action that causes the AI to move into position to be able to open a door

class MoveToDoorAction extends MoveToLocationAction
	dependson(ISwatAI)
	config(AI);
///////////////////////////////////////////////////////////////////////////////

import enum AIDoorUsageSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// internal
var private vector				Destination;
var private vector				OpenPoint;

// copied from our goal
var(parameters) Door			TargetDoor;
var(parameters) bool			bPreferSides;

// config
var config float				MoveToDoorThreshold;


///////////////////////////////////////////////////////////////////////////////
//
// Distance Sensor

protected function SetDistanceSensorParameters()
{
	DistanceSensor.setParameters( WalkThreshold, TargetDoor, ShouldUseNavigationDistanceOnSensor() );
}

///////////////////////////////////////////////////////////////////////////////
//
// Door Usage Side

protected function SetUsageSide(AIDoorUsageSide inDoorUsageSide)
{
	MoveToDoorGoal(achievingGoal).DoorUsageSide = inDoorUsageSide;
}

protected function AIDoorUsageSide GetDoorUsageSide()
{
	return MoveToDoorGoal(achievingGoal).DoorUsageSide;
}

protected function SetDoorUsageRotation(Rotator inDoorUsageRotation)
{
	MoveToDoorGoal(achievingGoal).DoorUsageRotation = inDoorUsageRotation;
}

protected function Rotator GetDoorUsageRotation()
{
	return MoveToDoorGoal(achievingGoal).DoorUsageRotation;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// called during a MoveToward call, in case we want to interrupt it for some reason
// overridden because the delegate set in the MoveToGoalBase, but we don't derive from that.
event bool ShouldStopMoving()
{
	return false;
}

function vector GetDestination()
{
	return Destination;
}

protected function bool IsInPosition()
{
	return m_Pawn.ReachedLocation(Destination);
}

latent function MoveToDoor(Door Target, vector inDestination)
{
	OverriddenMoveToThreshold = MoveToDoorThreshold;

	SetOverriddenMoveToThreshold();

	Destination = inDestination;

	MoveToLocation();

	ResetOverriddenMoveToThreshold();

	// disable collision avoidance - it is behavior specific (ie. TryDoorAction, RemoveWedgeAction, etc.) to undo this
	m_Pawn.DisableCollisionAvoidance();

	// face the door
	RotateTowardRotation(GetDoorUsageRotation());
}

latent function MoveToOpenDoor(Door Target)
{
	local ISwatDoor SwatDoorTarget;
	local rotator DoorUsageRotation;

	SwatDoorTarget = ISwatDoor(Target);
	assert(SwatDoorTarget != None);

	SetUsageSide(SwatDoorTarget.GetOpenPositions(m_Pawn, bPreferSides, OpenPoint, DoorUsageRotation));

	SetDoorUsageRotation(DoorUsageRotation);

	if (m_Pawn.logTyrion)
		log(m_Pawn@" moving to OpenPoint:"@OpenPoint@" Target.Location is:"@Target.Location);

	MoveToDoor(Target, OpenPoint);

	if (m_Pawn.logTyrion)
		log(m_Pawn@" finished moving to OpenPoint:"@OpenPoint);
}

latent function MoveToCloseDoor(Door Target, bool bCloseFromLeftSide, bool bCloseFromBehind)
{
	local vector ClosePoint;
	local ISwatDoor SwatDoorTarget;

	SwatDoorTarget = ISwatDoor(Target);
	assert(SwatDoorTarget != None);

	ClosePoint = SwatDoorTarget.GetClosePoint(bCloseFromLeftSide);
//	log("Target.Location is: " $ Target.Location $ " ClosePoint is: " $ ClosePoint $ " Distance is: " $ VSize(Target.Location - ClosePoint));

	if (bCloseFromBehind)
	{
		// the rotation we use to close the door faces directly towards the door
		SetDoorUsageRotation(rotator(ClosePoint - Target.Location));
	}
	else
	{
		// the rotation we use to close the door faces directly towards the door
		SetDoorUsageRotation(rotator(Target.Location - ClosePoint));
	}

	MoveToDoor(Target, ClosePoint);
}

protected latent function RotateAndLockToDoorUsageRotation()
{
	ISwatAI(m_Pawn).AimToRotation(GetDoorUsageRotation());
	ISwatAI(m_Pawn).LockAim();
	FinishRotation();

	ISwatAI(m_Pawn).AnimSnapBaseToAim();
}

protected latent function ReportMoveToOutcome(bool succeeded)
{
	// do nothing if we are successful
    if (succeeded == false)
	{
		if (m_Pawn.logTyrion)
			log("[AI WARNING] - " $ m_Pawn.Name $ " cannot pathfind to our current destination!");

        Fail(ACT_CANT_FIND_PATH);
    }
}

state Running
{
 Begin:
	MoveToOpenDoor(TargetDoor);	
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'MoveToDoorGoal'
}