///////////////////////////////////////////////////////////////////////////////
// UseBreachingChargeAction.uc - UseBreachingChargeAction class
// this action that causes the AI to move to a door, place a breaching charge,
//  move to a safe location, and then blow the door

class UseBreachingChargeAction extends SwatCharacterAction
	implements IInterestedInDoorOpening;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private RotateTowardPointGoal				CurrentRotateTowardPointGoal;
var private RotateTowardActorGoal				CurrentRotateTowardActorGoal;
var private MoveToActorGoal						CurrentMoveToActorGoal;
var private MoveToLocationGoal					CurrentMoveToLocationGoal;

var private HandheldEquipment					BreachingCharge;
var private HandheldEquipment					Detonator;

// Copied from our goal
var(parameters) private Door					TargetDoor;
var(parameters) private NavigationPoint			SafeLocation;
var(parameters) IInterestedInDetonatorEquipping InterestedInDetonatorEquippingClient;

///////////////////////////////////////////////////////////////////////////////
// 
// Cleanup

function cleanup()
{
	super.cleanup();

	if (BreachingCharge != None)
	{
		if (BreachingCharge.IsBeingUsed())
		{
			IAmAQualifiedUseEquipment(BreachingCharge).InstantInterrupt();
		}
		else
		{
			BreachingCharge.AIInterrupt();
		}
	}

	if ((Detonator != None) && !Detonator.IsIdle())
	{
		Detonator.AIInterrupt();
	}

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();

	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
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

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	if (m_Pawn.bIsCrouched)
	{
		m_Pawn.ShouldCrouch(false);
	}

	// unregister that we're interested that the door is opening
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	// re-enable collision avoidance (if it isn't already)
	m_Pawn.EnableCollisionAvoidance();
}

///////////////////////////////////////////////////////////////////////////////
//
// Notifications

function NotifyDoorOpening(Door TargetDoor)
{
	// door is opening, can't remove the wedge (this should only happen if the door was breached)
	instantSucceed();
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

function bool IsC2ChargeDeployedOnThisSideOfDoor()
{
	local ISwatDoor SwatDoorTarget;
	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

    if (SwatDoorTarget.PointIsToMyLeft(m_Pawn.Location))
    {
        return SwatDoorTarget.IsChargePlacedOnLeft();
    }
    else
    {
        return SwatDoorTarget.IsChargePlacedOnRight();
    }
}

// TODO: Get an actual breaching point from Shawn, rather than using the door open points
function vector GetDeployPoint()
{
	local ISwatDoor SwatDoorTarget;
	local vector DeployPoint;
	local Rotator DummyRotation;

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	SwatDoorTarget.GetOpenPositions(m_Pawn, false, DeployPoint, DummyRotation);
	return DeployPoint;
}

latent function MoveToDeployPoint()
{
	// currently we just move to the open point on the door
	CurrentMoveToLocationGoal = new class'SwatAICommon.MoveToLocationGoal'(movementResource(), achievingGoal.priority, GetDeployPoint());
	assert(CurrentMoveToLocationGoal != None);
	CurrentMoveToLocationGoal.AddRef();

	CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToLocationGoal.postGoal(self);
	waitForGoal(CurrentMoveToLocationGoal);
	CurrentMoveToLocationGoal.unPostGoal(self);

	CurrentMoveToLocationGoal.Release();
	CurrentMoveToLocationGoal = None;
}

private function vector GetPlacementPoint()
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

latent function RotateToPlacementPoint()
{
	assert(TargetDoor != None);

	CurrentRotateTowardPointGoal = new class'RotateTowardPointGoal'(movementResource(), achievingGoal.priority, GetPlacementPoint());
	assert(CurrentRotateTowardPointGoal != None);
	CurrentRotateTowardPointGoal.AddRef();

	CurrentRotateTowardPointGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardPointGoal);
	CurrentRotateTowardPointGoal.unPostGoal(self);

	CurrentRotateTowardPointGoal.Release();
	CurrentRotateTowardPointGoal = None;
}

