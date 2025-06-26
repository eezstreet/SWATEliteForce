///////////////////////////////////////////////////////////////////////////////
// BarricadeAction.uc - BarricadeAction class
// The Action that causes the AI to barricade

class BarricadeAction extends SuspiciousAction;
///////////////////////////////////////////////////////////////////////////////

const kMinAimAroundTime = 1.5;
const kMaxAimAroundTime = 4.0;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) vector			StimuliOrigin;
var(parameters) bool			bDelayBarricade;
var(parameters) bool			bCanCloseDoors;

// behaviors we use
var private AimAroundGoal		CurrentAimAroundGoal;
var private MoveToActorGoal		CurrentMoveToActorGoal;
var private CloseDoorGoal		CurrentCloseDoorGoal;
var private MoveToDoorGoal		CurrentMoveToDoorGoal;
var private AttackTargetGoal	AttackDoorGoal;
var private AimAtTargetGoal		CurrentAimAtTargetGoal;

// domain data
var private array<Door>			DoorsInRoom;
var private array<Door>			ClosableDoorsInRoom;
var private NavigationPoint		BarricadePoint;
var private Door				DoorOpening;

// sensors we use
var private DoorOpeningSensor	DoorOpeningSensor;

// config variables
var config float				ShootAtDoorsChance;
var config float				MinShootingAtDoorsTime;
var config float				MaxShootingAtDoorsTime;

var config float				CloseAndLockInitialDoorChance;
var config float				CloseAndLockSubsequentDoorChance;

var config float				MinBarricadeDelayTime;
var config float				MaxBarricadeDelayTime;

var config float				ReactionSpeechChance;
var config float				OtherReactionSpeechChance;
var config float				CrouchAtFleePointChance;
var config float				AimAtClosestDoorTime;

