///////////////////////////////////////////////////////////////////////////////
// PickUpWeaponAction.uc 
// The Action that causes an enemy to pick up a weapon
// (lots of code copied from SecureEvidenceAction)

class PickUpWeaponAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) private HandHeldEquipmentModel WeaponModel;

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

//function IEvidence GetEvidenceTarget()
//{
//    return EvidenceTarget;
//}

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
    assert(WeaponModel != None);
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, WeaponModel);
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
    assert(WeaponModel != None);
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(WeaponModel.Location - m_Pawn.Location));
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

latent function PickUpWeapon()
{
    local float ZDiff;
    local int AnimSpecialChannel;

	m_Pawn.DisableCollisionAvoidance();

    assert(WeaponModel != None);

	// if the weapon hasn't already been secured
	if (WeaponModel.CanBeUsedNow())
	{
		// todo: secureWeapon animations are just placeholder (?)
		ZDiff = m_Pawn.Location.Z - WeaponModel.Location.Z;
		if (ZDiff > kSecureOnFloorThreshold)
			AnimSpecialChannel = m_Pawn.AnimPlaySpecial('secureWeaponFloor', 0.1);
		else
			AnimSpecialChannel = m_Pawn.AnimPlaySpecial('secureWeaponTable', 0.1);

		m_Pawn.FinishAnim(AnimSpecialChannel);

		m_Pawn.EnableCollisionAvoidance();

		ISwatEnemy(m_Pawn).PickUpWeaponModel(WeaponModel);
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat())
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
	}
	}
}

state Running
{
Begin:
	if (m_Pawn.logTyrion)
		log(Name @ "started");

	useResources(class'AI_Resource'.const.RU_ARMS);

	MoveIntoPosition();

	RotateTowardsTarget();

	useResources(class'AI_Resource'.const.RU_LEGS);
	PickUpWeapon();

	succeed();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'PickUpWeaponGoal'
}
