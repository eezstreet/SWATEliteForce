///////////////////////////////////////////////////////////////////////////////
// SquadDeployThrownItemAction.uc - SquadDeployThrownItemAction class
// this action is used to organize the Officer's deploy thrown item behavior

class SquadDeployThrownItemAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

import enum AIThrowSide from ISwatAI;
import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private ThrowGrenadeGoal		CurrentThrowGrenadeGoal;

var private MoveToActorGoal			CurrentMoveToActorGoal;
var protected Pawn					ThrowingOfficer;

// copied from our goal
var(parameters) EquipmentSlot		ThrownItemSlot;
var(parameters) vector				TargetThrowLocation;

// internal
var private Actor					ThrowFrom;

const kMinDistanceToTarget = 64.0;

///////////////////////////////////////////////////////////////////////////////
//
// Events

protected function TriggerDeployingGrenadeSpeech()
{
	switch(ThrownItemSlot)
	{
		case Slot_Flashbang:
			ISwatOfficer(ThrowingOfficer).GetOfficerSpeechManagerAction().TriggerDeployingFlashbangSpeech();
			break;

		case Slot_CSGasGrenade:
			ISwatOfficer(ThrowingOfficer).GetOfficerSpeechManagerAction().TriggerDeployingGasSpeech();
			break;

		case Slot_StingGrenade:
			ISwatOfficer(ThrowingOfficer).GetOfficerSpeechManagerAction().TriggerDeployingStingSpeech();
			break;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.Cleanup();

	if (CurrentThrowGrenadeGoal != None)
	{
		CurrentThrowGrenadeGoal.Release();
		CurrentThrowGrenadeGoal = None;
	}

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.ShouldStopMovingDelegate = None;

		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// Notifications

// handle officers dying during the behavior
protected function NotifyPawnDied(Pawn pawn)
{
	super.NotifyPawnDied(pawn);

	assert(pawn != None);

	// this will cause us to restart the behavior
	instantFail(ACT_GENERAL_FAILURE);
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
		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

latent function DeployThrownItem()
{
	local Pawn ThrowingOfficer;
	local NavigationPoint PointToThrowFrom;
	ThrowingOfficer = GetThrowingOfficer(ThrownItemSlot);

	if (ThrowingOfficer != None)
	{
		PointToThrowFrom = GetPointToThrowFromForOfficer(ThrowingOfficer);

		if (PointToThrowFrom != None)
		{
			MoveOfficerToThrowingPosition(ThrowingOfficer, PointToThrowFrom);	
			TriggerDeployingGrenadeSpeech();
			ThrowGrenadeAtTargetLocation(ThrowingOfficer, ThrownItemSlot);
		}
		else
		{
			ISwatOfficer(ThrowingOfficer).GetOfficerSpeechManagerAction().TriggerCantDeployThrownSpeech();

			instantSucceed();
		}
	}
	else
	{
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
	}
}

latent function MoveOfficerToThrowingPosition(Pawn Officer, NavigationPoint Destination)
{
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(AI_Resource(Officer.movementAI), 80, Destination);
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToActorGoal.SetShouldWalkEntireMove(false);

	// set the delegate for stopping movement
	CurrentMoveToActorGoal.ShouldStopMovingDelegate = CanThrowGrenade;

	// post the goal and wait for it to complete
	CurrentMoveToActorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.ShouldStopMovingDelegate = None;
	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

latent function ThrowGrenadeAtTargetLocation(Pawn Officer, EquipmentSlot ThrownItemSlot)
{
	CurrentThrowGrenadeGoal = new class'ThrowGrenadeGoal'(AI_Resource(Officer.characterAI), TargetThrowLocation, Officer.Location, ThrownItemSlot);
	assert(CurrentThrowGrenadeGoal != None);
	CurrentThrowGrenadeGoal.AddRef();

	CurrentThrowGrenadeGoal.SetThrowSide(kThrowFromCenter);

	CurrentThrowGrenadeGoal.postGoal(self);
	WaitForGoal(CurrentThrowGrenadeGoal);
	CurrentThrowGrenadeGoal.unPostGoal(self);

	CurrentThrowGrenadeGoal.Release();
	CurrentThrowGrenadeGoal = None;
}

// returns the closest conscious officer with a the particular type of grenade requested
function Pawn GetThrowingOfficer(EquipmentSlot ThrownItemSlot)
{
	local int i;
	local Pawn IterOfficer, ClosestOfficer;
	local float IterDistance, ClosestDistance;

	for(i=0; i<squad().pawns.length; ++i)
	{
		IterOfficer = squad().pawns[i];

		if (ISwatOfficer(IterOfficer).GetThrownWeapon(ThrownItemSlot) != None)
		{
			IterDistance = VSize(IterOfficer.Location - TargetThrowLocation);

			if ((ClosestOfficer == None) || (IterDistance < ClosestDistance))
			{
				ClosestOfficer  = IterOfficer;
				ClosestDistance = IterDistance;
			}
		}
	}

	return ClosestOfficer;
}	

private function bool CanOfficerThrowFromNavigationPoint(Pawn Officer, NavigationPoint Point)
{
	local bool bIsUnderhandThrow;
	local vector ThrowOrigin;
	local rotator ThrowOrientation;

	assert(Point != None);
	assert(class'Pawn'.static.checkConscious(Officer));

	bIsUnderhandThrow = ISwatAI(Officer).IsUnderhandThrow(Point.Location, TargetThrowLocation);
	ThrowOrientation  = rotator(TargetThrowLocation - Point.Location);
	ThrowOrigin       = Point.Location + ISwatAI(Officer).GetThrowOriginOffset(bIsUnderhandThrow, ThrowOrientation);

	return CanThrowGrenadeFromPoint(Officer, ThrowOrigin);
}

private latent function NavigationPoint GetPointToThrowFromForOfficer(Pawn Officer)
{
	local NavigationPointList PointsInOfficersRoom, PointsInPlayersRoom;
	local int i;
	local NavigationPoint Iter;
	local name OfficerRoomName, PlayerRoomName;
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(Officer.Level.AIRepo);
	assert(SwatAIRepo != None);

	// first, see if we can find any navigation points in the room we're in that can hit the target point
	OfficerRoomName      = Officer.GetRoomName();
	PointsInOfficersRoom = SwatAIRepo.GetRoomNavigationPoints(OfficerRoomName);

	for(i=0; i<PointsInOfficersRoom.GetSize(); ++i)
	{
		Iter = PointsInOfficersRoom.GetEntryAt(i);

		if (CanOfficerThrowFromNavigationPoint(Officer, Iter))
			return Iter;
	}

	// wait a tick before testing the points in the player's room
	yield();

	// now try to see if we can find any navigation points in the room the player gave the command from (if it's different from the officer's room)
	PlayerRoomName      = SwatAIRepo.GetClosestRoomNameToPoint(CommandOrigin, CommandGiver);
	yield();

	if (PlayerRoomName != OfficerRoomName)
	{
		PointsInPlayersRoom = SwatAIRepo.GetRoomNavigationPoints(PlayerRoomName);

		for(i=0; i<PointsInPlayersRoom.GetSize(); ++i)
		{
			Iter = PointsInPlayersRoom.GetEntryAt(i);

			if (CanOfficerThrowFromNavigationPoint(Officer, Iter))
				return Iter;
		}
	}

	return None;
}

function vector GetThrowMidpoint(Pawn Officer, vector ThrowOrigin)
{
	local vector ThrowMidpoint;

	ThrowMidpoint    = (TargetThrowLocation - ThrowOrigin) / 2.0;
	ThrowMidpoint.Z += VSize(ThrowMidPoint) * sin(ISwatAI(Officer).GetThrowAngle());

//	log("ThrowOrigin: " $ ThrowOrigin $ " TargetThrowLocation: " $ TargetThrowLocation $ " ThrowMidPoint: " $ ThrowOrigin + ThrowMidPoint);

	return ThrowOrigin + ThrowMidPoint;
}

private function bool TraceToThrowGrenade(Pawn Officer, vector Start, vector End, bool bUseExtent)
{
	local vector HitLocation, HitNormal;
	local Actor HitActor;

//	Officer.Level.GetLocalPlayerController().myHUD.AddDebugLine(Start, End, class'Engine.Canvas'.Static.MakeColor(255,200,200));

	if (bUseExtent)
	{
		HitActor = Officer.Trace(HitLocation, HitNormal, End, Start, true, vect(10.0,10.0,10.0),,,,true);

		return ((HitActor == None) || (VSize(HitLocation - TargetThrowLocation) <= kMinDistanceToTarget));
	}
	else
	{
		HitActor = Officer.Trace(HitLocation, HitNormal, End, Start, true,,,,,true);

		return (HitActor == None);
	}
}

function bool CanThrowGrenadeFromPoint(Pawn Officer, vector ThrowOrigin)
{
	local vector ThrowMidPoint;

	ThrowMidPoint = GetThrowMidpoint(Officer, ThrowOrigin);

	return (TraceToThrowGrenade(Officer, ThrowOrigin, ThrowMidPoint, false) && 
		    TraceToThrowGrenade(Officer, ThrowMidPoint, TargetThrowLocation, false) &&
			TraceToThrowGrenade(Officer, ThrowOrigin, ThrowMidPoint, true) && 
		    TraceToThrowGrenade(Officer, ThrowMidPoint, TargetThrowLocation, true));
}

function bool CanThrowGrenade(Pawn MovingPawn)
{
	local vector ThrowOrigin;
	local rotator ThrowOrientation;
	local bool bIsUnderhandThrow;

	bIsUnderhandThrow = ISwatAI(MovingPawn).IsUnderhandThrowTo(TargetThrowLocation);
	ThrowOrientation  = rotator(TargetThrowLocation - MovingPawn.Location);
	ThrowOrigin       = ISwatAI(MovingPawn).GetThrowOrigin(bIsUnderhandThrow, ThrowOrientation);
	
	return CanThrowGrenadeFromPoint(MovingPawn, ThrowOrigin);
}

state Running
{
Begin:
	WaitForZulu();

	DeployThrownItem();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadDeployThrownItemGoal'
}