///////////////////////////////////////////////////////////////////////////////
// SquadMoveAndClearAction.uc - SquadMoveAndClearAction class
// this action is used to organize the Officer's move & clear behavior

class SquadMoveAndClearAction extends SquadStackUpAction
	implements Tyrion.ISensorNotification, IInterestedInDoorOpening, Engine.IInterestedGrenadeThrowing
	config(AI);
///////////////////////////////////////////////////////////////////////////////

import enum AIThrowSide from SwatAICommon.ISwatAI;
import enum AIDoorUsageSide from SwatAICommon.ISwatAI;
import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private MoveToActorGoal				CurrentMoveToActorGoal;
var protected OpenDoorGoal				CurrentOpenDoorGoal;
var private MoveToLocationGoal			CurrentMoveToLocationGoal;
var private ThrowGrenadeGoal			CurrentThrowGrenadeGoal;
var private RemoveWedgeGoal             CurrentRemoveWedgeGoal;
var private array<MoveAndClearGoal>		MoveAndClearGoals;
var private array<StackupGoal>			MoveUpStackupGoals;

var private array<ClearPoint>			ClearPoints;
var private bool						bClearingRoomIsOnRight;
var private bool						bShouldStackUpBeforeClearing;
var private Formation					ClearFormation;
var private MoveInFormationGoal			FollowerMoveInFormationGoal;
var private DistanceSensor				LeaderDistanceSensor;
var private DistanceSensor				FollowerDistanceSensor;
var private MoveAndClearGoal			LeaderMoveAndClearGoal;
var private MoveAndClearGoal			FollowerMoveAndClearGoal;
var private Timer						WaitForFirstTwoOfficersTimer;

var private StackUpGoal					ThirdOfficerStackUpGoal;
var private StackUpGoal					FourthOfficerStackUpGoal;

var private DoorSideSensor				LeaderDoorSideSensor;
var private DoorSideSensor				FollowerDoorSideSensor;
var private bool						bLeaderReachedOtherSide;
var private bool						bFollowerReachedOtherSide;

var private int							NumClearPointsInClearingRoom;

var private Pawn						Leader;
var private Pawn						Follower;
var private Pawn						DoorOpener;
var protected Pawn						Thrower;
var protected Pawn						Breacher;
var private Pawn						ThirdOfficer;
var private Pawn						FourthOfficer;

var config float						InitialClearPauseTime;

var config float						MaxWaitForFirstTwoOfficersTime;

var config float						FormationMoveToThreshold;
var config float						FormationWalkThreshold;

var config float						DoorOpenedFromSideDelayTime;

var private SwatGrenadeProjectile		Projectile;

const kLeaderClearPointIndex      = 1;
const kFollowerClearPointIndex    = 0;

const kMoveToDoorPriority         = 90;		// same as MoveAndClear behavior priority
const kMoveToThrowGrenadePriority = 86;		// same as ThrowGrenadeGoal behavior priority

const kGrenadeThrowOffsetFromDoor = 20.0;

///////////////////////////////////////////////////////////////////////////////
//
// selection heuristic

// In the case of all MoveAndClearActions, we only want to match actions with
//  goals that exactly match the satisfiesGoal (otherwise the SquadMoveAndClearAction
//  can satisfy the SquadBangAndClearGoal, which isn't correct)
function float selectionHeuristic( AI_Goal goal )
{
	if (satisfiesGoal == goal.class)
	{
		return 1.0;
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Init / cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	ClearPoints = ISwatDoor(TargetDoor).GetClearPoints(CommandOrigin);

	DetermineClearRoomSide();
	bShouldStackUpBeforeClearing = ShouldStackUpBeforeClearing();
//	log("bShouldStackUpBeforeClearing is: " @ bShouldStackUpBeforeClearing);

	FindNumberOfClearPointsInClearingRoom();
}

private function DetermineClearRoomSide()
{
	// if the command came from the left side of the door, we are clearing the right room...
	// and vice versa.
	if (ISwatDoor(TargetDoor).PointIsToMyLeft(CommandOrigin))
	{
		bClearingRoomIsOnRight = true;
	}
	else
	{
		bClearingRoomIsOnRight = false;
	}
}

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentOpenDoorGoal != None)
	{
		CurrentOpenDoorGoal.Release();
		CurrentOpenDoorGoal = None;
	}

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	if (CurrentThrowGrenadeGoal != None)
	{
		CurrentThrowGrenadeGoal.Release();
		CurrentThrowGrenadeGoal = None;
	}

    if (CurrentRemoveWedgeGoal != None)
	{
		CurrentRemoveWedgeGoal.Release();
		CurrentRemoveWedgeGoal = None;
	}

	if (ClearFormation != None)
	{
		ClearFormation.Cleanup();
		ClearFormation.Release();
		ClearFormation = None;
	}

	if (FollowerMoveInFormationGoal != None)
	{
		FollowerMoveInFormationGoal.Release();
		FollowerMoveInFormationGoal = None;
	}

	if (ThirdOfficerStackUpGoal != None)
	{
		ThirdOfficerStackUpGoal.Release();
		ThirdOfficerStackUpGoal = None;
	}

	if (FourthOfficerStackUpGoal != None)
	{
		FourthOfficerStackUpGoal.Release();
		FourthOfficerStackUpGoal = None;
	}

	DeactivateDistanceSensors();
	DeactivateDoorSideSensors();

	ClearOutMoveAndClearGoals();

	// we have to clean up the timer's delegate variable (which might point to us!)
	ClearFirstTwoOfficersTimer();

	// just in case this completes while we're waiting for the door to open
	ISwatDoor(TargetDoor).UnregisterInterestedInDoorOpening(self);

	if (Projectile != None)
	{
		// unregister ourselves as interested in grenade throwing on the projectile
		Projectile.UnRegisterInterestedGrenadeRegistrant(self);
	}
}

