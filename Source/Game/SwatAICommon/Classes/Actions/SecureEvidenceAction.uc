///////////////////////////////////////////////////////////////////////////////
// SecureEvidenceAction.uc - StackUpAction class
// The Action that causes the Officers to secure the evidence in question

class SecureEvidenceAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) private IEvidence		EvidenceTarget;

// behaviors we use
var private MoveToActorGoal				CurrentMoveToActorGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

const kSecureOnFloorThreshold = 48;

///////////////////////////////////////////////////////////////////////////////
// 
// Cleanup

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

    // Guarentee collision avoidance is back on
    m_Pawn.EnableCollisionAvoidance();
}

function IEvidence GetEvidenceTarget()
{
    return EvidenceTarget;
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// if our movement goal fails, we succeed so we don't get reposted!
	if (goal == CurrentMoveToActorGoal)
	{
		instantFail(errorCode);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveIntoPosition()
{
    assert(Actor(EvidenceTarget) != None);
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, Actor(EvidenceTarget));
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
    assert(Actor(EvidenceTarget) != None);
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(Actor(EvidenceTarget).Location - m_Pawn.Location));
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

latent function SecureEvidence()
{
    local Actor EvidenceActor;
    local float ZDiff;
    local int AnimSpecialChannel;

	m_Pawn.DisableCollisionAvoidance();

    EvidenceActor = Actor(EvidenceTarget);
    assert(EvidenceActor != None);

	// if the weapon hasn't already been secured
	if (EvidenceTarget.CanBeUsedNow())
	{
		ZDiff = m_Pawn.Location.Z - EvidenceActor.Location.Z;
		if (ZDiff > kSecureOnFloorThreshold)
			AnimSpecialChannel = m_Pawn.AnimPlaySpecial('secureWeaponFloor', 0.1);
		else
			AnimSpecialChannel = m_Pawn.AnimPlaySpecial('secureWeaponTable', 0.1);

		m_Pawn.FinishAnim(AnimSpecialChannel);

		m_Pawn.EnableCollisionAvoidance();

		if (EvidenceActor.IsA('FiredWeaponModel'))
		{
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerWeaponSecuredSpeech();
		}
		else
		{
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerEvidenceSecuredSpeech();
		}
	}
	else
	{
		if (EvidenceActor.IsA('FiredWeaponModel'))
		{
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerWeaponNotFoundSpeech();
		}
		else
		{
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerEvidenceNotFoundSpeech();
		}
	}
}

state Running
{
Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	MoveIntoPosition();

	RotateTowardsTarget();

	useResources(class'AI_Resource'.const.RU_LEGS);
	SecureEvidence();

	succeed();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'SecureEvidenceGoal'
}
