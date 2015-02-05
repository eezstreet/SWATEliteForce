///////////////////////////////////////////////////////////////////////////////
// SweepWeaponIdleAction.uc - SweepWeaponIdleAction class
// A procedural Idle action that causes the weapon to sweep betwee two points
// of interest

class SweepWeaponIdleAction extends ProceduralIdleAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private AimAroundGoal CurrentAimAroundGoal;

///////////////////////////////////////////////////////////////////////////////
//
// cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function SweepWeapon()
{
    CurrentAimAroundGoal = new class'AimAroundGoal'(weaponResource());
    assert(CurrentAimAroundGoal != None);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.SetAimInnerFovDegrees(60.0);
	CurrentAimAroundGoal.SetAimOuterFovDegrees(120.0);
	CurrentAimAroundGoal.SetDoOnce(true);

	// post the aim around goal and wait for it to do one aim
    CurrentAimAroundGoal.postGoal(self);
	WaitForGoal(CurrentAimAroundGoal);
    CurrentAimAroundGoal.unPostGoal(self);

	CurrentAimAroundGoal.Release();
	CurrentAimAroundGoal = None;
}

state Running
{
 Begin:
    // now sweep the weapon
    SweepWeapon();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