var config float				MinTimeBeforeClosingDoor;
var config float				MaxTimeBeforeClosingDoor;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	// unclaim our flee point
	if ((BarricadePoint != None) && BarricadePoint.IsA('FleePoint'))
	{
		if (FleePoint(BarricadePoint).GetFleePointUser() == m_Pawn)
		{
			FleePoint(BarricadePoint).UnclaimPoint();
		}
	}

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentCloseDoorGoal != None)
	{
		CurrentCloseDoorGoal.Release();
		CurrentCloseDoorGoal = None;
	}

	if (CurrentMoveToDoorGoal != None)
	{
		CurrentMoveToDoorGoal.Release();
		CurrentMoveToDoorGoal = None;
	}

	if (AttackDoorGoal != None)
	{
		AttackDoorGoal.Release();
		AttackDoorGoal = None;
	}

	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}

	if (DoorOpeningSensor != None)
	{
		DoorOpeningSensor.deactivateSensor(self);
		DoorOpeningSensor = None;
	}

	// if we were crouched, get up.
	if (m_Pawn.bIsCrouched)
	{
		m_Pawn.ShouldCrouch(false);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log("barricading - goal " $ goal.NAme $ " failed");

	instantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor notifications

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	super.OnSensorMessage(sensor, value, userData);

	if (sensor == DoorOpeningSensor)
	{
		if (m_Pawn.logAI)
			log(m_Pawn.Name $ " noticed a door opening.");

		// it better be a door!
		assert(value.objectData.IsA('Door'));

		if (isIdle())
		{
			DoorOpening = Door(value.objectData);
			runAction();
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function FindBarricadePoint()
{
	local name RoomName;

	RoomName = m_Pawn.GetRoomName();

	if(RoomName == '')
	{
		// This can cause errors!
		return;
	}

	// find our anchor, and check if it's a flee point
	m_Pawn.FindAnchor(true);

	if ((m_Pawn.Anchor != None) && m_Pawn.Anchor.IsA('FleePoint') &&
		((FleePoint(m_Pawn.Anchor).GetFleePointUser() == None) || (FleePoint(m_Pawn.Anchor).GetFleePointUser() == m_Pawn)))
	{
		BarricadePoint = Pawn.Anchor;
	}
	else
	{
		BarricadePoint = SwatAIRepository(m_Pawn.Level.AIRepo).FindUnclaimedFleePointInRoom(RoomName);

		// if we didn't find an unclaimed flee point, just use a random PathNode in the room
		if (BarricadePoint == None)
		{
			BarricadePoint = SwatAIRepository(m_Pawn.Level.AIRepo).FindRandomPointInRoom(RoomName, 'PathNode');
		}
	}

    AssertWithDescription((BarricadePoint != None), "AI:"@m_Pawn@" has no FleePoints in the room he is in (\""$RoomName$"\") to barricade himself!  Add Flee Points to this room!");

	// take this point over so nobody else tries to use it
	if (BarricadePoint.IsA('FleePoint'))
	{
		FleePoint(BarricadePoint).ClaimPoint(m_Pawn);
	}
}

latent function MoveToBarricadePoint()
{
    if (BarricadePoint != None)
    {
        CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, BarricadePoint);
        assert(CurrentMoveToActorGoal != None);
		CurrentMoveToActorGoal.AddRef();

		CurrentMoveToActorGoal.SetRotateTowardsFirstPoint(true);
		CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
		CurrentMoveToActorGoal.SetWalkThreshold(0.0);

        // post the move to goal and wait for it to complete
        CurrentMoveToActorGoal.postGoal(self);
        WaitForGoal(CurrentMoveToActorGoal);

        // remove and destroy the move to goal
        CurrentMoveToActorGoal.unPostGoal(self);
		CurrentMoveToActorGoal.Release();
        CurrentMoveToActorGoal = None;
    }
}

private function bool ShouldCrouchAtFleePoint()
{
	local FleePoint BarricadeFleePoint;
	if (BarricadePoint != None)
	{
		BarricadeFleePoint = FleePoint(BarricadePoint);
		if ((BarricadeFleePoint != None) && BarricadeFleePoint.ShouldCrouchAtPoint && (FRand() <= CrouchAtFleePointChance))
		{
			return true;
		}
	}

	return false;
}

latent function AimAround()
{
    CurrentAimAroundGoal = new class'AimAroundGoal'(weaponResource(), kMinAimAroundTime, kMaxAimAroundTime);
    assert(CurrentAimAroundGoal != None);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.SetAimInnerFovDegrees(180.0);
	CurrentAimAroundGoal.SetAimOuterFovDegrees(360.0);
	CurrentAimAroundGoal.SetExtraDoorWeight(0.333);
	CurrentAimAroundGoal.SetAimWeapon(true);

    CurrentAimAroundGoal.postGoal(self);
}


private function PopulateDoorsInRoom()
{
	local NavigationPointList DoorPointsInRoom;
	local SwatAIRepository SwatAIRepo;
	local int i;
	local Door IterDoor;
	local ISwatDoor IterSwatDoor;
	local Name RoomName;

	RoomName = BarricadePoint.GetRoomName(m_Pawn);

	if(RoomName == '')
	{
		return;	// no room ... don't crash!
	}

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

	DoorPointsInRoom = SwatAIRepo.GetRoomNavigationPointsOfType(RoomName, 'Door');

	for(i=0; i<DoorPointsInRoom.GetSize(); ++i)
	{
		IterDoor     = Door(DoorPointsInRoom.GetEntryAt(i));
		assert(IterDoor != None);
		IterSwatDoor = ISwatDoor(IterDoor);
		assert(IterSwatDoor != None);

		DoorsInRoom[DoorsInRoom.Length] = IterDoor;

		// if there's a door that isn't broken, isn't locked, and isn't opening,
		// we consider the door usable
		if (!IterDoor.IsEmptyDoorWay() && !IterSwatDoor.IsBroken() && !IterDoor.IsOpening() && !IterDoor.IsClosing() && !IterSwatDoor.IsLocked())
		{
			ClosableDoorsInRoom[ClosableDoorsInRoom.Length] = IterDoor;
		}
	}

	SwatAIRepo.ReleaseNavigationPointList(DoorPointsInRoom);
}

private function bool DoesRoomHaveDoorsToCloseAndLock()
{
	return (ClosableDoorsInRoom.Length > 0);
}

private function Door GetClosestDoorToStimuliOrigin()
{
	local int i;
	local Door ClosestDoor, IterDoor;
	local float ClosestDistance, IterDistance;

	for(i=0; i<DoorsInRoom.Length; ++i)
	{
		IterDoor     = DoorsInRoom[i];
		IterDistance = VSize2D(IterDoor.Location - StimuliOrigin);

		if ((ClosestDoor == None) || (IterDistance < ClosestDistance))
		{
			ClosestDoor     = IterDoor;
			ClosestDistance = IterDistance;
		}
	}

	return ClosestDoor;
}

private function Door GetClosestClosableDoorToStimuliOrigin()
{
	local int i;
	local Door ClosestDoor, IterDoor;
	local float ClosestDistance, IterDistance;

	for(i=0; i<ClosableDoorsInRoom.Length; ++i)
	{
		IterDoor     = ClosableDoorsInRoom[i];
		IterDistance = VSize2D(IterDoor.Location - StimuliOrigin);

		if ((ClosestDoor == None) || (IterDistance < ClosestDistance))
		{
			ClosestDoor     = IterDoor;
			ClosestDistance = IterDistance;
		}
	}

	return ClosestDoor;
}

private function RemoveDoorFromCloseAndLockList(Door DoorToRemove)
{
	local int i;

	for(i=0; i<ClosableDoorsInRoom.Length; ++i)
	{
		if (ClosableDoorsInRoom[i] == DoorToRemove)
		{
			ClosableDoorsInRoom.Remove(i, 1);
			break;
		}
	}
}

latent function AimAtClosestDoor()
{
	local Door ClosestDoor;

	ClosestDoor = GetClosestDoorToStimuliOrigin();

//	log("ClosestDoor is: " $ ClosestDoor $ " Can hit ClosestDoor: " $ m_Pawn.CanHit(ClosestDoor));

	if ((ClosestDoor != None) && m_Pawn.CanHitTarget(ClosestDoor))
	{
		RemoveAimAroundGoal();

		CurrentAimAtTargetGoal = new class'AimAtTargetGoal'(weaponResource(), achievingGoal.priority, ClosestDoor);
		assert(CurrentAimAtTargetGoal != None);
		CurrentAimAtTargetGoal.AddRef();

		CurrentAimAtTargetGoal.SetAimOnlyWhenCanHitTarget(true);
		CurrentAimAtTargetGoal.SetAimWeapon(true);
		CurrentAimAtTargetGoal.SetShouldFinishOnSuccess(true);

		CurrentAimAtTargetGoal.postGoal(self);
		sleep(AimAtClosestDoorTime);
		CurrentAimAtTargetGoal.unPostGoal(self);

		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}
}

latent function CloseDoor(Door TargetDoor)
{
	if (ISwatDoor(TargetDoor).IsOpen())
	{
		assert(CurrentCloseDoorGoal	== None);

		CurrentCloseDoorGoal = new class'CloseDoorGoal'(movementResource(), achievingGoal.priority, TargetDoor);
		assert(CurrentCloseDoorGoal != None);
		CurrentCloseDoorGoal.AddRef();

		CurrentCloseDoorGoal.SetRotateTowardsFirstPoint(true);
		CurrentCloseDoorGoal.SetRotateTowardsPointsDuringMovement(true);
		CurrentCloseDoorGoal.SetShouldWalkEntireMove(false);
		CurrentCloseDoorGoal.SetWalkThreshold(0.0);

		CurrentCloseDoorGoal.postGoal(self);
		WaitForGoal(CurrentCloseDoorGoal);
		CurrentCloseDoorGoal.unPostGoal(self);

		CurrentCloseDoorGoal.Release();
		CurrentCloseDoorGoal = None;
	}
}

latent function LockDoor(Door TargetDoor)
{
	if (ISwatDoor(TargetDoor).CanBeLocked() && !ISwatDoor(TargetDoor).IsLocked())
	{
		CurrentMoveToDoorGoal = new class'MoveToDoorGoal'(movementResource(), TargetDoor);
		assert(CurrentMoveToDoorGoal != None);
		CurrentMoveToDoorGoal.AddRef();

		CurrentMoveToDoorGoal.SetRotateTowardsFirstPoint(true);
		CurrentMoveToDoorGoal.SetRotateTowardsPointsDuringMovement(true);
		CurrentMoveToDoorGoal.SetShouldWalkEntireMove(false);
		CurrentMoveToDoorGoal.SetWalkThreshold(0.0);

		CurrentMoveToDoorGoal.postGoal(self);
		// trigger the other (unused) barricade speech based on a die roll
		if (FRand() < OtherReactionSpeechChance)
		{
			ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerBarricadeSpeech();
		}
		WaitForGoal(CurrentMoveToDoorGoal);
		CurrentMoveToDoorGoal.unPostGoal(self);

		CurrentMoveToDoorGoal.Release();
		CurrentMoveToDoorGoal = None;

		// now lock the door (no animations)
		// just make sure the door is locked again before calling this (in case something has changed)
		if (ISwatDoor(TargetDoor).CanBeLocked())
		{
			ISwatDoor(TargetDoor).Lock();
		}
	}
}

latent function CloseAndLockDoorsInRoom()
{
	local Door CurrentDoor;

	// only close and lock doors if the die roll is successful
	if (FRand() < CloseAndLockInitialDoorChance)
	{
		while (ClosableDoorsInRoom.Length > 0)
		{
			CurrentDoor = GetClosestDoorToStimuliOrigin();
			RemoveDoorFromCloseAndLockList(CurrentDoor);

            if(ISwatDoor(CurrentDoor).IsOpen() && !ISwatDoor(CurrentDoor).IsLocked())
            { // it's possible for another AI to have locked and closed the door in the meantime
             CloseDoor(CurrentDoor);
			 LockDoor(CurrentDoor);
            }

			// check to see the chance we will close and lock subsequent doors (another die roll)
			if (FRand() > CloseAndLockSubsequentDoorChance)
			{
				break;
			}
		}
	}
}

function CreateDoorOpeningSensor()
{
	local int i;

	if (ClosableDoorsInRoom.Length > 0)
	{
		DoorOpeningSensor = DoorOpeningSensor(class'AI_Sensor'.static.activateSensor(self, class'DoorOpeningSensor', characterResource(), 0, 1000000));
		assert(DoorOpeningSensor != None);

		for(i=0; i<ClosableDoorsInRoom.Length; ++i)
		{
			DoorOpeningSensor.AddDoor(ClosableDoorsInRoom[i]);
		}
	}
}

function RemoveAimAroundGoal()
{
	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.unPostGoal(self);
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}
}

latent function ShootAtOpeningDoor()
{
	local float EndShootingTime;
	assert(AttackDoorGoal == None);
	assert(DoorOpening != None);

	AttackDoorGoal = new class'AttackTargetGoal'(weaponResource(), DoorOpening);
	assert(AttackDoorGoal != None);
	AttackDoorGoal.AddRef();
	AttackDoorGoal.SetSuppressiveFire(true);

	AttackDoorGoal.postGoal(self);
	// do some speech
	ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerDoorOpeningSpeech();
	if (m_Pawn.IsA('SwatEnemy') && !ISwatEnemy(m_Pawn).IsAThreat())
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
	}

	EndShootingTime = Level.TimeSeconds + RandRange(MinShootingAtDoorsTime, MaxShootingAtDoorsTime);

	while ((Level.TimeSeconds < EndShootingTime) && m_Pawn.CanHitTarget(DoorOpening))
	{
		yield();
	}

	AttackDoorGoal.unPostGoal(self);
	AttackDoorGoal.Release();
	AttackDoorGoal = None;

	ISwatEnemy(m_Pawn).UnbecomeAThreat();
}