latent function RotateToDoor()
{
	assert(TargetDoor != None);

	CurrentRotateTowardActorGoal = new class'RotateTowardActorGoal'(movementResource(), achievingGoal.priority, TargetDoor);
	assert(CurrentRotateTowardActorGoal != None);
	CurrentRotateTowardActorGoal.AddRef();

	CurrentRotateTowardActorGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardActorGoal);
	CurrentRotateTowardActorGoal.unPostGoal(self);

	CurrentRotateTowardActorGoal.Release();
	CurrentRotateTowardActorGoal = None;
}

function EquipBreachingCharge()
{
	BreachingCharge = ISwatOfficer(m_Pawn).GetItemAtSlot(SLOT_Breaching);
	assert(BreachingCharge != None);
    assert(BreachingCharge.IsA('C2Charge'));

	BreachingCharge.AIInstantEquip();
}

latent function UseBreachingCharge()
{
	assert(TargetDoor != None);
	assert(BreachingCharge != None);

	// wait for the breaching charge to finish being equipped
	while(BreachingCharge.IsBeingEquipped())
	{
		yield();
	}
	
	if (! BreachingCharge.IsEquipped())
	{
		BreachingCharge.LatentWaitForIdleAndEquip();
	}

	m_Pawn.ShouldCrouch(true);
	IAmUsedOnOther(BreachingCharge).LatentUseOn(TargetDoor);
	m_Pawn.ShouldCrouch(false);
}

latent function MoveToSafeLocation()
{
	// move to the safe location
	CurrentMoveToActorGoal = new class'SwatAICommon.MoveToActorGoal'(movementResource(), achievingGoal.priority, SafeLocation);
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	
	CurrentMoveToActorGoal.postGoal(self);

	EquipDetonator();

	waitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

function EquipDetonator()
{
	local ISwatOfficer Officer;
    Officer = ISwatOfficer(m_Pawn);
    assert(Officer != None);

	Detonator = Officer.GetItemAtSlot(Slot_Detonator);
	assert(Detonator != None); 

	if (InterestedInDetonatorEquippingClient != None)
	{
		InterestedInDetonatorEquippingClient.NotifyDetonatorEquipping();
	}
	
	Detonator.AIInstantEquip();
}

// equip and use the detonator
latent function BlowDoor()
{
    local ISwatOfficer Officer;
    Officer = ISwatOfficer(m_Pawn);
    assert(Officer != None);

    Officer.SetDoorToBlowC2On(TargetDoor);
	
	assert(Detonator != None);

	// if the detonator is being equipped, wait for that to finish
	// otherwise we just equip it
	while(Detonator.IsBeingEquipped())
	{
		yield();
	}

	if (! Detonator.IsEquipped())
	{
		if (InterestedInDetonatorEquippingClient != None)
		{
			InterestedInDetonatorEquippingClient.NotifyDetonatorEquipping();
		}

		Detonator.LatentWaitForIdleAndEquip();
	}

	// we're no longer interested if the door is opening (we're about to open it)
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	Detonator.LatentUse();

    Officer.SetDoorToBlowC2On(None);
}

function TriggerReportedDeployingC2Speech()
{
	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportedDeployingC2Speech();
}

state Running
{
 Begin:
	if (TargetDoor.IsClosed() && ! TargetDoor.IsOpening() && ! TargetDoor.IsBroken())
	{
		ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

		useResources(class'AI_Resource'.const.RU_ARMS);

		if (!IsC2ChargeDeployedOnThisSideOfDoor())
		{
			TriggerReportedDeployingC2Speech();

			EquipBreachingCharge();

			MoveToDeployPoint();
	    	
			// no avoiding collision while we're breaching the door!
			m_Pawn.DisableCollisionAvoidance();

			RotateToPlacementPoint();
			useResources(class'AI_Resource'.const.RU_LEGS);

			UseBreachingCharge();

			// re-enable collision avoidance!
			m_Pawn.EnableCollisionAvoidance();

			clearDummyMovementGoal();
		}

		MoveToSafeLocation();
		RotateToDoor();

		useResources(class'AI_Resource'.const.RU_LEGS);
		WaitForZulu();
		BlowDoor();
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'UseBreachingChargeGoal'
}
