///////////////////////////////////////////////////////////////////////////////

class DisableTargetAction extends SwatCharacterAction
	implements IInterestedInDoorOpening;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Actor					Target;
var(parameters) vector					DisableFromPoint;
var(parameters) bool					bUseMoveToThreshold;

// behaviors we use
var private MoveToLocationGoal			CurrentMoveToLocationGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

// internal
var private bool						bMovedToDisableTarget;
var private bool						bDoorHasOpened;

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

	if (m_Pawn.bIsCrouched)
		m_Pawn.ShouldCrouch(false);

    // Guarentee collision avoidance is back on
    m_Pawn.EnableCollisionAvoidance();

	// unregister that we're interested that the door is opening
	if (TargetSwatDoor != None)
		TargetSwatDoor.UnRegisterInterestedInDoorOpening(self);

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
// IInterestedInDoorOpening implementation

function NotifyDoorOpening(Door TargetDoor)
{
	if (! bMovedToDisableTarget)
	{
		// door is opening, can't disable the target on an open door
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
// State Code

latent function MoveIntoPosition()
{
    CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(movementResource(), achievingGoal.priority, DisableFromPoint);
    assert(CurrentMoveToLocationGoal != None);
    CurrentMoveToLocationGoal.AddRef();

    CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToLocationGoal.SetAcceptNearbyPath(true);

	// only use a padded move threshold if we're supposed to
	if (bUseMoveToThreshold)
	{
		CurrentMoveToLocationGoal.SetMoveToThreshold(m_Pawn.CollisionRadius + DistanceFromTargetToDisable);
	}

    // post the goal and wait for it to complete
    CurrentMoveToLocationGoal.postGoal(self);
    
	while (! CurrentMoveToLocationGoal.hasCompleted())
	{
		// if the target is a deployed c2, stop moving
		if ((Target.IsA('DeployedC2ChargeBase') && Target.bHidden) || bDoorHasOpened)
			succeed();

		yield();
	}

    CurrentMoveToLocationGoal.unPostGoal(self);

    CurrentMoveToLocationGoal.Release();
    CurrentMoveToLocationGoal = None;
}

latent function RotateTowardsTarget()
{
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

	if (! bDoorHasOpened)
	{
		SetDisableTargetAim();

		// Use it on the target
		IAmUsedOnOther(Toolkit).LatentUseOn(Target);

		UnsetDisableTargetAim();
	}

	// Unequip
	ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

	m_Pawn.EnableCollisionAvoidance();

}

state Running
{
Begin:
	if (Target.IsA('DeployedC2ChargeBase'))
	{
		// if the target has been hidden already, don't bother dealing with it
		if (Target.bHidden)
			succeed();

		TargetSwatDoor = IDeployedC2Charge(Target).GetDoorDeployedOn();
		TargetSwatDoor.RegisterInterestedInDoorOpening(self);
	}

	useResources(class'AI_Resource'.const.RU_ARMS);

	// trigger the appropriate reply speech
	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerRepliedDisablingSpeech();

	bMovedToDisableTarget = true;
	MoveIntoPosition();
	RotateTowardsTarget();

	useResources(class'AI_Resource'.const.RU_LEGS);

	DisableTarget();

	// trigger the appropriate completed disable speech, if the door hasn't opened
	if (! bDoorHasOpened)		
		TriggerCompletedDisableSpeech();
	
	succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    satisfiesGoal = class'DisableTargetGoal'
}

///////////////////////////////////////////////////////////////////////////////
