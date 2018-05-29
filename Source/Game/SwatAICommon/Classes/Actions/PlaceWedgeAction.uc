///////////////////////////////////////////////////////////////////////////////
// PlaceWedgeAction.uc - PlaceWedgeAction class
// The Action that causes the Officers to place a wedge on a door

class PlaceWedgeAction extends SwatCharacterAction
	implements IInterestedInDoorOpening;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// our wedge
var private HandheldEquipment		Wedge;

// copied from our goal
var(parameters) Door				TargetDoor;

// behaviors we use
var private MoveToDoorGoal			CurrentMoveToDoorGoal;
var private RotateTowardPointGoal	CurrentRotateTowardPointGoal;

// other
var private bool					bPlacingWedge;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (Wedge != None)
	{
		if (Wedge.IsBeingUsed())
		{
			IAmAQualifiedUseEquipment(Wedge).InstantInterrupt();
		}
		else
		{
			Wedge.AIInterrupt();
		}
	}

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();

	if (CurrentMoveToDoorGoal != None)
	{
		CurrentMoveToDoorGoal.Release();
		CurrentMoveToDoorGoal = None;
	}

	if (CurrentRotateTowardPointGoal != None)
	{
		CurrentRotateTowardPointGoal.Release();
		CurrentRotateTowardPointGoal = None;
	}

	if (m_Pawn.bIsCrouched)
	{
		m_Pawn.ShouldCrouch(false);
	}

	// tell the pawn to care about being hit by doors again
	ISwatOfficer(m_Pawn).SetIgnoreDoorBlocking(false);

	// unregister that we're interested that the door is opening
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	// make sure we re-enable collision avoidance
	m_Pawn.EnableCollisionAvoidance();
}

///////////////////////////////////////////////////////////////////////////////
//
// Notifications

function NotifyDoorOpening(Door TargetDoor)
{
	// if we are kneeling down to place a wedge, we don't care
	if(bPlacingWedge)
	{
		return;
	}

	// door is opening, can't wedge it
	instantSucceed();
}

///////////////////////////////////////////////////////////////////////////////
//
// Update!

function UpdateOfficersKnowledge()
{
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);
	assert(SwatAIRepo != None);

	SwatAIRepo.NotifyOfficersDoorWedged(TargetDoor);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function vector GetPlaceWedgePoint()
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

latent function RotateToPlaceWedgePoint()
{
	CurrentRotateTowardPointGoal = new class'RotateTowardPointGoal'(movementResource(), achievingGoal.priority, GetPlaceWedgePoint());
	assert(CurrentRotateTowardPointGoal != None);
	CurrentRotateTowardPointGoal.AddRef();

	CurrentRotateTowardPointGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardPointGoal);
	CurrentRotateTowardPointGoal.unPostGoal(self);

	CurrentRotateTowardPointGoal.Release();
	CurrentRotateTowardPointGoal = None;
}

latent function MoveToPlaceWedge()
{
	CurrentMoveToDoorGoal = new class'MoveToDoorGoal'(AI_Resource(m_Pawn.movementAI), TargetDoor);
	assert(CurrentMoveToDoorGoal != None);
	CurrentMoveToDoorGoal.AddRef();

	CurrentMoveToDoorGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToDoorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToDoorGoal);
	CurrentMoveToDoorGoal.unPostGoal(self);

	CurrentMoveToDoorGoal.Release();
	CurrentMoveToDoorGoal = None;
}

latent function PlaceWedge()
{
	bPlacingWedge = true;

	assert(TargetDoor != None);

	Wedge = ISwatOfficer(m_Pawn).GetItemAtSlot(SLOT_Wedge);
	assert(Wedge != None);

	Wedge.LatentWaitForIdleAndEquip();

	m_Pawn.ShouldCrouch(true);
	IAmUsedOnOther(Wedge).LatentUseOn(TargetDoor);
	m_Pawn.ShouldCrouch(false);

	ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

	bPlacingWedge = false;
}

state Running
{
Begin:
	if (TargetDoor.IsClosed() && ! TargetDoor.IsOpening())
	{
		ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

		useResources(class'AI_Resource'.const.RU_ARMS);

		MoveToPlaceWedge();

		m_Pawn.DisableCollisionAvoidance();

		RotateToPlaceWedgePoint();

		useResources(class'AI_Resource'.const.RU_LEGS);

		// ignore being hit by doors
		ISwatOfficer(m_Pawn).SetIgnoreDoorBlocking(true);
		log("#0 Pawn ("$m_Pawn$") door blocking is now: "$ISwatOfficer(m_Pawn).GetIgnoreDoorBlocking());

		PlaceWedge();

		// care about being hit by doors again
		ISwatOfficer(m_Pawn).SetIgnoreDoorBlocking(false);
		log("0# Pawn's door blocking is now: "$ISwatOfficer(m_Pawn).GetIgnoreDoorBlocking());

		m_Pawn.EnableCollisionAvoidance();

		// play a sound
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerWedgePlacedSpeech();
	}

	UpdateOfficersKnowledge();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'PlaceWedgeGoal'
}
