///////////////////////////////////////////////////////////////////////////////
// SquadDeployShotgunAction.uc - SquadDeployShotgunAction class
// this action is used to organize the Officer's deploy shotgun behavior

class SquadDeployShotgunAction extends SquadStackUpAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private UseBreachingShotgunGoal CurrentUseBreachingShotgunGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentUseBreachingShotgunGoal != None)
	{
		CurrentUseBreachingShotgunGoal.Release();
		CurrentUseBreachingShotgunGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// FIXME: Define this somewhere higher up in the hierarchy so we aren't defining this twice
private function bool CanOfficerUseBreachingShotgun(Pawn Officer)
{
	local HandheldEquipment Equipment;
	local FiredWeapon Weapon;

	assert(class'Pawn'.static.checkConscious(Officer));

	Weapon = FiredWeapon(ISwatOfficer(Officer).GetItemAtSlot(SLOT_PrimaryWeapon));
	if(Weapon != None && Weapon.IsA('Shotgun') && (!Weapon.NeedsReload() || Weapon.CanReload()))
	{
		return true;
	}

	Weapon = FiredWeapon(ISwatOfficer(Officer).GetItemAtSlot(SLOT_SecondaryWeapon));
	if(Weapon != None && Weapon.IsA('Shotgun') && (!Weapon.NeedsReload() || Weapon.CanReload()))
	{
		return true;
	}

	return false;
}

// tells the first officer found with C2 to place it
latent function DeployShotgun()
{
	local Pawn Officer, BreachingOfficer;
	local int i, BreacherStackUpIndex;
	local StackUpPoint BreacherStackUpPoint;

	assert(OfficersInStackUpOrder.Length > 0);

	// try all the officers
	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		Officer = OfficersInStackUpOrder[i];

		if (CanOfficerUseBreachingShotgun(Officer))
		{
			BreacherStackUpIndex = i;
			BreachingOfficer     = Officer;
			break;
		}
	}

    if (BreachingOfficer != None)
    {
		// moves up the breacher (if they're not the first officer)
		MoveUpShotgunBreacher(BreachingOfficer);

	    // get the stack up point for the officer (our safe location)
	    BreacherStackUpPoint = StackUpPoints[BreacherStackUpIndex];
	    assert(BreacherStackUpPoint != None);

	    CurrentUseBreachingShotgunGoal = new class'UseBreachingShotgunGoal'(AI_Resource(BreachingOfficer.characterAI), TargetDoor, BreacherStackUpPoint);
	    assert(CurrentUseBreachingShotgunGoal != None);
	    CurrentUseBreachingShotgunGoal.AddRef();

	    CurrentUseBreachingShotgunGoal.postGoal(self);
	    WaitForGoal(CurrentUseBreachingShotgunGoal);
	    CurrentUseBreachingShotgunGoal.unPostGoal(self);

	    CurrentUseBreachingShotgunGoal.Release();
	    CurrentUseBreachingShotgunGoal = None;
    }
}

state Running
{
Begin:
	StackUpSquad(true);

	DeployShotgun();	//<-- WaitforZulu() happens in UseBreachingShotgun action
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadDeployShotgunGoal'
}
