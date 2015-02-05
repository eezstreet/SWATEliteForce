///////////////////////////////////////////////////////////////////////////////
// OfficerTeamInfo.uc - the OfficerTeamInfo class
// this is the base class of all squads for the Officer AI

class OfficerTeamInfo extends AICommon.SquadInfo
	native;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var	SwatAIRepository			SwatAIRepo;
var protected SquadCommandGoal	CurrentSquadCommandGoal;
var bool						bHoldCommand;			// wait for "zulu" command before completing action

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

event PostBeginPlay()
{
	// have to call this before calling InitAbilities because the SquadAI 
	// is created in a parent class
	Super.PostBeginPlay();

	InitAbilities();
}

// add all of our abilities to the Squad Resource -- subclasses should call down the chain
protected function InitAbilities()
{
	SquadAI.addAbility( new class'SquadMirrorCornerAction' );
	SquadAI.addAbility( new class'SquadMirrorDoorAction' );
	SquadAI.addAbility( new class'SquadCloseDoorAction' );
	SquadAI.addAbility( new class'SquadFallInAction' );
	SquadAI.addAbility( new class'SquadStackUpAction' );
	SquadAI.addAbility( new class'SquadStackUpAndTryDoorAction' );
	SquadAI.addAbility( new class'SquadMoveAndClearAction' );
	SquadAI.addAbility( new class'SquadBangAndClearAction' );
	SquadAI.addAbility( new class'SquadGasAndClearAction' );
	SquadAI.addAbility( new class'SquadStingAndClearAction' );
	SquadAI.addAbility( new class'SquadBreachAndClearAction' );
	SquadAI.addAbility( new class'SquadBreachBangAndClearAction' );
	SquadAI.addAbility( new class'SquadBreachGasAndClearAction' );
	SquadAI.addAbility( new class'SquadBreachStingAndClearAction' );
	SquadAI.addAbility( new class'SquadDeployThrownItemAction' );
	SquadAI.addAbility( new class'SquadExamineAndReportAction' );
	SquadAI.addAbility( new class'SquadPickLockAction' );
	SquadAI.addAbility( new class'SquadPlaceWedgeAction' );
	SquadAI.addAbility( new class'SquadRemoveWedgeAction' );
	SquadAI.addAbility( new class'SquadDeployC2Action' );
	SquadAI.addAbility( new class'SquadSecureAction' );
	//SquadAI.addAbility( new class'SquadReportAction' );
	SquadAI.addAbility( new class'SquadDeployTaserAction' );
	SquadAI.addAbility( new class'SquadDeployPepperSprayAction' );
	SquadAI.addAbility( new class'SquadDisableTargetAction' );
	SquadAI.addAbility( new class'SquadMoveToAction' );
	SquadAI.addAbility( new class'SquadCoverAction' );
	SquadAI.addAbility( new class'SquadDeployShotgunAction' );
	SquadAI.addAbility( new class'SquadDeployLessLethalShotgunAction' );
	SquadAI.addAbility( new class'SquadDeployGrenadeLauncherAction' );
	SquadAI.addAbility( new class'SquadDeployThrownItemThroughDoorAction' );
	SquadAI.addAbility( new class'SquadDeployPepperBallAction' );
	SquadAI.addAbility( new class'SquadDeployLightstickAction' );
}

///////////////////////////////////////////////////////////////////////////////
//
// Destruction

