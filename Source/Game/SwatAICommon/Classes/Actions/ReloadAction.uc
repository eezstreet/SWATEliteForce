///////////////////////////////////////////////////////////////////////////////

class ReloadAction extends SwatWeaponAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

function float selectionHeuristic( AI_Goal goal )
{
	local FiredWeapon CurrentWeapon;
	CurrentWeapon = FiredWeapon(goal.resource.pawn().GetActiveItem());
	
	if (CurrentWeapon != None)
	{
		if (CurrentWeapon.NeedsReload() && CurrentWeapon.CanReload())
		{
			return 1.0;
		}
	}

	// couldn't find anything
	return 0.0;
}

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