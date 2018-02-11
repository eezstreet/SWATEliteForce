///////////////////////////////////////////////////////////////////////////////

class ShareEquipmentAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////

// copied from our goal
var(parameters) Pawn Destination;
var(parameters) EquipmentSlot Slot;

var config float	DistanceFromPlayer;
var config float	DistanceToWalk;

///////////////////////////////////////////////////////////////////////////////
//
// State code

latent function MoveToDestination()
{
	local MoveToActorGoal MoveGoal;

	MoveGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, Destination);
	MoveGoal.AddRef();
	MoveGoal.SetRotateTowardsPointsDuringMovement(true);
	MoveGoal.SetMoveToThreshold(Destination.CollisionRadius + DistanceFromPlayer);
	MoveGoal.SetShouldWalk(true);
	MoveGoal.SetWalkThreshold(DistanceToWalk);
	MoveGoal.SetWalkThresholdTarget(Destination);

	// post the goal and wait for it to complete
	MoveGoal.postGoal(self);
	WaitForGoal(MoveGoal);
	MoveGoal.unPostGoal(self);

	MoveGoal.Release();
	MoveGoal = None;
}

latent function RotateTowardsTarget()
{
	local rotator RotationToTarget;
	local RotateTowardRotationGoal RotateGoal;

	RotationToTarget = rotator(Destination.Location - m_Pawn.Location);

	RotateGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, RotationToTarget);
	assert(RotateGoal != None);
	RotateGoal.AddRef();

	RotateGoal.postGoal(self);
	WaitForGoal(RotateGoal);
	RotateGoal.unPostGoal(self);

	RotateGoal.Release();
	RotateGoal = None;

	// make sure we're using the correct rotation
	ISwatAI(m_Pawn).AimToRotation(RotationToTarget);
	ISwatAI(m_Pawn).LockAim();
}

latent function GiveEquipment()
{
	local HandheldEquipment EquipmentPiece;

	EquipmentPiece = ISwatOfficer(m_Pawn).GetItemAtSlot(Slot);
	if ( EquipmentPiece == None) {
		return;
	}

	EquipmentPiece.LatentGive(Destination);
}

state Running
{
Begin:
	MoveToDestination(); // move to the target...
	RotateTowardsTarget(); // rotate towards the target...
	GiveEquipment(); // ... and then give them our equipment!
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'ShareEquipmentGoal'
}

///////////////////////////////////////////////////////////////////////////////
