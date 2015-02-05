///////////////////////////////////////////////////////////////////////////////
// RemoveWedgeAction.uc - RemoveWedgeAction class
// The Action that causes the Officers to remove a wedge on a door

class RemoveWedgeAction extends SwatCharacterAction
	implements IInterestedInDoorOpening;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// our toolkit, used for removing the wedge
var private HandheldEquipment		Toolkit;

// the wedge
var private Actor					Wedge;

// copied from our goal
var(parameters) Door				TargetDoor;

// behaviors we use
var private MoveToDoorGoal			CurrentMoveToDoorGoal;
var private RotateTowardPointGoal	CurrentRotateTowardPointGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	// interrupt the toolkit
    if (Toolkit != None)
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

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();

	if (m_Pawn.bIsCrouched)
	{
		m_Pawn.ShouldCrouch(false);
	}

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

	// unregister that we're interested that the door is opening
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	// make sure aim gets unset
	UnsetRemoveWedgeAim();

	// make sure we re-enable collision avoidance
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
// Aiming

private function SetRemoveWedgeAim()
{
	ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_UsingToolkit);
	ISwatAI(m_Pawn).AimAtActor(Wedge);
}

private function UnsetRemoveWedgeAim()
{
	// we're no longer aiming at someone
    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_UsingToolkit);
}

///////////////////////////////////////////////////////////////////////////////
//
// Update! 

function UpdateOfficersKnowledge()
{
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);
	assert(SwatAIRepo != None);

	SwatAIRepo.NotifyOfficersDoorWedgeRemoved(TargetDoor);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveToRemoveWedge()
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

private function vector GetRemoveWedgePoint()
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

latent function RotateToRemoveWedgePoint()
{
	CurrentRotateTowardPointGoal = new class'RotateTowardPointGoal'(movementResource(), achievingGoal.priority, GetRemoveWedgePoint());
	assert(CurrentRotateTowardPointGoal != None);
	CurrentRotateTowardPointGoal.AddRef();

	CurrentRotateTowardPointGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardPointGoal);
	CurrentRotateTowardPointGoal.unPostGoal(self);

	CurrentRotateTowardPointGoal.Release();
	CurrentRotateTowardPointGoal = None;
}

latent function RemoveWedge()
{
	// get a reference to the wedge
	Wedge = ISwatDoor(TargetDoor).GetDeployedWedge();

	if (Wedge != None)
	{
		m_Pawn.DisableCollisionAvoidance();

		Toolkit = ISwatOfficer(m_Pawn).GetItemAtSlot(SLOT_Toolkit);
		assert(Toolkit != None);

		Toolkit.LatentWaitForIdleAndEquip();

		m_Pawn.ShouldCrouch(true);

		// get a reference to the wedge again (in case it was alreayd removed)
		Wedge = ISwatDoor(TargetDoor).GetDeployedWedge();
	
		// handles the case where the wedge has been removed
		if (Wedge != None)
		{
			// set our aim
			SetRemoveWedgeAim();

			// use it on the door
			IAmUsedOnOther(Toolkit).LatentUseOn(Wedge);

			// unset our aim
			UnsetRemoveWedgeAim();

			// play the speech that we've removed the wedge
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerWedgeRemovedSpeech();
		}
		else
		{
			// play the speech that there is no wedge
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerWedgeNotFoundSpeech();
		}

		m_Pawn.ShouldCrouch(false);

		// re-enable collision avoidance
		m_Pawn.EnableCollisionAvoidance();

		// all done.
		ISwatOfficer(m_Pawn).ReEquipFiredWeapon();
	}
	else
	{
		// play the speech that there is no wedge
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerWedgeNotFoundSpeech();
	}
}

state Running
{
Begin:
	if (TargetDoor.IsClosed() && ! TargetDoor.IsOpening() && ! TargetDoor.IsBroken())
	{
		ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

		useResources(class'AI_Resource'.const.RU_ARMS);

		MoveToRemoveWedge();
		RotateToRemoveWedgePoint();

		useResources(class'AI_Resource'.const.RU_LEGS);

		RemoveWedge();
	}

	UpdateOfficersKnowledge();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'RemoveWedgeGoal'
}