function Destroyed()
{
	super.Destroyed();

	if (CurrentSquadCommandGoal != None)
	{
		CurrentSquadCommandGoal.Release();
		CurrentSquadCommandGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

event function AI_SquadResource GetSquadAI()
{
	return AI_SquadResource(SquadAI);
}

// i'm not even going to make a "SWAT" movie reference here...
function bool IsOfficerOnTeam(Pawn Officer)
{
	local int i;

	assert(Officer != None);

	for(i=0; i<pawns.length; ++i)
	{
		if (pawns[i] == Officer)
		{
			return true;
		}
	}

	return false;
}

function bool IsMovingAndClearing()
{
	return ((CurrentSquadCommandGoal != None) && CurrentSquadCommandGoal.IsA('SquadMoveAndClearGoal') && !CurrentSquadCommandGoal.hasCompleted());
}

// is this squad (or in the case of the element, any of the subsquads) currently waiting for a "zulu" command?
event bool IsHoldingCommand()
{
	if (self == SwatAIRepo.GetElementSquad())
		return SwatAIRepo.GetBlueSquad().bHoldCommand || SwatAIRepo.GetRedSquad().bHoldCommand;
	else
		return bHoldCommand;
}

function name GetRoomNameToClear()
{
	// you shouldn't call this function without testing IsMovingAndClearing first!
	assert(IsMovingAndClearing());

	return SquadMoveAndClearGoal(CurrentSquadCommandGoal).GetRoomNameToClear();
}

function Pawn GetFirstOfficer()
{
	if (pawns.length > 0)
		return pawns[0];
	else
		return None;
}

function Pawn GetSecondOfficer()
{
	if (pawns.length > 1)
		return pawns[1];
	else
		return None;
}

function Pawn GetClosestOfficerWithEquipmentTo(EquipmentSlot Slot, vector Point)
{
	local int i;
	local Pawn IterOfficer, ClosestOfficer;
	local float IterDistance, ClosestDistance;
	for(i=0; i<pawns.length; ++i)
	{
		IterOfficer = pawns[i];

		if (ISwatOfficer(IterOfficer).GetItemAtSlot(Slot) != None)
		{
			if (IterOfficer.FastTrace(Point, IterOfficer.Location))
			{
				IterDistance = VSize(Point - IterOfficer.Location);
			}
			else
			{
				IterDistance = IterOfficer.GetPathfindingDistanceToPoint(Point, true);
			}

			if ((ClosestOfficer == None) || (IterDistance < ClosestDistance))
			{
				ClosestOfficer  = IterOfficer;
				ClosestDistance = IterDistance;
			}
		}
	}

	return ClosestOfficer;
}

function Pawn GetClosestOfficerTo(Actor Target, optional bool bRequiresLineOfSight, optional bool bUsePathfindingDistance)
{
	local int i;
	local Pawn Iter, Closest;
	local float IterDistance, ClosestDistance;

	for (i=0; i<pawns.length; ++i)
	{
		Iter = pawns[i];

		if (!bRequiresLineOfSight || Iter.LineOfSightTo(Target))
		{
			if (bUsePathfindingDistance)
			{
				IterDistance = Iter.GetPathfindingDistanceToActor(Target);
			}

			// use LOS distance if were supposed to,
			// or if pathfinding distance failed (by returning 0.0) use the line of sight distance instead
			if (!bUsePathfindingDistance || ((IterDistance == 0.0) && (Target != Iter)))
			{
				IterDistance = VSize(Target.Location - Iter.Location);
			}

			if ((Closest == None) || (IterDistance < ClosestDistance))
			{
				Closest			= Iter;
				ClosestDistance = IterDistance;
			}
		}
	}

	return Closest;
}

function Pawn GetClosestOfficerThatCanHit(Actor Target)
{
	local int i;
	local Pawn Iter, Closest;
	local float IterDistance, ClosestDistance;

	for (i=0; i<pawns.length; ++i)
	{
		Iter = pawns[i];

		if (Iter.CanHit(Target))
		{
			IterDistance = VSize(Target.Location - Iter.Location);

			if ((Closest == None) || (IterDistance < ClosestDistance))
			{
				Closest			= Iter;
				ClosestDistance = IterDistance;
			}
		}
	}

	return Closest;
}

function Pawn GetClosestOfficerWithEquipment(vector Location, EquipmentSlot Slot, optional Name EquipmentClassName)
{
	local int i;
	local Pawn Iter, Closest;
	local float IterDistance, ClosestDistance;
    local HandheldEquipment Equipment;

	for (i=0; i<pawns.length; ++i)
	{
		Iter = pawns[i];

        Equipment = ISwatOfficer(Iter).GetItemAtSlot(Slot);
		if (Equipment != None)
        {
            // If no class name was supplied, or if the equipment is of
            // the supplied class name's type, then this officer has the
            // equipment
            if (EquipmentClassName == '' || Equipment.IsA(EquipmentClassName))
            {
			    IterDistance = VSize(Location - Iter.Location);

			    if ((Closest == None) || (IterDistance < ClosestDistance))
			    {
				    Closest			= Iter;
				    ClosestDistance = IterDistance;
			    }
            }
        }
	}

	return Closest;
}

///////////////////////////////////////////////////////////////////////////////
//
// Officer Command Queries

function bool HasActiveMembers()
{
	return GetSquadAI().hasActiveMembers();
}

function bool CanExecuteCommand()
{
	// if we don't have any active members, we can't execute a command
	if (! HasActiveMembers())
		return false;

	// return false if the officers have turned on the player
	if (SwatAIRepo.GetHive().HasTurnedOnPlayer())
		return false;

	// return false if the officers are engaging somebody
	if (AreOfficersBusyEngaging())
	{
		TriggerBusyEngagingSpeech();
		return false;
	}

	// we can execute the command
	return true;
}

private function bool AreOfficersBusyEngaging()
{
	local int i;
	local Pawn Officer, Assignment;

	// make sure we update our current assignments
	SwatAIRepo.GetHive().UpdateOfficerAssignments();

	// go through the officers, if one of them has an assignment, then we can't follow the command
	for(i=0; i<pawns.length; ++i)
	{
		Officer = pawns[i];

		Assignment = ISwatOfficer(Officer).GetOfficerCommanderAction().GetCurrentAssignment();

		if (Assignment != None)
			return true;
	}

	// didn't find an officer with an assignment
	return false;
}

private function TriggerBusyEngagingSpeech()
{
	local Pawn Officer;

	// this function doesn't need to be networked because we don't have officers in coop
	Officer = GetClosestOfficerTo(SwatAIRepo.Level.GetLocalPlayerController().Pawn);

	if (Officer != None)
	{
		ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerBusyEngagingSpeech();
	}
}

private function TriggerOtherTeamDoingBehaviorSpeech()
{
	local Pawn Officer;

	// this function doesn't need to be networked because we don't have officers in coop
	Officer = GetClosestOfficerTo(SwatAIRepo.Level.GetLocalPlayerController().Pawn);

	if (Officer != None)
	{
		ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerOtherTeamOnItSpeech();
	}
}

function TriggerTeamReportedSpeech(Pawn Officer);

// returns true if any officer has the equipment, and it can be used (ie. a fired weapon has ammo)
// returns false otherwise
function bool DoesAnOfficerHaveUsableEquipment(EquipmentSlot Slot, optional Name EquipmentClassName)
{
	local int i;
	local Pawn Officer;
    local HandheldEquipment Equipment;
	local FiredWeapon Weapon;

    for(i=0; i<pawns.length; ++i)
	{
		Officer = pawns[i];

	    Equipment = ISwatOfficer(Officer).GetItemAtSlot(Slot);
		if (Equipment != None)
        {
            // If no class name was supplied, or if the equipment is of
            // the supplied class name's type, then this officer has the
            // equipment
            if (EquipmentClassName == '' || Equipment.IsA(EquipmentClassName))
            {
				Weapon = FiredWeapon(Equipment);

			    return ((Weapon == None) || !Weapon.IsEmpty());
		    }
        }
	}

	// no Officer has the equipment
	return false;
}

event function bool CanPickLock()
{
	return DoesAnOfficerHaveUsableEquipment(Slot_Toolkit);
}

event private function bool CanBreachAndClearLockedDoor()
{
	if (DoesAnOfficerHaveUsableEquipment(SLOT_Breaching) ||
		DoesAnOfficerHaveUsableEquipment(Slot_Toolkit))
	{
		return true;
	}
	else
	{
		return false;
	}
}

event function bool CanBreachAndClear(bool bPlayerBelievesDoorLocked)
{
	// if we believe the door to be locked, test to see if we have the equipment to open a locked door
	if (bPlayerBelievesDoorLocked)
	{
		return CanBreachAndClearLockedDoor();
	}
	else
	{
		// if we believe the door is unlocked, we can always breach and clear
		return true;
	}

	return false;
}

event function bool CanBreachBangAndClear(bool bPlayerBelievesDoorLocked)
{
	return (CanBreachAndClear(bPlayerBelievesDoorLocked) && DoesAnOfficerHaveUsableEquipment(Slot_Flashbang));
}

event function bool CanBreachGasAndClear(bool bPlayerBelievesDoorLocked)
{
	return (CanBreachAndClear(bPlayerBelievesDoorLocked) && DoesAnOfficerHaveUsableEquipment(Slot_CSGasGrenade));
}

event function bool CanBreachStingAndClear(bool bPlayerBelievesDoorLocked)
{
	return (CanBreachAndClear(bPlayerBelievesDoorLocked) && DoesAnOfficerHaveUsableEquipment(Slot_StingGrenade));
}

event function bool CanBangAndClear()
{
	return DoesAnOfficerHaveUsableEquipment(Slot_Flashbang);
}

event function bool CanGasAndClear()
{
	return DoesAnOfficerHaveUsableEquipment(Slot_CSGasGrenade);
}

event function bool CanStingAndClear()
{
	return DoesAnOfficerHaveUsableEquipment(Slot_StingGrenade);
}

event function bool CanDeployThrownItem(EquipmentSlot ThrownItemEquipmentSlot)
{
	return DoesAnOfficerHaveUsableEquipment(ThrownItemEquipmentSlot);
}

event function bool CanDeployShotgun(Door TargetDoor)
{
	return TargetDoor.IsClosed() && DoesAnOfficerHaveUsableEquipment(Slot_Breaching, 'BreachingShotgun');
}

event function bool CanDeployC2(Door TargetDoor, bool bLeftSide)
{
    local ISwatDoor SwatDoor;
    SwatDoor = ISwatDoor(TargetDoor);
    assert(SwatDoor != None);

	// if the door is closed, and there's already a charge on this side, or an officer
    // has C2 that they can use, then return true
    return TargetDoor.IsClosed() && DoesAnOfficerHaveUsableEquipment(Slot_Breaching, 'C2Charge');
}

event function bool CanDeployPepperSpray()
{
	return DoesAnOfficerHaveUsableEquipment(Slot_PepperSpray);
}

event function bool CanDeployTaser()
{
    return DoesAnOfficerHaveUsableEquipment(Slot_SecondaryWeapon, 'Taser');
}

event function bool CanDeployLessLethalShotgun()
{
    return DoesAnOfficerHaveUsableEquipment(Slot_PrimaryWeapon, 'LessLethalSG');
}

event function bool CanDeployGrenadeLauncher()
{
    return DoesAnOfficerHaveUsableEquipment(Slot_PrimaryWeapon, 'HK69GrenadeLauncher');
}

event function bool CanDeployPepperBallGun()
{
    return DoesAnOfficerHaveUsableEquipment(Slot_PrimaryWeapon, 'CSBallLauncher') || DoesAnOfficerHaveUsableEquipment(Slot_SecondaryWeapon, 'CSBallLauncher');
}

event function bool CanDeployLightstick()
{
    return DoesAnOfficerHaveUsableEquipment(Slot_Lightstick);
}

event function bool CanDeployWedge(Door TargetDoor)
{
	return (! ISwatDoor(TargetDoor).IsWedged()) && DoesAnOfficerHaveUsableEquipment(Slot_Wedge);
}

event function bool CanDisable()
{
	return DoesAnOfficerHaveUsableEquipment(Slot_Toolkit);
}

event function bool CanMirror()
{
	return DoesAnOfficerHaveUsableEquipment(Slot_Optiwand);
}

///////////////////////////////////////////////////////////////////////////////
//
// Officer Commands

protected function PostCommandGoal(SquadCommandGoal NewCommandGoal)
{
	assert(NewCommandGoal != None);

	// unpost any existing command goals
	UnpostCommandGoals();

	InternalPostCommandGoal(NewCommandGoal);
}

protected function InternalPostCommandGoal(SquadCommandGoal NewCommandGoal)
{
	assert(NewCommandGoal != None);
	assert(CurrentSquadCommandGoal == None);

//	log(NewCommandGoal.Name $ " will be posted on " $ Name);

	// post the new command goal
	CurrentSquadCommandGoal = NewCommandGoal;
	CurrentSquadCommandGoal.AddRef();
	CurrentSquadCommandGoal.postGoal(None);
}

// subclasses should override
protected function UnpostCommandGoals();

function ClearCommandGoal()
{
	if ((GetFirstOfficer() != None) && GetFirstOfficer().logAI)
		log(Name $ " ClearCommandGoal - " $ CurrentSquadCommandGoal $ " will be unposted on " $ Name);

	if (CurrentSquadCommandGoal != None)
	{
		CurrentSquadCommandGoal.unPostGoal(None);
		CurrentSquadCommandGoal.Release();
		CurrentSquadCommandGoal = None;
	}
}

function ClearNonCharacterInteractionCommandGoal()
{
    if ((CurrentSquadCommandGoal != None) && !CurrentSquadCommandGoal.bIsCharacterInteractionCommandGoal)
    {
        ClearCommandGoal();
    }
}

function bool IsExecutingCommandGoal()
{
	return ((CurrentSquadCommandGoal != None) && !CurrentSquadCommandGoal.hasCompleted());
}

// Overridden in ColoredSquadInfo
function bool IsSubElement()
{
	return false;
}

function ColoredSquadInfo GetOtherTeam()
{
	assert(! IsA('ElementSquadInfo'));

	if (SwatAIRepo.GetBlueSquad() == self)
		return SwatAIRepo.GetRedSquad();
	else
		return SwatAIRepo.GetBlueSquad();
}

function bool HoldingStatusDiffers()
{
	assert(! IsA('ElementSquadInfo'));

	return GetOtherTeam().bHoldCommand != bHoldCommand;
}

function bool IsOtherSubElementUsingDoor(Door TestDoor)
{
	local Door DoorOtherTeamIsUsing;
	
	assert(TestDoor != None);

	DoorOtherTeamIsUsing = GetOtherTeam().GetDoorBeingUsed();

	return (DoorOtherTeamIsUsing == TestDoor);
}

// perfectly ok to return none
function Door GetDoorBeingUsed()
{
	if (IsExecutingCommandGoal())
		return CurrentSquadCommandGoal.GetDoorBeingUsed();
	else
		return None;
}

function bool IsOtherSubElementFallingIn()
{
	return GetOtherTeam().IsFallingIn();
}

function bool IsFallingIn()
{
	if (IsExecutingCommandGoal())
		return CurrentSquadCommandGoal.IsA('SquadFallInGoal');
	else
		return false;
}

function bool IsOtherSubElementInteractingWith(Actor TestActor)
{
	return GetOtherTeam().IsTeamInteractingWith(TestActor);
}

function bool IsTeamInteractingWith(Actor TestActor)
{
	if (IsExecutingCommandGoal())
		return CurrentSquadCommandGoal.IsInteractingWith(TestActor);
	else
		return false;
}

function SetSquadCommandGoalHold(bool status)
{
	if (CurrentSquadCommandGoal != None)
		CurrentSquadCommandGoal.bHoldCommand = status;
}

function bool IsHoldingCommandGoal()
{
	return CurrentSquadCommandGoal != None && CurrentSquadCommandGoal.bHoldCommand;
}

function ClearHeldFlag()
{
	local SwatAIRepository SwatAIRepo;

	SwatAIRepo = SwatAIRepository(Level.AIRepo);
	if (self == SwatAIRepo.GetElementSquad())
	{
		SwatAIRepo.GetRedSquad().bHoldCommand = false;
		SwatAIRepo.GetBlueSquad().bHoldCommand = false;
	}
	bHoldCommand = false;
}

function bool Zulu(Pawn CommandGiver, vector CommandOrigin)
{
 	local SwatAIRepository SwatAIRepo;

	if (CommandGiver == None || class'Pawn'.static.CheckDead(CommandGiver))
        return false;

	// (speech is issued in CommandInterface.SpeakingCommand state - doesn't need to be done here)

	// stop command actions from blocking
	SwatAIRepo = SwatAIRepository(Level.AIRepo);
	SetSquadCommandGoalHold(false);
	if (self == SwatAIRepo.GetElementSquad())
	{
		SwatAIRepo.GetRedSquad().SetSquadCommandGoalHold(false);
		SwatAIRepo.GetBlueSquad().SetSquadCommandGoalHold(false);
	}
	ClearHeldFlag();

	return true;	// command issued
}

function bool FallIn(Pawn CommandGiver, vector CommandOrigin)
{
	local SquadFallInGoal SquadFallInGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not falling in, or holding status differs
		if (!IsSubElement() || !IsOtherSubElementFallingIn() || HoldingStatusDiffers())
		{
			SquadFallInGoal = new class'SquadFallInGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin);
			assert(SquadFallInGoal != None);

			PostCommandGoal(SquadFallInGoal);
		}
		else
		{
			// we want the whole team to fall in
			SwatAIRepo.GetElementSquad().bHoldCommand = bHoldCommand;
			SwatAIRepo.GetElementSquad().FallIn(CommandGiver, CommandOrigin);
		}
		return true;	// command issued
	}
	
	return false;
}

function bool StackUpAt(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadStackUpGoal SquadStackUpGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			SquadStackUpGoal = new class'SquadStackUpGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
			assert(SquadStackUpGoal != None);

			PostCommandGoal(SquadStackUpGoal);
			return true;	// command issued
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}
	
	return false;
}

