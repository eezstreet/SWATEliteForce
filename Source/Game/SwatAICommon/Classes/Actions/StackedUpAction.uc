///////////////////////////////////////////////////////////////////////////////
// StackedUpAction.uc - StackedUpAction class
// Controls behavior for when an Officer is stacked up

class StackedUpAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum AIDoorUsageSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private MoveToActorGoal				CurrentMoveToActorGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

// constants
const kStackedUpUpdateTime = 0.333;

///////////////////////////////////////////////////////////////////////////////
//
// cleanup

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

	ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_StackedUp);
}

///////////////////////////////////////////////////////////////////////////////
//
//

function StackUpPoint GetStackUpPoint()
{
	return StackedUpGoal(achievingGoal).GetStackUpPoint();
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function StackUp()
{
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, GetStackUpPoint());
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(false);
	CurrentMoveToActorGoal.SetShouldWalkEntireMove(false);

	CurrentMoveToActorGoal.postGoal(self);
	
    while (!CurrentMoveToActorGoal.hasCompleted() && !m_Pawn.IsAvoidingCollision() && !IsStackUpPointBlocked())
    {
        yield();
    }

	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;

	if (! IsRotatedToStackUpPointRotation())
	{
		RotateToStackUpPointRotation();
	}
}

latent function RotateToStackUpPointRotation()
{
	local StackUpPoint StackUpPoint;

	StackUpPoint = GetStackUpPoint();
	assert(StackUpPoint != None);

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.Priority, StackUpPoint.Rotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

function bool IsRotatedToStackUpPointRotation()
{
	local StackUpPoint StackUpPoint;

	StackUpPoint = GetStackUpPoint();
	assert(StackUpPoint != None);

//	log("StackUpPoint.Rotation " $ StackUpPoint.Rotation $ " GetAimOrientation: " $ ISwatAI(m_Pawn).GetAimOrientation() $ " == " $ (WrapAngle0To2Pi(StackUpPoint.Rotation.Yaw) == WrapAngle0To2Pi(ISwatAI(m_Pawn).GetAimOrientation().Yaw)));

	return (WrapAngle0To2Pi(ISwatAI(m_Pawn).GetAimOrientation().Yaw) == WrapAngle0To2Pi(int(ISwatAI(m_Pawn).GetAnimBaseYaw())));
}

private function bool IsBlockedByAnotherOfficerAtCenterPoint()
{
	local vector CenterPoint, OfficerIterCenterPoint;
	local AIDoorUsageSide DummyUsageSide;
	local int i;
	local ElementSquadInfo Element;
	local Pawn OfficerIter;
	local Door TargetDoor;

	TargetDoor  = GetStackUpPoint().ParentDoor;
	CenterPoint = ISwatDoor(TargetDoor).GetCenterOpenPoint(m_Pawn, DummyUsageSide);

	// if we want to be close enough to the center point on the door
	if (VSize2D(CenterPoint - GetStackUpPoint().Location) < ((m_Pawn.CollisionRadius + m_Pawn.CollisionSoftRadiusOffset) * 2.0))
	{
		Element = SwatAIRepository(Level.AIRepo).GetElementSquad();

		// go through each officer
		for(i=0; i<Element.pawns.length; ++i)
		{
			OfficerIter = Element.pawns[i];

			if ((OfficerIter != m_Pawn) && 
				class'Pawn'.static.checkConscious(OfficerIter))
			{
				OfficerIterCenterPoint = ISwatDoor(TargetDoor).GetCenterOpenPoint(OfficerIter, DummyUsageSide);

				// if the center point for this officer is the same as the center point for us, and he's at the center open point, it is currently blocked
				if ((OfficerIterCenterPoint == CenterPoint) && OfficerIter.ReachedLocation(CenterPoint))
					return true;
			}
		}
	}

	return false;
}

private function bool IsStackUpPointBlocked()
{
	local int i;
	local ElementSquadInfo Element;
	local Pawn OfficerIter, Player;
	local StackUpPoint StackUpPoint;

	StackUpPoint = GetStackUpPoint();
	assert(StackUpPoint != None);

	// go through each officer
	Element = SwatAIRepository(Level.AIRepo).GetElementSquad();
	for(i=0; i<Element.pawns.length; ++i)
	{
		OfficerIter = Element.pawns[i];

		if ((OfficerIter != m_Pawn) && 
			class'Pawn'.static.checkConscious(OfficerIter))
		{
			if (OfficerIter.ReachedDestination(StackUpPoint))
				return true;
		}
	}

	// check the player
	Player = Level.GetLocalPlayerController().Pawn;
	if (class'Pawn'.static.checkConscious(Player))
	{
		if (Player.ReachedDestination(StackUpPoint))
			return true;
	}

	return false;
}

latent function WaitLoop()
{
	local bool ReachedStackUpPoint;

	while (class'Pawn'.static.checkConscious(m_Pawn))
	{
		ReachedStackUpPoint = m_Pawn.ReachedDestination(GetStackUpPoint());

		if (! IsStackUpPointBlocked() && ! m_Pawn.IsAvoidingCollision())
		{
			// if we've moved out of position, move back
			if (!ReachedStackUpPoint && !IsBlockedByAnotherOfficerAtCenterPoint())
			{
				ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_LowReady, kUBABCI_StackedUp);

				clearDummyMovementGoal();
				StackUp();
				useResources(class'AI_Resource'.const.RU_LEGS);

				ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_StackedUp);
			}
			else if (ReachedStackUpPoint && ! IsRotatedToStackUpPointRotation())
			{
				ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_LowReady, kUBABCI_StackedUp);

				clearDummyMovementGoal();
				RotateToStackUpPointRotation();
				useResources(class'AI_Resource'.const.RU_LEGS);

				ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_StackedUp);
			}
		}

		sleep(kStackedUpUpdateTime);
	}
}

state Running
{
 Begin:
	// wait until we can use the resources
	while (!resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
		yield();

	useResources(class'AI_Resource'.const.RU_LEGS | class'AI_Resource'.const.RU_ARMS);

	WaitLoop();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'StackedUpGoal'
}