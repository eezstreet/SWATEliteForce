///////////////////////////////////////////////////////////////////////////////
// LaunchGrenadeAction.uc - LaunchGrenadeAction class
// this action causes an AI to launch a grenade instead of throwing it

class LaunchGrenadeAction extends UseGrenadeAction
	config(AI);
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// equipment we use
var private SwatWeapon GrenadeLauncher;
var private AimAtPointGoal CurrentAimAtPointGoal;

// internal
var private bool								bContinueToThrowGrenade;

// copied from our goal
var(parameters) vector							vTargetLocation;
var(parameters) EquipmentSlot					GrenadeSlot;
var(parameters) bool							bWaitToThrowGrenade;
var(parameters) IInterestedGrenadeThrowing		ThrowClient;

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	ISwatAI(m_Pawn).SetGrenadeTargetLocation(vTargetLocation);
}

function cleanup()
{
	super.cleanup();

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();

	// unregister
	if (ThrowClient != None)
	{
		GrenadeLauncher.UnRegisterInterestedGrenadeThrowing(ThrowClient);
	}
}

function float selectionHeuristic(AI_Goal Goal)
{
	local UseGrenadeGoal TheGoal;
	local ISwatOfficer Officer;

	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_WeaponResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	TheGoal = UseGrenadeGoal(Goal);
	Officer = ISwatOfficer(m_Pawn);

	if(Officer.HasLauncherWhichFires(TheGoal.GetGrenadeSlot()))
	{
		return 1.0; // use this one!
	}
	return 0.0;	// use the throw grenade action instead
}

///////////////////////////////////////////////////////////////////////////////

function SetContinueToThrowGrenade()
{
	bContinueToThrowGrenade = true;
}

///////////////////////////////////////////////////////////////////////////////
//
//	State code

function TriggerReportedDeployingGrenadeLauncherSpeech()
{
	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerDeployingGrenadeLauncherSpeech();
}

latent function AimLauncherAtPoint()
{
    CurrentAimAtPointGoal = new class'AimAtPointGoal'(weaponResource(), achievingGoal.priority, vTargetLocation);
    assert(CurrentAimAtPointGoal != None);
    CurrentAimAtPointGoal.AddRef();

    CurrentAimAtPointGoal.postGoal(self);
}

private latent function CheckAmmunition()
{
	assert(GrenadeLauncher != None);
	assert(GrenadeLauncher.IsEquipped());

	if (GrenadeLauncher.NeedsReload())
	{
		if (GrenadeLauncher.CanReload())
		{
			GrenadeLauncher.LatentReload();
		}
		else
		{
			instantFail(ACT_NO_WEAPONS_AVAILABLE);
		}
	}
}

latent function EquipGrenadeLauncher()
{
	local ISwatOfficer Officer;

	Officer = ISwatOfficer(m_Pawn);

	GrenadeLauncher = SwatWeapon(Officer.GetLauncherWhichFires(GrenadeSlot));

	if(GrenadeLauncher == None)
	{
		instantFail(ACT_NO_WEAPONS_AVAILABLE);
	}

	if (!GrenadeLauncher.IsEquipped())
    {
        GrenadeLauncher.LatentWaitForIdleAndEquip();
    }

	CheckAmmunition();

	Officer.SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_UseBreachingShotgunAction);
}

latent function ShootGrenadeLauncher()
{
	ISwatAI(m_Pawn).SetWeaponTargetLocation(vTargetLocation);

	if (ThrowClient != None)
	{
		GrenadeLauncher.RegisterInterestedGrenadeThrowing(ThrowClient);
	}

    // @NOTE: Pause for a brief moment before shooting to make the shot look
    // more deliberate
    Sleep(1.0);

	CheckAmmunition();

	GrenadeLauncher.SetPerfectAimNextShot();

	GrenadeLauncher.LatentUse();
}

private function StopAiming()
{
	if (CurrentAimAtPointGoal != None)
	{
		CurrentAimAtPointGoal.unPostGoal(self);
		CurrentAimAtPointGoal.Release();
		CurrentAimAtPointGoal = None;
	}
}

state Running
{
Begin:
	TriggerReportedDeployingGrenadeLauncherSpeech();
	AimLauncherAtPoint();
	EquipGrenadeLauncher();

	if (ThrowClient != None)
	{
		ThrowClient.NotifyGrenadeReadyToThrow();
	}

	// wait if we're supposed to, we will be notified when to throw the grenade
	if (bWaitToThrowGrenade)
	{
		PlayNodAnimation();

		// only pause if we're supposed to
		if (! bContinueToThrowGrenade)
			pause();
	}

	ShootGrenadeLauncher();
	StopAiming();

	ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

	Succeed();
}

defaultproperties
{
	satisfiesGoal = class'UseGrenadeGoal'
}