function ClearOutMoveAndClearGoals()
{
	if (LeaderMoveAndClearGoal != None)
	{
		LeaderMoveAndClearGoal.Release();
		LeaderMoveAndClearGoal = None;
	}

	if (FollowerMoveAndClearGoal != None)
	{
		FollowerMoveAndClearGoal.Release();
		FollowerMoveAndClearGoal = None;
	}

	while (MoveAndClearGoals.Length > 0)
	{
		if (MoveAndClearGoals[0] != None)
		{
			MoveAndClearGoals[0].Release();
			MoveAndClearGoals[0] = None;
		}

		MoveAndClearGoals.Remove(0, 1);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Notifications

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
//	log("SquadMoveAndClearAction received sensor message from " $ sensor.name $ " value is "$ value.integerData);

	// we only (currently) get messages from a distance sensor
	if ((sensor == LeaderDistanceSensor) || (sensor == FollowerDistanceSensor))
	{
		if (sensor == LeaderDistanceSensor)
		{
			assert(Leader != None);
//			log("leader distance sensor triggered at time " $ resource.pawn().Level.TimeSeconds);

			if ((value.integerData == 0) && (Leader.GetRoomName() == ClearPoints[kLeaderClearPointIndex].GetRoomName(None)))
			{
				// deactivate the sensor
				LeaderDistanceSensor.deactivateSensor(self);
				LeaderDistanceSensor = None;

//				log("leader is in the room and will be paused at time " $ resource.pawn().Level.TimeSeconds);

				PauseLeadingOfficer();

				// if we don't have a follower, just go
				// otherwise start the follower's move and clear behavior
				if (Follower == None)
				{
					// only run if we're idle (paused and not stopped on a goal)
					if (isIdle())
						runAction();
				}
				else
				{
					StartFollowerMoveAndClear();
				}
			}
		}
		else if (sensor == FollowerDistanceSensor)
		{
			assert(Follower != None);

			if ((value.integerData == 0) && (Follower.GetRoomName() == ClearPoints[kFollowerClearPointIndex].GetRoomName(None)))
			{
				FollowerDistanceSensor.deactivateSensor(self);
				FollowerDistanceSensor = None;

//				log("follower distance sensor triggered - isIdle: " $ isIdle() $ " waitingForGoalsN: " $ waitingForGoalsN $ " at time " $ resource.pawn().Level.TimeSeconds);

				// start running again if we're paused and not waiting for any goals
				if (isIdle())
					runAction();
			}
		}
	}
	else if (sensor.IsA('DoorSideSensor'))
	{
		HandleDoorSideSensorMessage(sensor);
	}
	else
	{
		super.onSensorMessage(sensor, value, userData);
	}
}

private function DeactivateDistanceSensors()
{
	if (LeaderDistanceSensor != None)
	{
		PauseLeadingOfficer();

		LeaderDistanceSensor.deactivateSensor(self);
		LeaderDistanceSensor = None;
	}

	if (FollowerDistanceSensor != None)
	{
		FollowerDistanceSensor.deactivateSensor(self);
		FollowerDistanceSensor = None;
	}
}

private function DeactivateDoorSideSensors()
{
	if (LeaderDoorSideSensor != None)
	{
		LeaderDoorSideSensor.deactivateSensor(self);
		LeaderDoorSideSensor = None;
	}

	if (FollowerDoorSideSensor != None)
	{
		FollowerDoorSideSensor.deactivateSensor(self);
		FollowerDoorSideSensor = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Callbacks / Notifications

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	super.goalAchievedCB(goal, child);

	if (goal == CurrentOpenDoorGoal)
	{
		CurrentOpenDoorGoal.unPostGoal(self);
		CurrentOpenDoorGoal.Release();
		CurrentOpenDoorGoal = None;
	}
}

// handle officers dying during a move and clear
protected function NotifyPawnDied(Pawn pawn)
{
	super.NotifyPawnDied(pawn);

	if (pawn.LogAI)
		log("MoveAndClearAction::NotifyPawnDied called - pawn is: " $ pawn);

	assert(pawn != None);

	// if the pawn is gonna be deleted restart the behavior,
    // or if someone important dies before we've moved through or are moving through the door, restart the behavior
	// don't restart the behavior if we just threw a grenade
	if (pawn.bPendingDelete ||
        ((!AreAnyOfficersInRoomToClear() && (LeaderMoveAndClearGoal == None) && (FollowerMoveAndClearGoal == None) && (Projectile == None)) &&
		 ((pawn == Leader) || (pawn == Follower) || (pawn == Thrower) || (pawn == Breacher))))
	{
		instantFail(ACT_GENERAL_FAILURE);
	}
	else
	{
		// setup the officers' roles again
		SetupOfficerRoles();
	}
}

function NotifyGrenadeDetonated(SwatGrenadeProjectile Grenade)
{
	// make sure we get unregistered from the grenade projectile
	// because it will crash if we don't... :)
	Grenade.UnRegisterInterestedGrenadeRegistrant(self);

//	log("SquadMoveAndClearAction::NotifyGrenadeDetonated - IsIdle: " $ isIdle() $ " - running action at time: " $ resource.pawn().Level.TimeSeconds);

	if (isIdle())
	{
		runAction();
	}
}

function NotifyDoorOpening(Door TargetDoor)
{
//	log("SquadMoveAndClearAction::NotifyDoorOpening - IsIdle: " $ isIdle() $ " - running action at time: " $ resource.pawn().Level.TimeSeconds);

	// we only run if the first officer isn't the thrower
	if (isIdle() && !IsFirstOfficerThrower())
	{
		runAction();
	}
}

// notification that a character is ready to throw a grenade
function NotifyGrenadeReadyToThrow()
{
//	log("SquadMoveAndClearAction::NotifyGrenadeReadyToThrow - IsIdle: " $ isIdle() $ " - running action at time: " $ resource.pawn().Level.TimeSeconds);

	if (isIdle())
	{
		runAction();
	}
}

// notification that a the client has been registered on the projectile
function NotifyRegisteredOnProjectile(SwatGrenadeProjectile Grenade)
{
	Projectile = Grenade;
}

///////////////////////////////////////////////////////////////////////////////
//
// Shared State Code (for subclasses)

latent private function LatentMoveOfficerToActor(Pawn Officer, Actor Destination, int priority)
{
	while (! Officer.ReachedDestination(Destination))
	{
		CurrentMoveToActorGoal = new class'MoveToActorGoal'(AI_Resource(Officer.MovementAI), priority, Destination);
		assert(CurrentMoveToActorGoal != None);
		CurrentMoveToActorGoal.AddRef();

		CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
		CurrentMoveToActorGoal.SetWalkThreshold(0.0);

		CurrentMoveToActorGoal.postGoal(self);
		WaitForGoal(CurrentMoveToActorGoal);
		CurrentMoveToActorGoal.unPostGoal(self);

		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}
}

// returns true when the door is an empty doorway or if it's not closed, opening, or is broken
// returns false if the door is closed
protected function bool ShouldRunToStackupPoint()
{
	return TargetDoor.IsEmptyDoorWay() || !TargetDoor.IsClosed() || TargetDoor.IsOpening() || TargetDoor.IsBroken();
}

// @TODO: there's a few things we can't implement yet.
//	* removing wedges if there is a wedge on the target door.  wedges haven't been implemented yet
//  * AI knowledge of a door being locked, blocked, wedged, or open
//		-- need to have some facility to handle when AIs don't know that a door is locked
//		    (we want them to assume a door is closed until they try and open the door,
//			 and when they can't open it they now "know" that the door is wedged or locked)
latent function OpenTargetDoor(Pawn Officer)
{
	assert(Officer != None);

	// only open the door if it's closed and not broken
	if (CanInteractWithTargetDoor())
	{
		ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

		// have him open the door
		CurrentOpenDoorGoal = new class'OpenDoorGoal'(AI_Resource(Officer.MovementAI), TargetDoor);
		assert(CurrentOpenDoorGoal != None);
		CurrentOpenDoorGoal.AddRef();

		CurrentOpenDoorGoal.SetPreferSides();

		CurrentOpenDoorGoal.postGoal(self);
	}
}

function FirstOfficerReadyToOpenDoor();

protected function bool ShouldThrowerBeFirstOfficer()
{
	return (TargetDoor.IsEmptyDoorWay() || ISwatDoor(TargetDoor).IsOpen() || TargetDoor.IsOpening() || ISwatDoor(TargetDoor).IsBroken());
}

// return the first officer we find with the grenade
function Pawn GetThrowingOfficer(EquipmentSlot ThrownItemSlot)
{
	local int i;
	local Pawn Officer;

	// if the door is an empty doorway, is open, is opening, or is broken, try to use the first officer
	// otherwise use the second officer
	if (ShouldThrowerBeFirstOfficer())
	{
		i = 0;
	}
	else
	{
		i = 1;
	}

//	log("get throwing officer - starting i is: " $ i);

	while(i<OfficersInStackupOrder.Length)
	{
//		log("get throwing officer - i is: " $ i);

		Officer = OfficersInStackupOrder[i];

		if (class'Pawn'.static.checkConscious(Officer) && (Officer != Breacher))
		{
			if (ISwatOfficer(Officer).GetThrownWeapon(ThrownItemSlot) != None)
			{
				if (Officer.logAI)
					log("Officer to throw is: " $ Officer);

				return Officer;
			}
		}

		++i;
	}

	// now try the first officer
	Officer = OfficersInStackupOrder[0];

	if (class'Pawn'.static.checkConscious(Officer))
	{
		if (ISwatOfficer(Officer).GetThrownWeapon(ThrownItemSlot) != None)
		{
			return Officer;
		}
	}

	// now try again, without the breacher restriction
	i = 0;
	while(i<OfficersInStackupOrder.Length)
	{
		Officer = OfficersInStackupOrder[i];

		if (class'Pawn'.static.checkConscious(Officer))
		{
			if (ISwatOfficer(Officer).GetThrownWeapon(ThrownItemSlot) != None)
			{
				if (Officer.logAI)
					log("Officer to throw is: " $ Officer);

				return Officer;
			}
		}

		++i;
	}

	// didn't find an alive officer with the thrown weapon available
	return None;
}

private latent function MoveOfficerToThrowingPoint(Pawn Officer, vector ThrowingPoint)
{
	// quick reject to see if the officer is already at that location
	if (! Officer.ReachedLocation(ThrowingPoint))
	{
		CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(AI_Resource(Officer.movementAI), 80, ThrowingPoint);
		assert(CurrentMoveToLocationGoal != None);
		CurrentMoveToLocationGoal.AddRef();

		CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);

		CurrentMoveToLocationGoal.postGoal(self);
		WaitForGoal(CurrentMoveToLocationGoal);
		CurrentMoveToLocationGoal.unPostGoal(self);

		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}
}

private function vector GetTargetDoorEdge(Pawn Officer)
{
	local vector FarDoorEdge, NearDoorEdge, TargetEdge;

	FarDoorEdge  = TargetDoor.Location + (vector(TargetDoor.Rotation) * kGrenadeThrowOffsetFromDoor);
	NearDoorEdge = TargetDoor.Location - (vector(TargetDoor.Rotation) * kGrenadeThrowOffsetFromDoor);

	if (VSize(FarDoorEdge - Officer.Location) > VSize(NearDoorEdge - Officer.Location))
	{
		TargetEdge = FarDoorEdge;
	}
	else
	{
		TargetEdge = NearDoorEdge;
	}

	return TargetEdge;
}

private function AIThrowSide GetThrowSide(vector CenterOpenPoint, vector ThrowingPoint)
{
	local vector LeftDirection;

	LeftDirection = Normal(TargetDoor.Location - CenterOpenPoint) Cross vect(0,0,1);

	// if we're headed in the left direction, then we're on the right side, and vice versa
	if ((Normal(CenterOpenPoint - ThrowingPoint) Dot LeftDirection) > 0.0)
	{
		return kThrowFromRight;
	}
	else
	{
		return kThrowFromLeft;
	}
}

private function vector GetTargetThrowPoint(vector ThrowOrigin)
{
	local float AdditionalGrenadeThrowDistance;
	local vector TargetThrowPoint;

	// get the additional distance to throw
	AdditionalGrenadeThrowDistance = ISwatDoor(TargetDoor).GetAdditionalGrenadeThrowDistance(CommandOrigin);

	// get the target throw point based on the origin
	TargetThrowPoint = TargetDoor.Location + Normal(TargetDoor.Location - ThrowOrigin) * AdditionalGrenadeThrowDistance;

	return TargetThrowPoint;
}

latent function PrepareToThrowGrenade(EquipmentSlot GrenadeSlot, bool bWaitToThrowGrenade)
{
	local vector TargetThrowPoint, ThrowFromPoint, CenterPoint;
	local rotator ThrowRotation;
	local AIDoorUsageSide DoorUsageSide;
	local AIThrowSide ThrowSide;
	local StackUpPoint ThrowerStackUpPoint;
	local PlacedThrowPoint PlacedThrowPointToUse;

	PlacedThrowPointToUse = ISwatDoor(TargetDoor).GetPlacedThrowPoint(CommandOrigin);

	// remove the stacked up goal on the thrower
	// because it will try and move the officer back to his stackup point
	RemoveStackedUpGoalOnOfficer(Thrower);

	// get the center point
	CenterPoint = ISwatDoor(TargetDoor).GetCenterOpenPoint(Thrower, DoorUsageSide);

	if (PlacedThrowPointToUse != None)
	{
		// move to the throw point
		LatentMoveOfficerToActor(Thrower, PlacedThrowPointToUse, kMoveToThrowGrenadePriority);

		ThrowSide        = PlacedThrowPointToUse.ThrowSide;
		ThrowFromPoint   = PlacedThrowPointToUse.Location;
		TargetThrowPoint = GetTargetThrowPoint(ThrowFromPoint);

		if (ThrowSide == kThrowFromCenter)
		{
			ThrowRotation = rotator(TargetThrowPoint - ThrowFromPoint);
		}
		else
		{
			ThrowRotation = ISwatDoor(TargetDoor).GetSidesOpenRotation(ThrowFromPoint);
		}
	}
	else
	{
		TargetThrowPoint = GetTargetThrowPoint(CenterPoint);
		DoorUsageSide    = ISwatDoor(TargetDoor).GetOpenPositions(Thrower, true, ThrowFromPoint, ThrowRotation);

		// get the thrower's stack up point, if specified to do so, we will throw from there
		ThrowerStackUpPoint = GetStackupPointForOrderedOfficer(Thrower);

		// if we're throwing from the side and we can fit there, set the correct throw side
		// otherwise just use the center
//		log("DoorUsageSide: " $ DoorUsageSide $ " Thrower.CanSetLocation(ThrowFromPoint): " $Thrower.CanSetLocation(ThrowFromPoint));

		if (ThrowerStackUpPoint.CanThrowFromPoint)
		{
			ThrowFromPoint   = ThrowerStackUpPoint.Location;
			TargetThrowPoint = GetTargetThrowPoint(ThrowFromPoint);
			ThrowSide        = ThrowerStackUpPoint.ThrowSide;

			if (ThrowSide == kThrowFromCenter)
			{
				ThrowRotation = rotator(TargetThrowPoint - ThrowFromPoint);
			}
			else
			{
				ThrowRotation = ISwatDoor(TargetDoor).GetSidesOpenRotation(ThrowFromPoint);
			}
		}
		else if ((DoorUsageSide != kUseDoorCenter) && !TargetDoor.IsEmptyDoorway())
		{
			ThrowSide = GetThrowSide(CenterPoint, ThrowFromPoint);
		}
		else
		{
			ThrowFromPoint   = CenterPoint;
			ThrowSide        = kThrowFromCenter;
			ThrowRotation    = rotator(TargetThrowPoint - ThrowFromPoint);
		}

		MoveOfficerToThrowingPoint(Thrower, ThrowFromPoint);
	}

	CurrentThrowGrenadeGoal = new class'ThrowGrenadeGoal'(AI_Resource(Thrower.characterAI), TargetThrowPoint, Thrower.Location, GrenadeSlot, true);
	assert(CurrentThrowGrenadeGoal != None);
	CurrentThrowGrenadeGoal.AddRef();

	CurrentThrowGrenadeGoal.SetThrowSide(ThrowSide);
	CurrentThrowGrenadeGoal.SetThrowRotation(ThrowRotation);
	CurrentThrowGrenadeGoal.SetWaitToThrowGrenade(TargetDoor.IsClosed() && ! TargetDoor.IsOpening() && bWaitToThrowGrenade);
	CurrentThrowGrenadeGoal.RegisterForGrenadeThrowing(self);
	CurrentThrowGrenadeGoal.postGoal(self);

	// pause and wait for the character to be ready to throw the grenade
	pause();
}

latent function ThrowGrenade()
{
	if (TargetDoor.IsClosed() && !TargetDoor.IsOpening() && !TargetDoor.IsBroken() && !TargetDoor.IsEmptyDoorway())
	{
		// start over again because the door isn't open or opening
		instantFail(ACT_GENERAL_FAILURE);
	}
	else
	{
		// make sure the throw grenade goal exists
		assert(CurrentThrowGrenadeGoal != None);

		if (CurrentThrowGrenadeGoal.bWaitToThrowGrenade)
		{
			CurrentThrowGrenadeGoal.NotifyThrowGrenade();
		}

		// pause and wait for the grenade to detonate
		pause();
	}
}

latent function FinishUpThrowBehavior()
{
	if (CurrentThrowGrenadeGoal != None)
	{
		while (! CurrentThrowGrenadeGoal.hasCompleted() && class'Pawn'.static.checkConscious(Thrower))
		{
			yield();
		}

		CurrentThrowGrenadeGoal.unPostGoal(self);
		CurrentThrowGrenadeGoal.Release();
		CurrentThrowGrenadeGoal = None;
	}
}

// overridden in subclasses
protected function TriggerThrowGrenadeMoveUpSpeech();

// if the thrower isn't the first or second officer, move them up to the first or second officer position
// if the thrower is the first officer but the door needs to be opened, make the thrower the second officer
protected latent function MoveUpThrower()
{
	local Pawn FirstOfficer, SecondOfficer, OriginalThrower;
	if (Thrower != None)
	{
		if (ShouldThrowerBeFirstOfficer())
		{
			if (Thrower != GetFirstOfficer())
			{
				TriggerThrowGrenadeMoveUpSpeech();

				OriginalThrower = Thrower;
				FirstOfficer    = GetFirstOfficer();

				SwapOfficerRoles(OriginalThrower, FirstOfficer);
				SwapStackUpPositions(OriginalThrower, FirstOfficer);
			}
		}
		else
		{
			if ((GetSecondOfficer() != None) && (Thrower != GetSecondOfficer()))
			{
				TriggerThrowGrenadeMoveUpSpeech();

				OriginalThrower = Thrower;
				SecondOfficer   = GetSecondOfficer();

				SwapOfficerRoles(OriginalThrower, SecondOfficer);	//(Thrower, Breacher)
				SwapStackUpPositions(OriginalThrower, SecondOfficer);
			}
		}
	}
}

protected function SwapOfficerRoles(Pawn OfficerA, Pawn OfficerB)
{
//	log("Before Swap - Leader: " $ Leader $ " Follower: " $ Follower $ " DoorOpener: " $ DoorOpener);

	if (OfficerA == Leader)
	{
		Leader = OfficerB;
	}
	else if (OfficerB == Leader)
	{
		Leader = OfficerA;
	}

	if (OfficerA == Follower)
	{
		Follower = OfficerB;
	}
	else if (OfficerB == Follower)
	{
		Follower = OfficerA;
	}

	if (OfficerA == DoorOpener)
	{
		DoorOpener = OfficerB;
	}
	else if (OfficerB == DoorOpener)
	{
		DoorOpener = OfficerA;
	}

	if (OfficerA == Breacher)
	{
		Breacher = OfficerB;
	}
	else if (OfficerB == Breacher)
	{
		Breacher = OfficerA;
	}

//	log("After Swap - Leader: " $ Leader $ " Follower: " $ Follower $ " DoorOpener: " $ DoorOpener);
}

latent function RemoveWedge()
{
	local Pawn Officer;
	local int i;

	assert(OfficersInStackUpOrder.Length > 0);
	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		if (class'Pawn'.static.checkConscious(OfficersInStackUpOrder[i]))
		{
			// we've found our officer
    		Officer = OfficersInStackUpOrder[i];
			break;
		}
	}

    if (Officer != None)
    {
	    CurrentRemoveWedgeGoal = new class'RemoveWedgeGoal'(AI_Resource(Officer.characterAI), TargetDoor);
	    assert(CurrentRemoveWedgeGoal != None);
	    CurrentRemoveWedgeGoal.AddRef();

	    CurrentRemoveWedgeGoal.postGoal(self);
	    WaitForGoal(CurrentRemoveWedgeGoal);
	    CurrentRemoveWedgeGoal.unPostGoal(self);

	    CurrentRemoveWedgeGoal.Release();
	    CurrentRemoveWedgeGoal = None;
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Move & Clear State Code

latent function WaitToFinishOpeningDoor()
{
//	log("WaitToFinishOpeningDoor - CurrentOpenDoorGoal: " $ CurrentOpenDoorGoal $ " hasCompleted: " $ CurrentOpenDoorGoal.hasCompleted());
	if ((CurrentOpenDoorGoal != None) && ! CurrentOpenDoorGoal.hasCompleted())
	{
		WaitForGoal(CurrentOpenDoorGoal);
	}
}

latent function OpenDoorForThrowingGrenade()
{
	// open the target door
	OpenTargetDoor(GetFirstOfficer());

//	log(GetFirstOfficer().Name $ " opening target door - IsFirstOfficerThrower: " $ IsFirstOfficerThrower());

	// if the first officer is also the thrower, wait until the door opens to throw the grenade
	// otherwise, start throwing as soon as the door starts opening
	if (IsFirstOfficerThrower())
	{
		WaitToFinishOpeningDoor();
	}
	else if (TargetDoor.IsClosed() && !TargetDoor.IsOpening() && !ISwatDoor(TargetDoor).IsBroken())
	{
		pause();
	}
}

// this function will be overridden to allow the squad to open the door,
// flashbang, gas, place charges, etc. (all the move & clear variances)
latent function PrepareToMoveSquad(optional bool bNoZuluCheck)
{
    local ISwatDoor SwatDoor;

    SwatDoor = ISwatDoor(TargetDoor);
    assert(SwatDoor != None);
    if (SwatDoor.IsWedged())
    {
        RemoveWedge();
    }

	if (!bNoZuluCheck)
	{
		WaitForZulu();
	}
}

function FindNumberOfClearPointsInClearingRoom()
{
	local int i;
	local name ClearingRoomName;

	ClearingRoomName = GetClearingRoomName();

	for(i=0; i<ClearPoints.Length; ++i)
	{
		if (ClearPoints[i].GetRoomName(None) == ClearingRoomName)
		{
			NumClearPointsInClearingRoom++;
		}
	}

	if (resource.pawn().logAI)
		log("NumClearPointsInClearingRoom is: " $ NumClearPointsInClearingRoom);
}

private function AddMoveAndClearGoalToList(Pawn Officer, ClearPoint Destination, bool bAnnounceClear)
{
	local int NextOpenMoveAndClearIndex;

	NextOpenMoveAndClearIndex = MoveAndClearGoals.Length;

	MoveAndClearGoals[NextOpenMoveAndClearIndex] = PostMoveAndClearGoalOnOfficer(Officer, Destination, bAnnounceClear);
	assert(MoveAndClearGoals[NextOpenMoveAndClearIndex] != None);
	MoveAndClearGoals[NextOpenMoveAndClearIndex].AddRef();
}

function MoveAndClearGoal PostMoveAndClearGoalOnOfficer(Pawn Officer, ClearPoint Destination, bool bAnnounceClear)
{
	local MoveAndClearGoal OfficerMoveAndClearGoal;

	assert(Officer != None);

	OfficerMoveAndClearGoal = new class'SwatAICommon.MoveAndClearGoal'(AI_CharacterResource(Officer.CharacterAI), Destination, CommandOrigin, bAnnounceClear);
	OfficerMoveAndClearGoal.postGoal( self );

	return OfficerMoveAndClearGoal;
}

function CreateClearFormation()
{
	assert(Leader != None);
	assert(Follower != None);

//	log("creating clear formation at time " $ resource.pawn().Level.TimeSeconds);

	assert(ClearFormation == None);
	ClearFormation = new class'Formation'(Leader);
	ClearFormation.AddRef();

	ClearFormation.AddMember(Follower);

	ISwatOfficer(Leader).SetCurrentFormation(ClearFormation);
	ISwatOfficer(Follower).SetCurrentFormation(ClearFormation);

	// post the formation goal on the follower (the leader uses a different goal)
	FollowerMoveInFormationGoal = new class'MoveInFormationGoal'(AI_MovementResource(Follower.MovementAI));
	assert(FollowerMoveInFormationGoal != None);
	FollowerMoveInFormationGoal.AddRef();

	FollowerMoveInFormationGoal.SetRotateTowardsPointsDuringMovement(true);
	FollowerMoveInFormationGoal.SetMoveToThresholds(FormationMoveToThreshold, FormationMoveToThreshold, FormationMoveToThreshold);
	FollowerMoveInFormationGoal.SetWalkThresholds(FormationWalkThreshold, FormationWalkThreshold, FormationWalkThreshold);

	FollowerMoveInFormationGoal.postGoal(self);
}

function StopFollowingLeader()
{
	// clear out the move in formation goal
	if (FollowerMoveInFormationGoal != None)
	{
		FollowerMoveInFormationGoal.unPostGoal(self);
		FollowerMoveInFormationGoal.Release();
		FollowerMoveInFormationGoal = None;
	}

	// clear out the formation
	if (ClearFormation != None)
	{
		ClearFormation.Cleanup();
		ClearFormation.Release();
		ClearFormation = None;
	}
}

protected function SetupOfficerRoles()
{
	local Pawn FirstOfficer, SecondOfficer;

	FirstOfficer = GetFirstOfficer();
	SecondOfficer = GetSecondOfficer();
	ThirdOfficer = GetThirdOfficer();
	FourthOfficer = GetFourthOfficer();

	if (FirstOfficer.logAI)
		log("SetupOfficerRoles - FirstOfficer: " $ FirstOfficer $ " SecondOfficer: " $ SecondOfficer $ " ThirdOfficer: " $ ThirdOfficer $ " FourthOfficer: " $ FourthOfficer);

	// the first officer could be the same as the second officer, if the original first officer died at some point
	// between when they stacked up and now, so set the second officer to the third or fourth officer if possible,
	// or just set them to none
	if (FirstOfficer == SecondOfficer)
	{
		if (ThirdOfficer != None)
		{
			SecondOfficer = ThirdOfficer;
			ThirdOfficer  = FourthOfficer;
		}
		else if (FourthOfficer != None)
		{
			SecondOfficer = FourthOfficer;
			FourthOfficer = None;
		}
		else
		{
			SecondOfficer = None;
		}
	}

	// the second officer could be the third or fourth officer, like if the officer at the second stack up point
	// dies between when they stacked up and now, so set the third or fourth officer to none if that's the case
	if (SecondOfficer == ThirdOfficer)
	{
		ThirdOfficer = None;
	}

	if (SecondOfficer == FourthOfficer)
	{
		FourthOfficer = None;
	}

	// ditto for the third and fourth officer
	if (ThirdOfficer == FourthOfficer)
	{
		FourthOfficer = None;
	}

	// everybody should be unique, catch problems here.
	assert(FirstOfficer != SecondOfficer);
	assert(FirstOfficer != ThirdOfficer);
	assert(FirstOfficer != FourthOfficer);
	assert((FourthOfficer == None) || (ThirdOfficer != FourthOfficer));
	assert((ThirdOfficer == None) || (SecondOfficer != ThirdOfficer));
	assert((FourthOfficer == None) || (SecondOfficer != FourthOfficer));


	// handle the case where the second officer doesn't exist
	if (SecondOfficer != None)
	{
		if (CanInteractWithTargetDoor())
		{
			// we have to have enough clear points on the other side
			if (NumClearPointsInClearingRoom >= 2)
			{
				Leader     = SecondOfficer;
				Follower   = FirstOfficer;
				DoorOpener = FirstOfficer;
			}
			else
			{
				Leader     = SecondOfficer;
				Follower   = None;
				DoorOpener = FirstOfficer;
			}
		}
		else
		{
			// we have to have enough clear points on the other side
			if (NumClearPointsInClearingRoom >= 2)
			{
				Leader     = FirstOfficer;
				Follower   = SecondOfficer;
			}
			else
			{
				Leader     = FirstOfficer;
				Follower   = None;
			}

			// just in case the door's status changes from open to closed
			DoorOpener = FirstOfficer;
		}
	}
	else
	{
		Leader     = FirstOfficer;
		DoorOpener = FirstOfficer;
	}

	SetBreacher();
	SetThrower();

	if (Leader.logAI)
		log("Leader is: " $ Leader $ " Follower is: " $ Follower);
}

// allows subclasses to set the thrower
protected function SetThrower();

// allows sublcasses to set the breacher
protected function SetBreacher(optional bool skipBreacher);

latent function MoveFirstTwoOfficersThroughDoor()
{
	// have the first officer open the door, if it's usable
	if (CanInteractWithTargetDoor())
	{
		OpenTargetDoor(DoorOpener);

		// wait for the door to start opening
		pause();

		// if the door was opened from the center (not the side), there are enough clear points to change rolls
		// we have the officers switch roles so the officer in front goes in first
		if (! CurrentOpenDoorGoal.WasOpenedFromSide())
		{
			WaitForGoal(CurrentOpenDoorGoal);

			if ((Follower != None) && (DoorOpener == Follower))
			{
				Follower = Leader;
				Leader   = DoorOpener;
			}
		}
		else
		{
			// wait a moment before rushing through the door
			sleep(DoorOpenedFromSideDelayTime);
		}

		ISwatDoor(TargetDoor).UnregisterInterestedInDoorOpening(self);
	}

	TriggerStartedClearingSpeech(Leader);

	// have the Leader move to the door
	if (! TargetDoor.IsEmptyDoorway())
	{
//		log("leader is moving to door at time " $ resource.pawn().Level.TimeSeconds);

		if ((Leader == Thrower) && (CurrentThrowGrenadeGoal != None) && !CurrentThrowGrenadeGoal.hasCompleted())
		{
			WaitForGoal(CurrentThrowGrenadeGoal);
		}

		LatentMoveOfficerToActor(Leader, TargetDoor, kMoveToDoorPriority);

//		log("leader finished moving to door at time " $ resource.pawn().Level.TimeSeconds);
	}

	// only create the clear formation if have a second officer
	if (Follower != None)
	{
		// create the clear formation to move through the door
		CreateClearFormation();
	}

	// have the leader move and clear to the second clear point, if he exists
	LeaderMoveAndClearGoal = PostMoveAndClearGoalOnOfficer(Leader, ClearPoints[kLeaderClearPointIndex], true);
	assert(LeaderMoveAndClearGoal != None);
	LeaderMoveAndClearGoal.AddRef();

	// if we have a follower, setup the distance sensor
	if (Follower != None)
	{
		// we're interested when they're on the other side of the door and 128 units away
		// setup a sensor to find out when that happens,
		// and wait until that happens before moving remainder of squad.
		LeaderDistanceSensor = DistanceSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceSensor', AI_Resource(Leader.characterAI), 0, 1000000 ));
		LeaderDistanceSensor.SetParameters(ISwatDoor(TargetDoor).GetMoveAndClearPauseThreshold(), TargetDoor);
	}

//	log("leader is now moving and clearing, follower is following at time " $ resource.pawn().Level.TimeSeconds);
}

private function MoveUpSecondTwoOfficers()
{
	local StackupPoint ThirdOfficerStackupPoint, FourthOfficerStackupPoint;

	ThirdOfficerStackupPoint  = StackupPoints[0];
	FourthOfficerStackupPoint = StackupPoints[1];

	if (ThirdOfficer != None)
	{
		RemoveStackedUpGoalOnOfficer(ThirdOfficer);

		ThirdOfficerStackUpGoal = new class'StackupGoal'(AI_Resource(ThirdOfficer.characterAI), ThirdOfficerStackupPoint);
		assert(ThirdOfficerStackUpGoal != None);
		ThirdOfficerStackUpGoal.AddRef();

		ThirdOfficerStackUpGoal.postGoal(self);
	}

	if (FourthOfficer != None)
	{
		RemoveStackedUpGoalOnOfficer(FourthOfficer);

		FourthOfficerStackUpGoal = new class'StackupGoal'(AI_Resource(FourthOfficer.characterAI), FourthOfficerStackupPoint);
		assert(FourthOfficerStackUpGoal != None);
		FourthOfficerStackUpGoal.AddRef();

		FourthOfficerStackUpGoal.postGoal(self);
	}
}

private function StartFollowerMoveAndClear()
{
	// this function can't be called without a follower
	assert(Follower != None);

	FollowerMoveAndClearGoal = PostMoveAndClearGoalOnOfficer(Follower, ClearPoints[kFollowerClearPointIndex], true);
	FollowerMoveAndClearGoal.AddRef();

	ActivateFollowingSensor();
}

private function PauseLeadingOfficer()
{
	StopLeadingOfficer();
	ISwatAI(Leader).AimAtActor(ClearPoints[kLeaderClearPointIndex]);

	// if there is a follower, stop him from following the leader and tell him to move and clear
	// he will move and clear until he reaches the threshold as well (using a separate sensor)
	if (Follower != None)
	{
		StopFollowingLeader();

//		log("follower told to move and clear, activated follower distance sensor at time " $ resource.pawn().Level.TimeSeconds);
	}
}

private function ActivateFollowingSensor()
{
	FollowerDistanceSensor = DistanceSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceSensor', AI_Resource(Follower.characterAI), 0, 1000000 ));
	FollowerDistanceSensor.SetParameters(ISwatDoor(TargetDoor).GetMoveAndClearPauseThreshold(), TargetDoor);
}

private function StopLeadingOfficer()
{
	LeaderMoveAndClearGoal.unPostGoal(self);
	LeaderMoveAndClearGoal.Release();
	LeaderMoveAndClearGoal = None;
}

private function PauseFollowingOfficer()
{
//	log("pausing follower at time: " $ resource.pawn().Level.TimeSeconds);

	if (Follower != None)
	{
		StopFollowingOfficer();
		ISwatAI(Follower).AimAtActor(ClearPoints[kFollowerClearPointIndex]);
	}
}

private function StopFollowingOfficer()
{
//	log("StopFollowingOfficer called");

	if (FollowerMoveAndClearGoal != None)
	{
		FollowerMoveAndClearGoal.unPostGoal(self);
		FollowerMoveAndClearGoal.Release();
		FollowerMoveAndClearGoal = None;
	}
}

latent private function MoveFirstTwoOfficersToClearPoints()
{
	AddMoveAndClearGoalToList(Leader, ClearPoints[kLeaderClearPointIndex], true);

	if (Follower != None)
	{
		AddMoveAndClearGoalToList(Follower, ClearPoints[kFollowerClearPointIndex], true);
	}
}

latent function MoveRemainingOfficersThroughDoor()
{
	local Pawn Officer;
	local int ClearPointIndex, PawnIterIndex;

	// if we're stacking up first, the remaining officers start with the third clear point
	// else we just start with the first clear point
	if (bShouldStackUpBeforeClearing)
	{
		ClearPointIndex = 2;
	}
	else
	{
		ClearPointIndex = 0;
	}

	// tell each officer that is moving to another room to move to their clear point
	for(PawnIterIndex=0; PawnIterIndex<squad().pawns.length; ++PawnIterIndex)
	{
		Officer = squad().pawns[PawnIterIndex];
		assert(Officer != None);

		// only deal with officers who aren't the leader or the follower
		if ((Officer != Leader) && (Officer != Follower))
		{
			if (!bShouldStackUpBeforeClearing || (Officer.GetRoomName() != ClearPoints[ClearPointIndex].GetRoomName(None)))
			{
				AddMoveAndClearGoalToList(Officer, ClearPoints[ClearPointIndex], true);
			}

			++ClearPointIndex;
		}
	}
}

function WaitForFirstTwoOfficersTimerCompleted()
{
//	log("WaitForFirstTwoOfficersTimerCompleted - isIdle: " $ isIdle() $ " at time " $ resource.pawn().Level.TimeSeconds);

	if (isIdle())
		runAction();
}

latent function WaitForFirstTwoOfficers()
{
	assert(WaitForFirstTwoOfficersTimer == None);

	StartWaitForFirstTwoOfficersTimer();

//	log("pausing at time to wait for the first two officers at time " $ resource.pawn().Level.TimeSeconds);

	// pause and wait until the second officer crosses the threshold, or the timer runs out
	pause();

//	log("pausing finished at time " $ resource.pawn().Level.TimeSeconds);

	ClearFirstTwoOfficersTimer();
	DeactivateDistanceSensors();
}

function StartWaitForFirstTwoOfficersTimer()
{
	WaitForFirstTwoOfficersTimer = Leader.Spawn(class'Timer');
	WaitForFirstTwoOfficersTimer.timerDelegate = WaitForFirstTwoOfficersTimerCompleted;
	WaitForFirstTwoOfficersTimer.startTimer(MaxWaitForFirstTwoOfficersTime, false);
}

function ClearFirstTwoOfficersTimer()
{
	if (WaitForFirstTwoOfficersTimer != None)
	{
		WaitForFirstTwoOfficersTimer.stopTimer();
		WaitForFirstTwoOfficersTimer.timerDelegate = None;
		WaitForFirstTwoOfficersTimer.Destroy();
		WaitForFirstTwoOfficersTimer = None;
	}
}

private function ClearSecondTwoOfficersMoveUpBehavior()
{
	if (ThirdOfficerStackUpGoal != None)
	{
		ThirdOfficerStackUpGoal.unPostGoal(self);
		ThirdOfficerStackUpGoal.Release();
		ThirdOfficerStackUpGoal = None;
	}

	if (FourthOfficerStackUpGoal != None)
	{
		FourthOfficerStackUpGoal.unPostGoal(self);
		FourthOfficerStackUpGoal.Release();
		FourthOfficerStackUpGoal = None;
	}
}

private function ActivateDoorSideSensors()
{
	// only move up the second two officers if there's enough clear points in the room we're clearing
	if (NumClearPointsInClearingRoom > 2)
	{
		LeaderDoorSideSensor = DoorSideSensor(class'AI_Sensor'.static.activateSensor( self, class'DoorSideSensor', AI_Resource(Leader.characterAI), 0, 1000000 ));
		LeaderDoorSideSensor.SetParameters(Leader, TargetDoor, !bClearingRoomIsOnRight);

		if (Follower != None)
		{
			FollowerDoorSideSensor = DoorSideSensor(class'AI_Sensor'.static.activateSensor( self, class'DoorSideSensor', AI_Resource(Leader.characterAI), 0, 1000000 ));
			FollowerDoorSideSensor.SetParameters(Follower, TargetDoor, !bClearingRoomIsOnRight);
		}
		else
		{
			bFollowerReachedOtherSide = true;
		}
	}
}

private function HandleDoorSideSensorMessage(AI_Sensor DoorSideSensor)
{
	if (DoorSideSensor == LeaderDoorSideSensor)
	{
		bLeaderReachedOtherSide = true;

		LeaderDoorSideSensor.deactivateSensor(self);
		LeaderDoorSideSensor = None;
	}
	else
	{
		assert(DoorSideSensor == FollowerDoorSideSensor);

		bFollowerReachedOtherSide = true;

		FollowerDoorSideSensor.deactivateSensor(self);
		FollowerDoorSideSensor = None;
	}

	// if both have reached the other side of the door, move up the second two officers
	if (bLeaderReachedOtherSide && bFollowerReachedOtherSide)
	{
		MoveUpSecondTwoOfficers();
	}
}

latent function MoveStackedUpSquad()
{
	// move the first two officers through the door
	MoveFirstTwoOfficersThroughDoor();

	// only pause if there is a follower
	if (Follower != None)
	{
		// so we move the second two officers up when the first two officers are in the room
		ActivateDoorSideSensors();

		// pause and wait for the officers to move through the door to the other side
		WaitForFirstTwoOfficers();

		// stop the second officer...
		PauseFollowingOfficer();

		// trigger the reached threshold speech
		TriggerReportedThresholdClearSpeech(Leader);

//		log("everyone is paused at time " $ resource.pawn().Level.TimeSeconds $ " continuing in " $ InitialClearPauseTime $ " seconds");

		// ...briefly...
		sleep(InitialClearPauseTime);

//		log("everyone is continuing at time " $ resource.pawn().Level.TimeSeconds);

		// trigger that we are continuing to clear speech
		TriggerReportedContinuingClear(Leader);

		// now move the first two officers...
		MoveFirstTwoOfficersToClearPoints();

		// clear out the stack up goals for the officers
		ClearSecondTwoOfficersMoveUpBehavior();

		// ...and move any remaining officers through the door...
		MoveRemainingOfficersThroughDoor();
	}
}

protected function name GetClearingRoomName()
{
	if (bClearingRoomIsOnRight)
		return ISwatDoor(TargetDoor).GetRightRoomName();
	else
		return ISwatDoor(TargetDoor).GetLeftRoomName();
}

protected function bool IsOfficerInRoomToClear(Pawn Officer)
{
	assert(class'Pawn'.static.checkConscious(Officer));

//	log("IsOfficerInRoomToClear - Officer.GetRoomName(): " $ Officer.GetRoomName() $ " GetClearingRoomName(): " $ GetClearingRoomName() $ " Officer.Anchor: " $ Officer.Anchor);

	if (Officer.GetRoomName() == GetClearingRoomName())
		return true;
	else
		return false;
}

// we stack up before clearing only when everyone is on the same side as the player
protected function bool ShouldStackUpBeforeClearing()
{
	return (!AreAnyOfficersInRoomToClear() || ShouldStackUpIfOfficersInRoomToClear());
}

// by default we return false, subclasses should override completely
protected function bool ShouldStackUpIfOfficersInRoomToClear() { return false; }

private function bool AreAnyOfficersInRoomToClear()
{
	local int i;
	local Pawn OfficerIter;

	for(i=0; i<squad().pawns.length; ++i)
	{
		OfficerIter = squad().pawns[i];

		if (IsOfficerInRoomToClear(OfficerIter))
		{
			return true;
		}
	}

	return false;
}

function bool IsFirstOfficerThrower()
{
	return (GetFirstOfficer() == Thrower);
}

function TriggerStartedClearingSpeech(Pawn Officer)
{
	ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerStartedClearingSpeech();
}

// we only announce clear threshold if everyone's assignment is none, dead, arrested, or compliant
private function bool ShouldAnnounceClearThreshold()
{
	local int i;
	local Pawn Officer, CurrentAssignment;

	for(i=0; i<squad().pawns.length; ++i)
	{
		Officer = squad().pawns[i];

		CurrentAssignment = ISwatOfficer(Officer).GetOfficerCommanderAction().GetCurrentAssignment();

		if ((CurrentAssignment != None) &&
			!ISwatAI(CurrentAssignment).IsCompliant() &&
			!ISwatAI(CurrentAssignment).IsArrested())
		{
			return false;
		}
	}

	return true;
}

function TriggerReportedThresholdClearSpeech(Pawn Officer)
{
	if (ShouldAnnounceClearThreshold())
	{
		ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerReportedThresholdClearSpeech();
	}
}

function TriggerReportedContinuingClear(Pawn Officer)
{
	if (GetNumberLivingOfficersInSquad() > 2)
	{
		ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerReportedContinuingClear2Plus();
	}
	else
	{
		ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerReportedContinuingClear2Minus();
	}
}

state Running
{
Begin:
	// stack up the squad if the door is closed (and not broken)
	if (bShouldStackUpBeforeClearing)
	{
		StackUpSquad(true);

		// set up who's doing what
		SetupOfficerRoles();

		PrepareToMoveSquad();			// <-- "WaitForZulu" happens in here

		FinishUpThrowBehavior();

		ClearOutStackedUpGoals();

		MoveStackedUpSquad();
	}
	else
	{
		TriggerStartedClearingSpeech(GetFirstOfficer());

		MoveRemainingOfficersThroughDoor();
	}

	if (resource.pawn().logAI)
		log("waiting for all goals - MoveAndClearGoals: " $ MoveAndClearGoals.Length);

	yield();

	// wait for everything to cleanup...
	WaitForAllGoalsInList(MoveAndClearGoals);

	log("move done");

	// ...then cleanup
	ClearOutMoveAndClearGoals();

	// Clean the restrain goals

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadMoveAndClearGoal'
}
