///////////////////////////////////////////////////////////////////////////////
// SquadBreachAndClearAction.uc - SquadBreachAndClearAction class
// this action is used to organize the Officer's breach & clear behavior

class SquadBreachAndClearAction extends SquadMoveAndClearAction
	implements IInterestedInDetonatorEquipping;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private UseBreachingShotgunGoal CurrentUseBreachingShotgunGoal;
var private UseBreachingChargeGoal  CurrentUseBreachingChargeGoal;

///////////////////////////////////////////////////////////////////////////////
//
// cleanup

function cleanup()
{
	super.cleanup();

    if (CurrentUseBreachingShotgunGoal != None)
    {
        CurrentUseBreachingShotgunGoal.Release();
        CurrentUseBreachingShotgunGoal = None;
    }

	if (CurrentUseBreachingChargeGoal != None)
	{
		CurrentUseBreachingChargeGoal.Release();
		CurrentUseBreachingChargeGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Callbacks / Notifications

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	super.goalAchievedCB(goal, child);

	if (goal == CurrentUseBreachingShotgunGoal)
	{
		CurrentUseBreachingShotgunGoal.unPostGoal(self);
		CurrentUseBreachingShotgunGoal.Release();
		CurrentUseBreachingShotgunGoal = None;
	}
	else if (goal == CurrentUseBreachingChargeGoal)
	{
		CurrentUseBreachingChargeGoal.unPostGoal(self);
		CurrentUseBreachingChargeGoal.Release();
		CurrentUseBreachingChargeGoal = None;
	}
}

function NotifyDetonatorEquipping()
{
	if (isIdle() && (Breacher != Thrower))
		runAction();
}

///////////////////////////////////////////////////////////////////////////////
//
// Stacking up

// any breaching in a move and clear should be preceded by a stack up
// (according to the designers, and I agree)
protected function bool ShouldStackUpIfOfficersInRoomToClear() { return true; }


///////////////////////////////////////////////////////////////////////////////
//
// State Code

protected function SetBreacher()
{
	// breacher is ALWAYS the first officer
	Breacher = GetFirstOfficer();
}

protected function bool CanOfficerBreachWithShotgun(Pawn Officer)
{
	local HandheldEquipment Equipment;
	local FiredWeapon Weapon;

    Equipment = ISwatOfficer(Officer).GetItemAtSlot(SLOT_Breaching);
    if ((Equipment != None) && Equipment.IsA('BreachingShotgun'))
    {
		Weapon = FiredWeapon(Equipment);
		assert(Weapon != None);

		if (! Weapon.NeedsReload() || Weapon.CanReload())
		{
			return true;
		}
    }

	return false;
}

latent function UseBreachingShotgun()
{
	assert(Breacher != None);

	ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

	CurrentUseBreachingShotgunGoal = new class'UseBreachingShotgunGoal'(AI_Resource(Breacher.characterAI), TargetDoor);
	assert(CurrentUseBreachingShotgunGoal != None);
	CurrentUseBreachingShotgunGoal.AddRef();

	CurrentUseBreachingShotgunGoal.postGoal(self);

	// if we have a second officer, pause and wait for the door to open
	if (GetSecondOfficer() != None)
	{
		pause();
	}
	else
	{
		WaitForGoal(CurrentUseBreachingShotgunGoal);
	}

	CurrentUseBreachingShotgunGoal.unPostGoal(self);

	CurrentUseBreachingShotgunGoal.Release();
	CurrentUseBreachingShotgunGoal = None;
}

protected function bool CanOfficerBreachWithC2(Pawn Officer)
{
	local ISwatDoor SwatDoorTarget;
	local bool bIsChargeAlreadyPlacedOnDoor;
	local HandheldEquipment Equipment;

	assert(class'Pawn'.static.checkConscious(Officer));

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

    if (SwatDoorTarget.PointIsToMyLeft(CommandOrigin))
    {
        bIsChargeAlreadyPlacedOnDoor = SwatDoorTarget.IsChargePlacedOnLeft();
    }
    else
    {
        bIsChargeAlreadyPlacedOnDoor = SwatDoorTarget.IsChargePlacedOnRight();
    }

	// if a charge is already placed on the door, just use the first officer
	if (bIsChargeAlreadyPlacedOnDoor)
	{
		return (ISwatOfficer(Officer).GetItemAtSlot(Slot_Detonator) != None);
	}
	else
	{
		Equipment = ISwatOfficer(Officer).GetItemAtSlot(SLOT_Breaching);
        return (Equipment != None && Equipment.IsA('C2Charge'));
	}
}

latent function PlaceAndUseBreachingCharge()
{
    local NavigationPoint SafeLocation;

	assert(Breacher != None);

	ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

	// Get the post-breaching location to move to -- at this point the breacher is ALWAYS the first officer
	SafeLocation = StackUpPoints[0];
	assert(SafeLocation != None);

	CurrentUseBreachingChargeGoal = new class'UseBreachingChargeGoal'(AI_Resource(Breacher.characterAI), TargetDoor, SafeLocation);
	assert(CurrentUseBreachingChargeGoal != None);
	CurrentUseBreachingChargeGoal.AddRef();

	CurrentUseBreachingChargeGoal.SetInterestedInDetonatorEquippingClient(self);

	CurrentUseBreachingChargeGoal.postGoal(self);

	// if we have a different thrower than the breacher, pause and wait for the door to open
	if (Thrower != Breacher)
	{
		// pause to wait for the detonator to be equipped
		pause();

		// prepare the grenade
		PreTargetDoorBreached();

		// just wait for the door to open
		while (TargetDoor.IsClosed() && ! ISwatDoor(TargetDoor).IsBroken())
			yield();
	}
	else
	{
		WaitForGoal(CurrentUseBreachingChargeGoal);
		CurrentUseBreachingChargeGoal.unPostGoal(self);

		CurrentUseBreachingChargeGoal.Release();
		CurrentUseBreachingChargeGoal = None;
	}
}

latent function PrepareToMoveSquad(optional bool bNoZuluCheck)
{
	local ISwatDoor SwatDoorTarget;
	local bool bForceBreachAction;

	bForceBreachAction = SquadBreachAndClearGoal(achievingGoal).DoWeUseBreachingCharge();

    Super.PrepareToMoveSquad(true);

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	while ((SwatDoorTarget.IsLocked() || bForceBreachAction) && !SwatDoorTarget.IsBroken())
	{
		if (CanOfficerBreachWithShotgun(Breacher))
		{
			PreTargetDoorBreached();
			WaitForZulu();
			UseBreachingShotgun();
			PostTargetDoorBreached();
		}
		else if (CanOfficerBreachWithC2(Breacher))
		{
			PlaceAndUseBreachingCharge();	// <-- "WaitForZulu" happens here
			PostTargetDoorBreached();
		}
		else
		{
			assert(DoesAnOfficerHaveUsableEquipment(Slot_Toolkit));

			PreTargetDoorBreached();
			WaitForZulu();

			// just pick the lock because nobody has a breaching device
			// if there's no second officer, don't move to a destination afterwards, we will just open the door
			if(SwatDoorTarget.IsLocked())
				PickLock(GetSecondOfficer() != None);

			// if we are opening the door for throwing a grenade, do that
			// otherwise just let the base move and clear behavior take care of door opening
			if (Thrower != None)
				OpenDoorForThrowingGrenade();

			// door has been opened
			PostTargetDoorBreached();
		}

		yield();
	}
}

protected latent function PreTargetDoorBreached();
protected latent function PostTargetDoorBreached();

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadBreachAndClearGoal'
}
