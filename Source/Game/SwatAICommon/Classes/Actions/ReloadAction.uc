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
		if ((m_Pawn.IsA('SwatOfficer')) && (CurrentWeapon.IsA('RoundBasedWeapon')) && (CurrentWeapon.Ammo.RoundsRemainingBeforeReload() <= 0.9*CurrentWeapon.Ammo.RoundsComparedBeforeReload()) && CurrentWeapon.CanReload())
		{
			return 1.0;
		}	
		if ((m_Pawn.IsA('SwatOfficer')) && (CurrentWeapon.IsA('ClipBasedWeapon')) && (CurrentWeapon.Ammo.RoundsRemainingBeforeReload() <= 0.9*CurrentWeapon.Ammo.RoundsComparedBeforeReload()) && CurrentWeapon.CanReload())
		{
			return 1.0;
		}
		else if ((m_Pawn.IsA('SwatOfficer')) && CurrentWeapon.ShouldReload() && CurrentWeapon.CanReload())
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
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'ReloadGoal'
}