///////////////////////////////////////////////////////////////////////////////
// CheckTrapsAction.uc - CheckTrapsAction class
// The Action that causes the Officers to test and see if a door is trapped

class CheckTrapsAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum AIDoorUsageSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Door				TargetDoor;

// behaviors we use
var private MoveToLocationGoal			CurrentMoveToLocationGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private UseOptiwandGoal				CurrentUseOptiwandGoal;

// how we're mirroring
var private bool						bCrouchWhileMirroring;
var private bool						bMirrorAroundCorner;

// what we're mirroring
var private ISwatDoor					SwatTargetDoor;

// where and what direction we mirror in
var private rotator						MirroringRotation;
var private vector						MirroringFromPoint;
var private rotator						MirroringFromRotation;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentUseOptiwandGoal != None)
	{
		CurrentUseOptiwandGoal.Release();
		CurrentUseOptiwandGoal = None;
	}

	// re-enable collision avoidance (if it isn't already)
	m_Pawn.EnableCollisionAvoidance();
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  failing.");

	// just fail
	InstantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
//
//

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function SetMirroringType()
{
	if (!TargetDoor.IsEmptyDoorway() && TargetDoor.IsClosed() && !TargetDoor.IsOpening() /*&& !TargetDoor.IsBroken()*/)
	{
		bMirrorAroundCorner   = false;
		bCrouchWhileMirroring = true;
	}
	else
	{
		bCrouchWhileMirroring = false;
		bMirrorAroundCorner   = true;
	}
}
function SetMirroringOrientation()
{
	local vector CenterOpenPoint;
	local rotator CenterOpenRotation;

	// get the center mirroring point no matter what
	SwatTargetDoor.GetOpenPositions(m_Pawn, false, CenterOpenPoint, CenterOpenRotation);

	MirroringFromPoint    = CenterOpenPoint;
	MirroringFromRotation = CenterOpenRotation;
	MirroringRotation     = CenterOpenRotation;
}

latent function MoveToMirroringPosition()
{
	CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(movementResource(), achievingGoal.priority, MirroringFromPoint);
	assert(CurrentMoveToLocationGoal != None);
	CurrentMoveToLocationGoal.AddRef();

	CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToLocationGoal.postGoal(self);
	WaitForGoal(CurrentMoveToLocationGoal);
	CurrentMoveToLocationGoal.unPostGoal(self);

	CurrentMoveToLocationGoal.Release();
	CurrentMoveToLocationGoal = None;
}

latent function RotateToMirroringRotation()
{
	assert(CurrentRotateTowardRotationGoal == None);

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, MirroringFromRotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

function vector GetMirrorViewOrigin()
{
	if (SwatTargetDoor.ActorIsToMyLeft(m_Pawn))
	{
		return TargetDoor.GetBoneCoords('OptiwandRIGHT', true).Origin;
	}
	else
	{
		return TargetDoor.GetBoneCoords('OptiwandLEFT', true).Origin;
	}
}

latent function UseMirror(ISwatDoor Target)
{
	assert(CurrentUseOptiwandGoal == None);

	CurrentUseOptiwandGoal = new class'UseOptiwandGoal'(weaponResource(), vector(MirroringRotation), true, Target);
	assert(CurrentUseOptiwandGoal != None);
	CurrentUseOptiwandGoal.AddRef();

	CurrentUseOptiwandGoal.SetOverloadedViewOrigin(GetMirrorViewOrigin());

	if (bMirrorAroundCorner)
		CurrentUseOptiwandGoal.SetMirrorAroundCorner();

	CurrentUseOptiwandGoal.postGoal(self);
	WaitForGoal(CurrentUseOptiwandGoal);
	CurrentUseOptiwandGoal.unPostGoal(self);

	CurrentUseOptiwandGoal.Release();
	CurrentUseOptiwandGoal = None;
}

latent function MirrorDoor()
{
	useResources(class'AI_Resource'.const.RU_ARMS);

	SwatTargetDoor = ISwatDoor(TargetDoor);
	assert(SwatTargetDoor != None);

	SetMirroringType();
	SetMirroringOrientation();

	MoveToMirroringPosition();

	// disable collision avoidance while we are mirroring
	m_Pawn.DisableCollisionAvoidance();

	RotateToMirroringRotation();

	useResources(class'AI_Resource'.const.RU_LEGS);
	clearDummyWeaponGoal();

	UseMirror(SwatTargetDoor);

	// re-enable collision avoidance now that we're done mirroring
	m_Pawn.EnableCollisionAvoidance();
}

state Running
{
Begin:
	MirrorDoor();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'CheckTrapsGoal'
}