private latent function AimAtOpeningDoor()
{
	assert(DoorOpening != None);

	CurrentAimAtTargetGoal = new class'AimAtTargetGoal'(weaponResource(), DoorOpening);
	assert(CurrentAimAtTargetGoal != None);
	CurrentAimAtTargetGoal.AddRef();

	CurrentAimAtTargetGoal.SetAimOnlyWhenCanHitTarget(true);

	CurrentAimAtTargetGoal.postGoal(self);

	while (DoorOpening.IsOpening())
		yield();

	CurrentAimAtTargetGoal.unPostGoal(self);
	CurrentAimAtTargetGoal.Release();
	CurrentAimAtTargetGoal = None;
}

private latent function CloseOpenedDoor()
{
	CloseDoor(DoorOpening);
	LockDoor(DoorOpening);
}

state Running
{
Begin:
	while(! resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
		yield();

	useResources(class'AI_Resource'.const.RU_LEGS);

	FindBarricadePoint();
	PopulateDoorsInRoom();
	AimAtClosestDoor();

	useResources(class'AI_Resource'.const.RU_ARMS);

	if (bDelayBarricade)
	{
		sleep(RandRange(MinBarricadeDelayTime, MaxBarricadeDelayTime));
	}

	CheckWeaponStatus();

	// clear the dummy  movement goal so we can move to close and lock doors,
	// as well as to move to the flee point in the room
	ClearDummyMovementGoal();

	CreateDoorOpeningSensor();

	if (bCanCloseDoors && DoesRoomHaveDoorsToCloseAndLock())
	{
		CloseAndLockDoorsInRoom();
	}

GetInPosition:
    MoveToBarricadePoint();

	useResources(class'AI_Resource'.const.RU_LEGS);

	ClearDummyWeaponGoal();
	AimAround();

	// trigger the barricade speech based on a die roll
	if (FRand() < ReactionSpeechChance)
	{
		ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerBarricadingSpeech();
	}

	// crouch if we're supposed to
	if (ShouldCrouchAtFleePoint())
	{
		m_Pawn.ShouldCrouch(true);
	}

	// wait for a door to start opening, if that ever happens
	pause();

	if (m_Pawn.CanHitTarget(DoorOpening))
	{
		RemoveAimAroundGoal();

		if ((FRand() < ShootAtDoorsChance) && !m_Pawn.IsA('SwatUndercover'))
		{
			ShootAtOpeningDoor();
		}
		else
		{
			// aim at the door while it's opening
			AimAtOpeningDoor();
		}

		// clear the dummy  movement goal so we can move to close and lock doors,
		// as well as to move to the flee point in the room
		ClearDummyMovementGoal();

		CloseOpenedDoor();

		goto 'GetInPosition';
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'BarricadeGoal'
}
