class NoWeapon extends RoundBasedWeapon config(SwatEquipment);

function OnGivenToOwner()
{
	SetAvailable(false);
}

simulated function EquippedHook()
{
	// Switch to another piece of equipment
	if(SwatGamePlayerController(Pawn(Owner).Controller) != None)
	{	// for the player
		SwatGamePlayerController(Pawn(Owner).Controller).EquipNextSlot();
	}
	else
	{
		ISwatOfficer(Pawn(Owner)).ReEquipFiredWeapon();
	}
}

simulated function bool CanReload()
{
	return false;
}

simulated function bool IsEmpty()
{
	return true;
}

simulated function bool IsFull()
{
	return false;
}

simulated function bool NeedsReload()
{
	return false;
}

simulated function bool ShouldReload()
{
	return false;
}