function bool StackUpAndTryDoorAt(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor, optional bool bTriggerCouldntBreachLockedSpeech)
{
	local SquadStackUpAndTryDoorGoal SquadStackUpAndTryDoorGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			SquadStackUpAndTryDoorGoal = new class'SquadStackUpAndTryDoorGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor, bTriggerCouldntBreachLockedSpeech);
			assert(SquadStackUpAndTryDoorGoal != None);

			PostCommandGoal(SquadStackUpAndTryDoorGoal);
			return true;	// command issued
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool MoveAndClear(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadMoveAndClearGoal SquadMoveAndClearGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			SquadMoveAndClearGoal = new class'SquadMoveAndClearGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
			assert(SquadMoveAndClearGoal != None);

			PostCommandGoal(SquadMoveAndClearGoal);
			return true;	// command issued
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool BangAndClear(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadBangAndClearGoal SquadBangAndClearGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (CanBangAndClear())
			{
				SquadBangAndClearGoal = new class'SquadBangAndClearGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
				assert(SquadBangAndClearGoal != None);

				PostCommandGoal(SquadBangAndClearGoal);
				return true;	// command issued
			}
			else
			{
				// respond to not being able to bang and clear
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerFlashbangUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool GasAndClear(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadGasAndClearGoal SquadGasAndClearGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (CanGasAndClear())
			{
				SquadGasAndClearGoal = new class'SquadGasAndClearGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
				assert(SquadGasAndClearGoal != None);

				PostCommandGoal(SquadGasAndClearGoal);
				return true;	// command issued
			}
			else
			{
				// respond to not being able to gas and clear
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerGasUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool StingAndClear(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadStingAndClearGoal SquadStingAndClearGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (CanStingAndClear())
			{
				SquadStingAndClearGoal = new class'SquadStingAndClearGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
				assert(SquadStingAndClearGoal != None);

				PostCommandGoal(SquadStingAndClearGoal);
				return true;	// command issued
			}
			else
			{
				// respond to not being able to sting and clear
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerStingUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

// How Breach and Clear is supposed to work.

// If the player believes the door is unlocked:
//  |-> The Door is locked   -> The Officers will stack up and try the door, feeding back to the player that the door is locked
//  \-> The door is unlocked -> The Officers will breach and clear normally (they will just open the door)

// If the player believes the door is locked:
//  |-> The door is locked AND an Officer has the means (shotgun, C2, toolkit) to make it open -> The Officers will breach and clear normally
//  \-> The door is locked AND an Officer does not have the means (see above) to make it open -> The Officers will report that they do not have the necessary equipment

function bool BreachAndClear(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor, optional bool UseBreachingEquipment)
{
	local SquadBreachAndClearGoal SquadBreachAndClearGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (UseBreachingEquipment)
			{
				if (CanBreachAndClearLockedDoor())
				{
					SquadBreachAndClearGoal = new class'SquadBreachAndClearGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor, UseBreachingEquipment);
					assert(SquadBreachAndClearGoal != None);

					PostCommandGoal(SquadBreachAndClearGoal);
					return true;	// command issued
				}
				else
				{
					// respond to not being able to breach a locked door
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerDoorBreachingEquipmentUnavailableSpeech();
				}
			}
			else
			{
				if (ISwatDoor(TargetDoor).IsLocked())
				{
					// if it's locked, and we don't believe it's locked, stack up and try the door 
					// (and therefore report the status of the door)
					StackUpAndTryDoorAt(CommandGiver, CommandOrigin, TargetDoor, true);
				}
				else
				{
					// just move and clear
					MoveAndClear(CommandGiver, CommandOrigin, TargetDoor);
				}
				return true;	// command issued
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool BreachBangAndClear(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor, optional bool UseBreachingEquipment)
{
	local SquadBreachBangAndClearGoal SquadBreachBangAndClearGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if ((pawns[0] != None) && (pawns[0].logAI))
				log("BreachBangAndClear - CommandGiver believes door locked: " $ ISwatPawn(CommandGiver).DoesBelieveDoorLocked(TargetDoor) $ " is door locked: " $ ISwatDoor(TargetDoor).IsLocked());

			if (UseBreachingEquipment)
			{
				if (! DoesAnOfficerHaveUsableEquipment(Slot_Flashbang))
				{
					// respond that we don't have a flashbang
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerFlashbangUnavailableSpeech();
				}
				else if (! CanBreachAndClearLockedDoor())
				{
					// respond to not being able to breach a locked door
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerDoorBreachingEquipmentUnavailableSpeech();
				}
				else
				{
					// we can execute this command
					SquadBreachBangAndClearGoal = new class'SquadBreachBangAndClearGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor, UseBreachingEquipment);
					assert(SquadBreachBangAndClearGoal != None);

					PostCommandGoal(SquadBreachBangAndClearGoal);
					return true;	// command issued
				}
			}
			else
			{
				if (ISwatDoor(TargetDoor).IsLocked())
				{
					// if it's locked, and we don't believe it's locked, stack up and try the door 
					// (and therefore report the status of the door)
					StackUpAndTryDoorAt(CommandGiver, CommandOrigin, TargetDoor, true);
				}
				else
				{
					// just bang and clear
					BangAndClear(CommandGiver, CommandOrigin, TargetDoor);
				}
				return true;	// command issued
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool BreachGasAndClear(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor, optional bool UseBreachingEquipment)
{
	local SquadBreachGasAndClearGoal SquadBreachGasAndClearGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (UseBreachingEquipment)
			{
				if (! DoesAnOfficerHaveUsableEquipment(Slot_CSGasGrenade))
				{
					// respond that we don't have any gas grenades
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerGasUnavailableSpeech();
				}
				else if (! CanBreachAndClearLockedDoor())
				{
					// respond to not being able to breach a locked door
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerDoorBreachingEquipmentUnavailableSpeech();
				}
				else
				{
					SquadBreachGasAndClearGoal = new class'SquadBreachGasAndClearGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor, UseBreachingEquipment);
					assert(SquadBreachGasAndClearGoal != None);

					PostCommandGoal(SquadBreachGasAndClearGoal);
					return true;	// command issued
				}
			}
			else
			{
				if (ISwatDoor(TargetDoor).IsLocked())
				{
					// if it's locked, and we don't believe it's locked, stack up and try the door 
					// (and therefore report the status of the door)
					StackUpAndTryDoorAt(CommandGiver, CommandOrigin, TargetDoor, true);
				}
				else
				{
					// just gas and clear
					GasAndClear(CommandGiver, CommandOrigin, TargetDoor);
				}
				return true;	// command issued
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool BreachStingAndClear(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor, optional bool UseBreachingEquipment)
{
	local SquadBreachStingAndClearGoal SquadBreachStingAndClearGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (UseBreachingEquipment)
			{
				if (! DoesAnOfficerHaveUsableEquipment(Slot_StingGrenade))
				{
					// respond that we don't have any gas grenades
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerStingUnavailableSpeech();
				}
				else if (! CanBreachAndClearLockedDoor())
				{
					// respond to not being able to breach a locked door
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerDoorBreachingEquipmentUnavailableSpeech();
				}
				else
				{
					SquadBreachStingAndClearGoal = new class'SquadBreachStingAndClearGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor, UseBreachingEquipment);
					assert(SquadBreachStingAndClearGoal != None);

					PostCommandGoal(SquadBreachStingAndClearGoal);
					return true;	// command issued
				}
			}
			else
			{
				if (ISwatDoor(TargetDoor).IsLocked())
				{
					// if it's locked, and we don't believe it's locked, stack up and try the door 
					// (and therefore report the status of the door)
					StackUpAndTryDoorAt(CommandGiver, CommandOrigin, TargetDoor, true);
				}
				else
				{
					// just sting and clear
					StingAndClear(CommandGiver, CommandOrigin, TargetDoor);
				}
				return true;	// command issued
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployThrownItemAt(Pawn CommandGiver, vector CommandOrigin, EquipmentSlot ThrownItemSlot, vector TargetLocation, optional Door TargetDoor)
{
	local SquadDeployThrownItemGoal SquadDeployThrownItemGoal;
	local SquadDeployThrownItemThroughDoorGoal SquadDeployThrownItemThroughDoorGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, the target door is none, or if the other team is not using the same door
		if ((TargetDoor == None) || !IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (CanDeployThrownItem(ThrownItemSlot))
			{
				if (TargetDoor != None)
				{
					if (TargetDoor.IsClosed() && !TargetDoor.IsOpening() && !TargetDoor.IsBroken() && TargetDoor.IsLocked())
					{
						// if it's locked, regardless of whether we believe it's locked, stack up and try the door 
						// (and therefore report the status of the door)
						StackUpAndTryDoorAt(CommandGiver, CommandOrigin, TargetDoor, true);
					}
					else
					{
						SquadDeployThrownItemThroughDoorGoal = new class'SquadDeployThrownItemThroughDoorGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor, ThrownItemSlot);
						assert(SquadDeployThrownItemThroughDoorGoal != None);
		
						PostCommandGoal(SquadDeployThrownItemThroughDoorGoal);
					}
					return true;	// command issued
				}
				else
				{
					SquadDeployThrownItemGoal = new class'SquadDeployThrownItemGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, ThrownItemSlot, TargetLocation);
					assert(SquadDeployThrownItemGoal != None);

					PostCommandGoal(SquadDeployThrownItemGoal);
					return true;	// command issued
				}
			}
			else
			{
				switch(ThrownItemSlot)
				{
					case Slot_Flashbang:
						ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerFlashbangUnavailableSpeech();
						break;

					case Slot_CSGasGrenade:
						ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerGasUnavailableSpeech();
						break;

					case Slot_StingGrenade:
						ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerStingUnavailableSpeech();
						break;
				}
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployGrenadeLauncher(Pawn CommandGiver, vector CommandOrigin, Actor TargetActor, vector TargetLocation)
{
	local SquadDeployGrenadeLauncherGoal CurrentSquadDeployGrenadeLauncherGoal;

// log(Name $ " told to deploy grenade launcher on: " $ TargetActor @ TargetLocation);

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is already interacting with the TargetPawn
		if (!IsSubElement() || !IsOtherSubElementInteractingWith(TargetActor))
		{
			if (CanDeployGrenadeLauncher())
			{
				CurrentSquadDeployGrenadeLauncherGoal = new class'SquadDeployGrenadeLauncherGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetActor, TargetLocation);
				assert(CurrentSquadDeployGrenadeLauncherGoal != None);

				PostCommandGoal(CurrentSquadDeployGrenadeLauncherGoal);
				return true;	// command issued
			}
			else
			{
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerGrenadeLauncherUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool PickLock(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadPickLockGoal SquadPickLockGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (CanPickLock())
			{
				SquadPickLockGoal = new class'SquadPickLockGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
				assert(SquadPickLockGoal != None);

				PostCommandGoal(SquadPickLockGoal);
				return true;	// command issued
			}
			else
			{
				// respond to not being able to pick a lock
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerToolkitUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployWedge(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadPlaceWedgeGoal SquadPlaceWedgeGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (CanDeployWedge(TargetDoor))
			{
				SquadPlaceWedgeGoal = new class'SquadPlaceWedgeGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
				assert(SquadPlaceWedgeGoal != None);

				PostCommandGoal(SquadPlaceWedgeGoal);
				return true;	// command issued
			}
			else
			{
				if (! DoesAnOfficerHaveUsableEquipment(Slot_Wedge))
				{
					// respond to not having a wedge available
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerWedgeUnavailableSpeech();
				}
				else
				{
					// sanity check
					assert(ISwatDoor(TargetDoor).IsWedged());

					// respond that the door is already wedged
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerDoorIsAlreadyWedgedSpeech();
				}
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool RemoveWedge(Pawn CommandGiver, vector CommandOrigin, Door WedgedDoor)
{
	local SquadRemoveWedgeGoal SquadRemoveWedgeGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(WedgedDoor))
		{
			if (CanPickLock())
			{
				SquadRemoveWedgeGoal = new class'SquadRemoveWedgeGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, WedgedDoor);
				assert(SquadRemoveWedgeGoal != None);

				PostCommandGoal(SquadRemoveWedgeGoal);
				return true;	// command issued
			}
			else
			{
				// respond to not being able to remove a wedge
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerToolkitUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployC2(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadDeployC2Goal CurrentSquadDeployC2Goal;
	local ISwatDoor SwatDoorTarget;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			SwatDoorTarget = ISwatDoor(TargetDoor);
			assert(SwatDoorTarget != None);

			if (! TargetDoor.IsClosed())
			{
				// respond that the door isn't closed 
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerDoorNotClosedSpeech();
			}
			else if (CanDeployC2(TargetDoor, SwatDoorTarget.PointIsToMyLeft(CommandOrigin)))
			{
				CurrentSquadDeployC2Goal = new class'SquadDeployC2Goal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
				assert(CurrentSquadDeployC2Goal != None);

				PostCommandGoal(CurrentSquadDeployC2Goal);
				return true;	// command issued
			}
			else
			{
				// respond that nobody has C2
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerC2UnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool CloseDoor(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadCloseDoorGoal CurrentSquadCloseDoorGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			CurrentSquadCloseDoorGoal = new class'SquadCloseDoorGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
			assert(CurrentSquadCloseDoorGoal != None);

			PostCommandGoal(CurrentSquadCloseDoorGoal);
			return true;	// command issued
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool Secure(Pawn CommandGiver, vector CommandOrigin, Actor SecureTarget)
{
	local SquadSecureGoal CurrentSquadSecureGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is already interacting with the SecureTarget
		if (!IsSubElement() || !IsOtherSubElementInteractingWith(SecureTarget))
		{
			CurrentSquadSecureGoal = SquadSecureGoal(CurrentSquadCommandGoal);

			// if the current secure goal wasn't achieved yet, add a new secure target
			// however, if the current secure goal was achieved, or there isn't a current secure goal, start a new behavior
			if ((CurrentSquadSecureGoal != None) && !CurrentSquadSecureGoal.hasCompleted())
			{
				CurrentSquadSecureGoal.AddSecureTarget(SecureTarget);
			}
			else
			{
				CurrentSquadSecureGoal = new class'SquadSecureGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin);
				assert(CurrentSquadSecureGoal != None);

				CurrentSquadSecureGoal.AddSecureTarget(SecureTarget);
				PostCommandGoal(CurrentSquadSecureGoal);
				return true;	// command issued
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool Restrain(Pawn CommandGiver, vector CommandOrigin, Pawn TargetPawn)
{
	return Secure(CommandGiver, CommandOrigin, TargetPawn);
}

function bool SecureEvidence(Pawn CommandGiver, vector CommandOrigin, Actor Evidence)
{
	return Secure(CommandGiver, CommandOrigin, Evidence);
}

function bool MoveTo(Pawn CommandGiver, vector CommandOrigin, vector TargetLocation)
{
	local SquadMoveToGoal CurrentSquadMoveToGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		CurrentSquadMoveToGoal = new class'SquadMoveToGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetLocation);
		assert(CurrentSquadMoveToGoal != None);

		PostCommandGoal(CurrentSquadMoveToGoal);
		return true;	// command issued
	}

	return false;
}

function bool Cover(Pawn CommandGiver, vector CommandOrigin, vector TargetLocation)
{
	local SquadCoverGoal CurrentSquadCoverGoal;

	if (CanExecuteCommand())
	{
		CurrentSquadCoverGoal = new class'SquadCoverGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetLocation);
		assert(CurrentSquadCoverGoal != None);

		PostCommandGoal(CurrentSquadCoverGoal);
		return true;	// command issued
	}

	return false;
}

private function bool InternalMirrorRoom(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadMirrorDoorGoal CurrentSquadMirrorDoorGoal;

	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (CanMirror())
			{
				CurrentSquadMirrorDoorGoal = new class'SquadMirrorDoorGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor, false);
				assert(CurrentSquadMirrorDoorGoal != None);

				PostCommandGoal(CurrentSquadMirrorDoorGoal);
				return true;	// command issued
			}
			else
			{
				// respond that nobody has the mirror
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerMirrorUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool MirrorRoom(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	return InternalMirrorRoom(CommandGiver, CommandOrigin, TargetDoor);
}

function bool MirrorUnderDoor(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	return InternalMirrorRoom(CommandGiver, CommandOrigin, TargetDoor);
}

function bool MirrorCorner(Pawn CommandGiver, vector CommandOrigin, Actor MirrorPoint)
{
	local SquadMirrorCornerGoal CurrentSquadMirrorCornerGoal;

	assert(MirrorPoint != None);
	assertWithDescription(MirrorPoint.IsA('IMirrorPoint'), "OfficerTeamInfo::MirrorCorner - Actor passed in is not a IMirrorPoint");

	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is already interacting with the mirror point
		if (!IsSubElement() || !IsOtherSubElementInteractingWith(MirrorPoint))
		{
			if (CanMirror())
			{
				CurrentSquadMirrorCornerGoal = new class'SquadMirrorCornerGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, MirrorPoint);
				assert(CurrentSquadMirrorCornerGoal != None);

				PostCommandGoal(CurrentSquadMirrorCornerGoal);
				return true;	// command issued
			}
			else
			{
				// respond that nobody has the mirror
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerMirrorUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployTaser(Pawn CommandGiver, vector CommandOrigin, Pawn TargetPawn)
{
	local SquadDeployTaserGoal CurrentSquadDeployTaserGoal;

//	log(Name $ " told to deploy taser on: " $ TargetPawn);

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is already interacting with the TargetPawn
		if (!IsSubElement() || !IsOtherSubElementInteractingWith(TargetPawn))
		{
			if (CanDeployTaser())
			{
				CurrentSquadDeployTaserGoal = new class'SquadDeployTaserGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetPawn);
				assert(CurrentSquadDeployTaserGoal != None);

				PostCommandGoal(CurrentSquadDeployTaserGoal);
				return true;	// command issued
			}
			else
			{
				// respond that nobody has the taser
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerTaserUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployPepperSpray(Pawn CommandGiver, vector CommandOrigin, Pawn TargetPawn)
{
	local SquadDeployPepperSprayGoal CurrentSquadDeployPepperSprayGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is already interacting with the TargetPawn
		if (!IsSubElement() || !IsOtherSubElementInteractingWith(TargetPawn))
		{
			if (CanDeployPepperSpray())
			{
				CurrentSquadDeployPepperSprayGoal = new class'SquadDeployPepperSprayGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetPawn);
				assert(CurrentSquadDeployPepperSprayGoal != None);

				PostCommandGoal(CurrentSquadDeployPepperSprayGoal);
				return true;	// command issued
			}
			else
			{
				// respond that nobody has the pepper spray
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerPepperSprayUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DisableTarget(Pawn CommandGiver, vector CommandOrigin, Actor Target)
{
	local SquadDisableTargetGoal CurrentSquadDisableTargetGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is already interacting with the Target
		if (!IsSubElement() || !IsOtherSubElementInteractingWith(Target))
		{
			CurrentSquadDisableTargetGoal = new class'SquadDisableTargetGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, Target);
			assert(CurrentSquadDisableTargetGoal != None);

			PostCommandGoal(CurrentSquadDisableTargetGoal);
			return true;	// command issued
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployShotgun(Pawn CommandGiver, vector CommandOrigin, Door TargetDoor)
{
	local SquadDeployShotgunGoal CurrentSquadDeployShotgunGoal;
	local ISwatDoor SwatDoorTarget;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is not using the same door
		if (!IsSubElement() || !IsOtherSubElementUsingDoor(TargetDoor))
		{
			if (CanDeployShotgun(TargetDoor))
			{
				SwatDoorTarget = ISwatDoor(TargetDoor);
				assert(SwatDoorTarget != None);
			
				if (! TargetDoor.IsClosed())
				{
					// respond that the door isn't closed 
					ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerDoorNotClosedSpeech();
				}
				else
				{
					CurrentSquadDeployShotgunGoal = new class'SquadDeployShotgunGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetDoor);
					assert(CurrentSquadDeployShotgunGoal != None);

					PostCommandGoal(CurrentSquadDeployShotgunGoal);
					return true;	// command issued
				}
			}
			else
			{
				// respond that nobody has the shotgun
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerShotgunUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployLessLethalShotgun(Pawn CommandGiver, vector CommandOrigin, Pawn TargetPawn)
{
	local SquadDeployLessLethalShotgunGoal CurrentSquadDeployLessLethalShotgunGoal;

//	log(Name $ " told to deploy taser on: " $ TargetPawn);

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is already interacting with the TargetPawn
		if (!IsSubElement() || !IsOtherSubElementInteractingWith(TargetPawn))
		{
			if (CanDeployLessLethalShotgun())
			{
				CurrentSquadDeployLessLethalShotgunGoal = new class'SquadDeployLessLethalShotgunGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetPawn);
				assert(CurrentSquadDeployLessLethalShotgunGoal != None);

				PostCommandGoal(CurrentSquadDeployLessLethalShotgunGoal);
				return true;	// command issued
			}
			else
			{
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerLessLethalShotgunUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployPepperBallGun(Pawn CommandGiver, vector CommandOrigin, Pawn TargetPawn)
{
	local SquadDeployPepperBallGoal CurrentSquadDeployPepperBallGoal;

//	log(Name $ " told to deploy taser on: " $ TargetPawn);

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		// if we're not a sub element, or if the other team is already interacting with the TargetPawn
		if (!IsSubElement() || !IsOtherSubElementInteractingWith(TargetPawn))
		{
			if (CanDeployPepperBallGun())
			{
				CurrentSquadDeployPepperBallGoal = new class'SquadDeployPepperBallGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin, TargetPawn);
				assert(CurrentSquadDeployPepperBallGoal != None);

				PostCommandGoal(CurrentSquadDeployPepperBallGoal);
				return true;	// command issued
			}
			else
			{
				ISwatOfficer(GetFirstOfficer()).GetOfficerSpeechManagerAction().TriggerPepperBallUnavailableSpeech();
			}
		}
		else
		{
			TriggerOtherTeamDoingBehaviorSpeech();
		}
	}

	return false;
}

function bool DeployLightstick(Pawn CommandGiver, vector CommandOrigin, vector TargetLocation)
{
	local SquadDeployLightStickGoal CurrentSquadDeployLightStickGoal;

	// only post the goal if we are allowed
	if (CanExecuteCommand())
	{
		CurrentSquadDeployLightStickGoal = SquadDeployLightStickGoal(CurrentSquadCommandGoal);

		// if the current DeployLightStick goal wasn't achieved yet, add a new drop point
		// however, if the current DeployLightStick goal was achieved, or there isn't a current DeployLightStick goal, start a new behavior
		if ((CurrentSquadDeployLightStickGoal != None) && !CurrentSquadDeployLightStickGoal.hasCompleted())
		{
			CurrentSquadDeployLightStickGoal.AddDropPoint(TargetLocation);
		}
		else
		{
			CurrentSquadDeployLightstickGoal = new class'SquadDeployLightStickGoal'(AI_Resource(SquadAI), CommandGiver, CommandOrigin);
			assert(CurrentSquadDeployLightStickGoal != None);

			CurrentSquadDeployLightstickGoal.AddDropPoint(TargetLocation);
			PostCommandGoal(CurrentSquadDeployLightStickGoal);
			return true;	// command issued
		}
	}

	return false;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	tickTimeUpdateRange = (Min=0.0,Max=0.0)
}
