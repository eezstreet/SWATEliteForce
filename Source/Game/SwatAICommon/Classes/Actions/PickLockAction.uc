///////////////////////////////////////////////////////////////////////////////
// PickLockAction.uc - PickLockAction class
// this action that causes the AI to pick a lock on a door

class PickLockAction extends SwatCharacterAction
	implements IInterestedInDoorOpening;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) Door					TargetDoor;
var(parameters) NavigationPoint			PostPickLockDestination;

// behaviors we use
var private RotateTowardPointGoal		CurrentRotateTowardPointGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private MoveToActorGoal				CurrentMoveToActorGoal;
var private MoveToLocationGoal			CurrentMoveToLocationGoal;

// equipment we use
var private HandheldEquipment			Toolkit;

// internal
var private bool						bDoorHasOpened;
var private bool						bMovedToPickLock;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	// interrupt the toolkit
    if ((Toolkit != None) && !Toolkit.IsIdle())
    {
		if (Toolkit.IsBeingUsed())
		{
			IAmAQualifiedUseEquipment(Toolkit).InstantInterrupt();
		}
		else
		{
			Toolkit.AIInterrupt();
		}
    }

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	if (CurrentRotateTowardPointGoal != None)
	{
		CurrentRotateTowardPointGoal.Release();
		CurrentRotateTowardPointGoal = None;
	}

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

	// make sure the aim gets unset
	UnsetPickLockAim();

	// unregister that we're interested that the door is opening
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	// re-enable collision avoidance (if it isn't already)
	m_Pawn.EnableCollisionAvoidance();

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();
}

///////////////////////////////////////////////////////////////////////////////
//
// Notifications

function NotifyDoorOpening(Door TargetDoor)
{
	if (! bMovedToPickLock)
	{
		// door is opening, can't pick a lock on an open door
		instantSucceed();
	}
	else
	{
		bDoorHasOpened = true;

		if ((Toolkit != None) && Toolkit.IsBeingUsed())
		{
			IAmAQualifiedUseEquipment(Toolkit).InstantInterrupt();
		}
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// Aiming

private function SetPickLockAim()
{
	ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_UsingToolkit);
	ISwatAI(m_Pawn).AimAtPoint(GetLockPickPoint());
}

private function UnsetPickLockAim()
{
	// we're no longer aiming at someone
    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_UsingToolkit);
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

// gets the center open point on the door to use as the lock pick point
function vector GetPickLockPoint()
{
	local ISwatDoor SwatDoorTarget;
	local vector LockPickPoint;
	local Rotator DummyRotation;

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	SwatDoorTarget.GetOpenPositions(m_Pawn, false, LockPickPoint, DummyRotation);
	return LockPickPoint;
}

latent function MoveToPickLockPoint()
{
	// currently we just move to the open point on the door
	CurrentMoveToLocationGoal = new class'SwatAICommon.MoveToLocationGoal'(movementResource(), achievingGoal.priority, GetPickLockPoint());
	assert(CurrentMoveToLocationGoal != None);
	CurrentMoveToLocationGoal.AddRef();

	CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToLocationGoal.postGoal(self);
	waitForGoal(CurrentMoveToLocationGoal);
	CurrentMoveToLocationGoal.unPostGoal(self);

	CurrentMoveToLocationGoal.Release();
	CurrentMoveToLocationGoal = None;
}

private function vector GetLockPickPoint()
{
	local vector PlacementPoint;

	if (ISwatDoor(TargetDoor).ActorIsToMyLeft(TargetDoor))
	{
		PlacementPoint = TargetDoor.GetBoneCoords('C2ChargeLeft', true).Origin;
	}
	else
	{
		PlacementPoint = TargetDoor.GetBoneCoords('C2ChargeRight', true).Origin;
	}

	return PlacementPoint;
}

latent function RotateToLockPickPoint()
{
	CurrentRotateTowardPointGoal = new class'RotateTowardPointGoal'(movementResource(), achievingGoal.priority, GetLockPickPoint());
	assert(CurrentRotateTowardPointGoal != None);
	CurrentRotateTowardPointGoal.AddRef();

	CurrentRotateTowardPointGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardPointGoal);
	CurrentRotateTowardPointGoal.unPostGoal(self);

	CurrentRotateTowardPointGoal.Release();
	CurrentRotateTowardPointGoal = None;
}



latent function EquipToolkit()
{
	Toolkit = ISwatOfficer(m_Pawn).GetItemAtSlot(SLOT_Toolkit);
	assert(Toolkit != None);

	Toolkit.LatentWaitForIdleAndEquip();
}

// equip and use the toolkit, then re-equip our old weapon
latent function PickLock()
{
	// equip the tool kit
	EquipToolkit();

	if (! bDoorHasOpened)
	{
		// set our aim
		SetPickLockAim();

		// use it on the door
		IAmUsedOnOther(Toolkit).LatentUseOn(TargetDoor);

		// unset our aim
		UnsetPickLockAim();
	}

	// all done.
	ISwatOfficer(m_Pawn).ReEquipFiredWeapon();
}

latent function MoveToPostPickLockLocation()
{
	if (PostPickLockDestination != None)
	{
		// move to the post pick lock location
		CurrentMoveToActorGoal = new class'SwatAICommon.MoveToActorGoal'(movementResource(), achievingGoal.priority, PostPickLockDestination);
		assert(CurrentMoveToActorGoal != None);
		CurrentMoveToActorGoal.AddRef();

		CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);

		CurrentMoveToActorGoal.postGoal(self);
		waitForGoal(CurrentMoveToActorGoal);
		CurrentMoveToActorGoal.unPostGoal(self);

		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}
}

latent function RotateToPostPickLockRotation()
{
	if (PostPickLockDestination != None)
	{
		CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, PostPickLockDestination.Rotation);
		assert(CurrentRotateTowardRotationGoal != None);
		CurrentRotateTowardRotationGoal.AddRef();

		CurrentRotateTowardRotationGoal.postGoal(self);
		WaitForGoal(CurrentRotateTowardRotationGoal);
		CurrentRotateTowardRotationGoal.unPostGoal(self);

		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}
}

state Running
{
 Begin:
	if (TargetDoor.IsClosed() && ! TargetDoor.IsOpening() && ! TargetDoor.IsBroken())
	{
		ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

		useResources(class'AI_Resource'.const.RU_ARMS);

		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerDeployingToolkitSpeech();

		bMovedToPickLock = true;
		MoveToPickLockPoint();

		if (! bDoorHasOpened)
		{
			// no avoiding collision while we're picking the lock!
			m_Pawn.DisableCollisionAvoidance();

			RotateToLockPickPoint();

			if (! bDoorHasOpened)
			{
				useResources(class'AI_Resource'.const.RU_LEGS);
				PickLock();
				clearDummyMovementGoal();

				ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerFinishedLockPickSpeech();
			}

			// re-enable collision avoidance!
			m_Pawn.EnableCollisionAvoidance();
		}

		MoveToPostPickLockLocation();
		RotateToPostPickLockRotation();
		
		pause(); 	// So officers wont get in idle after picking
		
	}
	
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'PickLockGoal'
}
