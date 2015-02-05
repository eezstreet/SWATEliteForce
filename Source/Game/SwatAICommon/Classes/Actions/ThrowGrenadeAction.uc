///////////////////////////////////////////////////////////////////////////////
// ThrowGrenadeAction.uc - UseGrenadeAction class
// this action that causes the AI to throw the grenade at a particular point

class ThrowGrenadeAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum AIThrowSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) vector							TargetLocation;
var(parameters) vector							ThrowFromLocation;
var(parameters) EquipmentSlot					GrenadeSlot;
var(parameters) AIThrowSide						ThrowSide;
var(parameters) rotator							ThrowRotation;
var(parameters) bool							ThrowRotationOverridden;
var(parameters) bool							bWaitToThrowGrenade;
var(parameters) IInterestedGrenadeThrowing		ThrowClient;

// our behaviors
var private MoveToLocationGoal					CurrentMoveToLocationGoal;
var private RotateTowardRotationGoal			CurrentRotateTowardRotationGoal;
var private UseGrenadeGoal						CurrentUseGrenadeGoal;

///////////////////////////////////////////////////////////////////////////////
//
// cleanup

function cleanup()
{
	super.cleanup();

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

	if (CurrentUseGrenadeGoal != None)
	{
		CurrentUseGrenadeGoal.Release();
		CurrentUseGrenadeGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	// calling down the chain should do nothing
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  succeeding!");

	instantSucceed();
}

///////////////////////////////////////////////////////////////////////////////
//
// Messages from our goal

function NotifyThrowGrenade()
{
	assert(bWaitToThrowGrenade == true);
	assert(CurrentUseGrenadeGoal != None);
		
	CurrentUseGrenadeGoal.NotifyThrowGrenade();
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

latent function RotateToThrowGrenade()
{
	if (! ThrowRotationOverridden)
	{
		ThrowRotation = rotator(TargetLocation - Pawn.Location);
	}

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, ThrowRotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

private function bool IsRotatedToThrowRotation()
{
//	log("StackUpPoint.Rotation " $ StackUpPoint.Rotation $ " GetAimOrientation: " $ ISwatAI(m_Pawn).GetAimOrientation() $ " == " $ (WrapAngle0To2Pi(StackUpPoint.Rotation.Yaw) == WrapAngle0To2Pi(ISwatAI(m_Pawn).GetAimOrientation().Yaw)));

	return (WrapAngle0To2Pi(ISwatAI(m_Pawn).GetAimOrientation().Yaw) == WrapAngle0To2Pi(int(ISwatAI(m_Pawn).GetAnimBaseYaw())));
}

latent function MoveToThrowFromLocation()
{
	CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(movementResource(), achievingGoal.Priority, ThrowFromLocation);
	assert(CurrentMoveToLocationGoal != None);
	CurrentMoveToLocationGoal.AddRef();

	CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(false);
	CurrentMoveToLocationGoal.SetShouldWalkEntireMove(false);

	CurrentMoveToLocationGoal.postGoal(self);
	WaitForGoal(CurrentMoveToLocationGoal);
	CurrentMoveToLocationGoal.unPostGoal(self);

	CurrentMoveToLocationGoal.Release();
	CurrentMoveToLocationGoal = None;

	if (! IsRotatedToThrowRotation())
	{
		RotateToThrowGrenade();
	}
}

function ThrowGrenade()
{
	// let the pawn know our throw side before we start the use grenade behavior
	ISwatAI(m_Pawn).SetThrowSide(ThrowSide);

	CurrentUseGrenadeGoal = new class'UseGrenadeGoal'(weaponResource(), GrenadeSlot, TargetLocation);
	assert(CurrentUseGrenadeGoal != None);
	CurrentUseGrenadeGoal.AddRef();

	CurrentUseGrenadeGoal.SetWaitToThrowGrenade(bWaitToThrowGrenade);

	if (ThrowClient != None)
	{
		CurrentUseGrenadeGoal.RegisterForGrenadeThrowing(ThrowClient);
	}

	CurrentUseGrenadeGoal.postGoal(self);
}

state Running
{
 Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	RotateToThrowGrenade();

	useResources(class'AI_Resource'.const.RU_LEGS);
	clearDummyWeaponGoal();

	ThrowGrenade();

	while (class'Pawn'.static.checkConscious(m_Pawn) && ! CurrentUseGrenadeGoal.hasCompleted())
	{
		if (! m_Pawn.ReachedLocation(ThrowFromLocation))
		{
			clearDummyMovementGoal();

			MoveToThrowFromLocation();

			useResources(class'AI_Resource'.const.RU_LEGS);
		}
		else if (! IsRotatedToThrowRotation())
		{
			clearDummyMovementGoal();

			RotateToThrowGrenade();

			useResources(class'AI_Resource'.const.RU_LEGS);
		}

		yield();
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'ThrowGrenadeGoal'
}
