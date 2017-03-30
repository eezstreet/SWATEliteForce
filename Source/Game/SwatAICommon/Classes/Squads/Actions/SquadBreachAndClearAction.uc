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
var protected OpenDoorGoal			CurrentOpenDoorGoal;

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
	if (CurrentOpenDoorGoal != None)
	{
		CurrentOpenDoorGoal.Release();
		CurrentOpenDoorGoal = None;
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
	if (goal == CurrentOpenDoorGoal)
	{
		CurrentOpenDoorGoal.unPostGoal(self);
		CurrentOpenDoorGoal.Release();
		CurrentOpenDoorGoal = None;
	}
}

function NotifyDetonatorEquipping()
{
	if (isIdle() && Breacher != Thrower)
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

protected function Pawn GetFirstOfficerWithC2(optional bool skipBreacher)
{
	local int i;
	local Pawn Officer;
	local Pawn Found;

	for(i = 0; i < OfficersInStackUpOrder.Length; i++) {
		Officer = OfficersInStackUpOrder[i];

		if(class'Pawn'.static.checkConscious(Officer) && CanOfficerBreachWithC2(Officer) && (!skipBreacher || Officer != Breacher)) {
			Found = Officer;
			break;
		}
	}

	return Found;
}

protected function Pawn GetFirstOfficerWithBSG(optional bool skipBreacher)
{
	local int i;
	local Pawn Officer;
	local Pawn Found;

	for(i = 0; i < OfficersInStackUpOrder.Length; i++) {
		Officer = OfficersInStackUpOrder[i];

		if(class'Pawn'.static.checkConscious(Officer) && CanOfficerBreachWithShotgun(Officer) && (!skipBreacher || Officer != Breacher)) {
			Found = Officer;
			break;
		}
	}

	return Found;
}

protected function bool ShouldThrowerBeFirstOfficer()
{
	return Super.ShouldThrowerBeFirstOfficer();
}

protected function SetBreacher(optional bool skipBreacher)
{
	local int BreachingMethod;

	BreachingMethod = SquadBreachAndClearGoal(achievingGoal).GetBreachingMethod();

	switch(BreachingMethod) {
		case 0: // first available
			Breacher = GetFirstOfficer();
			break;
		case 1: // C2
			Breacher = GetFirstOfficerWithC2(skipBreacher);
			break;
		case 2: // BreachingShotgun
			Breacher = GetFirstOfficerWithBSG(skipBreacher);
			break;
	}

	if(Breacher == None) {
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE);
	}

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
	log("SquadBreachAndClearAction::UseBreachingShotgun()");
	assert(Breacher != None);

	ISwatDoor(TargetDoor).RegisterInterestedInDoorOpening(self);

	CurrentUseBreachingShotgunGoal = new class'UseBreachingShotgunGoal'(AI_Resource(Breacher.characterAI), TargetDoor);
	assert(CurrentUseBreachingShotgunGoal != None);
	CurrentUseBreachingShotgunGoal.AddRef();

	CurrentUseBreachingShotgunGoal.postGoal(self);

	WaitForGoal(CurrentUseBreachingShotgunGoal);

	CurrentUseBreachingShotgunGoal.unPostGoal(self);

	CurrentUseBreachingShotgunGoal.Release();
	CurrentUseBreachingShotgunGoal = None;

	// have him open the door
	CurrentOpenDoorGoal = new class'OpenDoorGoal'(AI_Resource(Breacher.MovementAI), TargetDoor);
	assert(CurrentOpenDoorGoal != None);
	CurrentOpenDoorGoal.AddRef();

	CurrentOpenDoorGoal.SetPreferSides();

	CurrentOpenDoorGoal.postGoal(self);

	// if the thrower is not the same as the breacher, wait for the door to open
	if(Thrower != Breacher)
	{
		WaitForGoal(CurrentOpenDoorGoal);
		CurrentOpenDoorGoal.unPostGoal(self);

		CurrentOpenDoorGoal.Release();
		CurrentOpenDoorGoal = None;
	}
	else
	{
		// pause to wait for the detonator to be equipped
		pause();

		// prepare the grenade
		PreTargetDoorBreached();

		// just wait for the door to open
		while (TargetDoor.IsClosed() /*&& ! ISwatDoor(TargetDoor).IsBroken()*/ && !TargetDoor.IsOpening())
			yield();

	}
}

protected function bool CanOfficerBreachWithC2(Pawn Officer)
{
	local ISwatDoor SwatDoorTarget;
	local bool bIsChargeAlreadyPlacedOnDoor;
	local HandheldEquipment Equipment;

	assert(class'Pawn'.static.checkConscious(Officer));

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	if(SwatDoorTarget.IsOpen()) { return false; }

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

	if(Breacher == GetFirstOfficer())
	{
		SafeLocation = StackUpPoints[0];
	}
	else if(Breacher == GetSecondOfficer())
	{
		SafeLocation = StackUpPoints[1];
	}
	else if(Breacher == GetThirdOfficer())
	{
		SafeLocation = StackUpPoints[2];
	}
	else if(Breacher == GetFourthOfficer())
	{
		SafeLocation = StackUpPoints[3];
	}
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
		while (TargetDoor.IsClosed() /*&& ! ISwatDoor(TargetDoor).IsBroken()*/ && !TargetDoor.IsOpening())
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

	log("SquadBreachAndClearAction: Super.PrepareToMoveSquad(): Thrower = "$Thrower$", Breacher = "$Breacher);
    Super.PrepareToMoveSquad(true);

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	while ((SwatDoorTarget.IsLocked() || bForceBreachAction)/* && !SwatDoorTarget.IsBroken()*/ && !TargetDoor.IsOpening() && !TargetDoor.IsOpen())
	{
		if (CanOfficerBreachWithShotgun(Breacher))
		{
			log("CanOfficerBreachWithShotgun()");
			PreTargetDoorBreached();
			UseBreachingShotgun();	// <-- "WaitForZulu" happens here
			PostTargetDoorBreached();
		}
		else if (CanOfficerBreachWithC2(Breacher))
		{
			log("SquadBreachAndClearAction: PlaceAndUseBreachingCharge()");
			PlaceAndUseBreachingCharge();	// <-- "WaitForZulu" happens here
			log("SquadBreachAndClearAction: PostTargetDoorBreached()");
			PostTargetDoorBreached();
		}
		else
		{
			assert(DoesAnOfficerHaveUsableEquipment(Slot_Toolkit));

			log("SquadBreachAndClearAction: PreTargetDoorBreached()");
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

	// now try the first officer
	Officer = OfficersInStackupOrder[0];

	if (class'Pawn'.static.checkConscious(Officer))
	{
		if (ISwatOfficer(Officer).GetThrownWeapon(ThrownItemSlot) != None)
		{
			log("Officer to throw is: " $ Officer);
			return Officer;
		}
	}

	if (class'Pawn'.static.checkConscious(Breacher))
	{
		if (ISwatOfficer(Officer).GetThrownWeapon(ThrownItemSlot) != None)
		{
			//well shit, gotta find a new breacher
			SetBreacher(true);

			i=0;
			while(i<OfficersInStackupOrder.Length)
			{

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
		}
	}

	// didn't find an alive officer with the thrown weapon available
	return None;
}

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

				if (SecondOfficer != Breacher && Breacher != Thrower) {
					SwapOfficerRoles(OriginalThrower, SecondOfficer);
				}
				SwapStackUpPositions(OriginalThrower, SecondOfficer);
			}
		}
	}
}

protected latent function PreTargetDoorBreached();
protected latent function PostTargetDoorBreached();

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadBreachAndClearGoal'
}
