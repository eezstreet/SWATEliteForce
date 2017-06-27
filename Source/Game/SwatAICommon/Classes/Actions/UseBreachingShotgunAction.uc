///////////////////////////////////////////////////////////////////////////////

class UseBreachingShotgunAction extends SwatCharacterAction
	implements IInterestedInDoorOpening
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private AimAtPointGoal		        CurrentAimAtPointGoal;
var private MoveToLocationGoal          CurrentMoveToLocationGoal;
var private MoveToActorGoal             CurrentMoveToActorGoal;

var private FiredWeapon		            BreachingShotgun;
var private vector						BreachAimLocation;

var(parameters) private Door            TargetDoor;
var(parameters) private NavigationPoint PostBreachPoint;

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	local ISwatDoor SwatDoor;

	super.initAction(r, goal);

	SwatDoor = ISwatDoor(TargetDoor);
    assert(SwatDoor != None);
    BreachAimLocation = SwatDoor.GetBreachAimPoint(m_Pawn);
}

function cleanup()
{
    local ISwatOfficer Officer;
    Officer = ISwatOfficer(m_Pawn);
    assert(Officer != None);

    super.cleanup();

	if (CurrentAimAtPointGoal != None)
	{
		CurrentAimAtPointGoal.Release();
		CurrentAimAtPointGoal = None;
	}

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	// unregister that we're interested that the door is opening
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	// re-enable collision avoidance (if it isn't already)
	m_Pawn.EnableCollisionAvoidance();

	if ((BreachingShotgun != None) && !BreachingShotgun.IsIdle())
	{
		BreachingShotgun.AIInterrupt();
	}

	// make sure the fired weapon is re-equipped
	Officer.InstantReEquipFiredWeapon();

    Officer.UnsetUpperBodyAnimBehavior(kUBABCI_UseBreachingShotgunAction);
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

// test to see if the breaching shotgun is currently empty, and reload it if necessary
// if we can't reload it, fail!
private latent function CheckBreachingShotgunAmmunition()
{
	assert(BreachingShotgun != None);
	assert(BreachingShotgun.IsEquipped());

	if (BreachingShotgun.NeedsReload())
	{
		if (BreachingShotgun.CanReload())
		{
			BreachingShotgun.LatentReload();
		}
		else
		{
			instantFail(ACT_NO_WEAPONS_AVAILABLE);
		}
	}
}

latent function EquipBreachingShotgun()
{
    local ISwatOfficer Officer;
    Officer = ISwatOfficer(m_Pawn);
    assert(Officer != None);

    BreachingShotgun = FiredWeapon(Officer.GetItemAtSlot(SLOT_PrimaryWeapon));
		if(BreachingShotgun == None || !BreachingShotgun.IsA('Shotgun'))
			BreachingShotgun = FiredWeapon(Officer.GetItemAtSlot(SLOT_SecondaryWeapon));
			
    // If we've been put into this action, we expect that the officer has a
    // breaching shotgun
    assert(BreachingShotgun != None);
    assert(BreachingShotgun.IsA('Shotgun'));

    if (!BreachingShotgun.IsEquipped())
    {
        BreachingShotgun.LatentWaitForIdleAndEquip();
    }

	CheckBreachingShotgunAmmunition();

    Officer.SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_UseBreachingShotgunAction);
}

function vector GetLocationToBreachFrom()
{
	local ISwatDoor SwatDoorTarget;
	local vector BreachFrom;

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	BreachFrom = SwatDoorTarget.GetBreachFromPoint(m_Pawn);

	return BreachFrom;
}

latent function MoveToBreachingLocation()
{
    // currently we just move to the open point on the door
    CurrentMoveToLocationGoal = new class'SwatAICommon.MoveToLocationGoal'(movementResource(), achievingGoal.priority, GetLocationToBreachFrom());
    assert(CurrentMoveToLocationGoal != None);
    CurrentMoveToLocationGoal.AddRef();

    CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);

    CurrentMoveToLocationGoal.postGoal(self);
    waitForGoal(CurrentMoveToLocationGoal);
    CurrentMoveToLocationGoal.unPostGoal(self);

    CurrentMoveToLocationGoal.Release();
    CurrentMoveToLocationGoal = None;
}

latent function MoveToPostBreachingPoint()
{
    CurrentMoveToActorGoal = new class'SwatAICommon.MoveToActorGoal'(movementResource(), achievingGoal.priority, PostBreachPoint);
    assert(CurrentMoveToActorGoal != None);
    CurrentMoveToActorGoal.AddRef();

    CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(false);

    CurrentMoveToActorGoal.postGoal(self);
    waitForGoal(CurrentMoveToActorGoal);
    CurrentMoveToActorGoal.unPostGoal(self);

    CurrentMoveToActorGoal.Release();
    CurrentMoveToActorGoal = None;
}

latent function AimAtDoorKnob()
{
    CurrentAimAtPointGoal = new class'AimAtPointGoal'(weaponResource(), achievingGoal.priority, BreachAimLocation);
    assert(CurrentAimAtPointGoal != None);
    CurrentAimAtPointGoal.AddRef();

    CurrentAimAtPointGoal.postGoal(self);
}

private function StopAimingAtDoorKnob()
{
	if (CurrentAimAtPointGoal != None)
	{
		CurrentAimAtPointGoal.unPostGoal(self);
		CurrentAimAtPointGoal.Release();
		CurrentAimAtPointGoal = None;
	}
}

latent function BreachDoorWithShotgun()
{
	ISwatAI(m_Pawn).SetWeaponTargetLocation(BreachAimLocation);

    // @NOTE: Pause for a brief moment before shooting to make the shot look
    // more deliberate
    Sleep(1.0);

	CheckBreachingShotgunAmmunition();

	// we're no longer interested if the door is opening (we're about to open it)
	ISwatDoor(TargetDoor).UnRegisterInterestedInDoorOpening(self);

	BreachingShotgun.SetPerfectAimNextShot();

	// @HACK Break the door "before firing the shotgun. The AI literally always misses,
	// and there is a very noticable delay if we automatically break the door AFTER firing
	// the shotgun, but if we break the door FIRST it appears to happen exactly when the
	// shot is fired. In other words, this solution looks perfect. -K.F.

	ISwatDoor(TargetDoor).Blasted(m_Pawn);
	BreachingShotgun.LatentUse();
}

function TriggerReportedDeployingShotgunSpeech()
{
	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportedDeployingShotgunSpeech();
}

state Running
{
Begin:
	if (TargetDoor.IsClosed() && ! TargetDoor.IsOpening() && ! TargetDoor.IsBroken())
	{
		ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

		useResources(class'AI_Resource'.const.RU_ARMS);

		TriggerReportedDeployingShotgunSpeech();

		MoveToBreachingLocation();

		useResources(class'AI_Resource'.const.RU_LEGS);

		// no avoiding collision while we're breaching the door!
		m_Pawn.DisableCollisionAvoidance();

		clearDummyWeaponGoal();

		AimAtDoorKnob();
		EquipBreachingShotgun();

		WaitForZulu();

		BreachDoorWithShotgun();

		StopAimingAtDoorKnob();
		ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

		// re-enable collision avoidance!
		m_Pawn.EnableCollisionAvoidance();

		useResources(class'AI_Resource'.const.RU_ARMS);
		clearDummyMovementGoal();

		if (PostBreachPoint != None)
		{
			MoveToPostBreachingPoint();
		}
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'UseBreachingShotgunGoal'
}

///////////////////////////////////////////////////////////////////////////////
