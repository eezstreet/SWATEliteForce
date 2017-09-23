///////////////////////////////////////////////////////////////////////////////

class ReloadAction extends SwatWeaponAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

function float selectionHeuristic( AI_Goal goal )
{
	local FiredWeapon CurrentWeapon;
	local int WeaponClip;
	local int CurrentCapacity;
	local int CutOff;

	CurrentWeapon = FiredWeapon(goal.resource.pawn().GetActiveItem());
	WeaponClip = CurrentWeapon.Ammo.RoundsRemainingBeforeReload();
	CurrentCapacity = CurrentWeapon.Ammo.RoundsComparedBeforeReload();
	CutOff = 0.9;

	if (CurrentWeapon != None)
	{
		if ((m_Pawn.IsA('SwatOfficer')) && CurrentWeapon.ShouldReload() && CurrentWeapon.CanReload())
		{
			return 1.0;
		}
		else if (CurrentWeapon.NeedsReload() && CurrentWeapon.CanReload())
		{
			return 1.0;
		}
	}

	// couldn't find anything
	return 0.0;
}

private function bool IsWeaponFull()
{
	local FiredWeapon CurrentWeapon;

	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

	if (CurrentWeapon != None)
	{
		if ((m_Pawn.IsA('SwatOfficer')) && CurrentWeapon.ShouldReload() && CurrentWeapon.CanReload())
		{
			return false;
		}
		else if (CurrentWeapon.NeedsReload() && CurrentWeapon.CanReload())
		{
			return false;
		}
	}

	return true;
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function ReloadWeapon()
{
	local FiredWeapon CurrentWeapon;
	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

	// reload the weapon
    CurrentWeapon.LatentReload();
}

state Running
{
 Begin:
	ReloadWeapon();
	// Wait, if this thing loaded yet?
	// If it is good, if it's not, then reload again.
	if (IsWeaponFull())
	{
		yield();
	}
	else
	{
		goto('Begin');
	}
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'ReloadGoal'
}
