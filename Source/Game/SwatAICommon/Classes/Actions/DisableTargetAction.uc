///////////////////////////////////////////////////////////////////////////////

class DisableTargetAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Actor					Target;

// behaviors we use
var private MoveToActorGoal				CurrentMoveToActorGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

// internal

// equipment
var private HandheldEquipment			Toolkit;

// door (in case it's a c2 charge)
var private	ISwatDoor					TargetSwatDoor;

// config
var config float						DistanceFromTargetToDisable;

// constants
const kDisableOnFloorThreshold = 48;

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

	if (m_Pawn.bIsCrouched)
		m_Pawn.ShouldCrouch(false);

  // Guarentee collision avoidance is back on
  m_Pawn.EnableCollisionAvoidance();

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();

	// make sure our aim is unset
	UnsetDisableTargetAim();
}

///////////////////////////////////////////////////////////////////////////////
//
// Aiming

private function SetDisableTargetAim()
{
	ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_UsingToolkit);
	ISwatAI(m_Pawn).AimAtActor(Target);
}

private function UnsetDisableTargetAim()
{
	// we're no longer aiming at someone
    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_UsingToolkit);
}

///////////////////////////////////////////////////////////////////////////////
//
// Speech

private function TriggerCompletedDisableSpeech()
{
	if (Target.IsA('BombBase'))
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportedBombDisabledSpeech();
	}
	else if (Target.IsA('BoobyTrap'))
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportedTrapDisabledSpeech();
	}
	else
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportedGenericDisabledSpeech();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveIntoPosition()
{
	assert(Target != None);
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, Target);
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetAcceptNearbyPath(true);
	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToActorGoal.SetMoveToThreshold(40.0);

	// post the goal and wait for it to complete
	CurrentMoveToActorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

latent function RotateTowardsTarget()
{
	assert(Target != None);
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(Target.Location - m_Pawn.Location));
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

latent function DisableTarget()
{
	local float ZDiff;


	m_Pawn.DisableCollisionAvoidance();

	ZDiff = m_Pawn.Location.Z - Target.Location.Z;

	if (ZDiff > kDisableOnFloorThreshold)
		m_Pawn.ShouldCrouch(true);

	// Equip
	Toolkit = ISwatOfficer(m_Pawn).GetItemAtSlot(SLOT_Toolkit);
	assert(Toolkit != None);
	Toolkit.LatentWaitForIdleAndEquip();

	SetDisableTargetAim();

	// Use it on the target
	IAmUsedOnOther(Toolkit).LatentUseOn(Target);

	UnsetDisableTargetAim();

	// Unequip
	ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

	m_Pawn.EnableCollisionAvoidance();

}

state Running
{
Begin:

	useResources(class'AI_Resource'.const.RU_ARMS);

	// trigger the appropriate reply speech
	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerRepliedDisablingSpeech();

	MoveIntoPosition();
	RotateTowardsTarget();

	useResources(class'AI_Resource'.const.RU_LEGS);

	DisableTarget();

	TriggerCompletedDisableSpeech();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    satisfiesGoal = class'DisableTargetGoal'
}

///////////////////////////////////////////////////////////////////////////////
