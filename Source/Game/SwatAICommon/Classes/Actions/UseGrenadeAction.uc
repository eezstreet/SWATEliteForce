///////////////////////////////////////////////////////////////////////////////
// UseGrenadeAction.uc - UseGrenadeAction class
// this action that causes the AI to throw a grenade at a particular target

class UseGrenadeAction extends SwatWeaponAction
	config(AI);
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// equipment we use
var private ThrownWeapon						GrenadeWeapon;

// internal
var private bool								bContinueToThrowGrenade;

// copied from our goal
var(parameters) vector							vTargetLocation;
var(parameters) EquipmentSlot					GrenadeSlot;
var(parameters) bool							bWaitToThrowGrenade;
var(parameters) IInterestedGrenadeThrowing		ThrowClient;

// config
var private config name							NodAnimation;

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

//	log("UseGrenadeAction cleanup - GrenadeWeapon is:" $GrenadeWeapon);
	if ((GrenadeWeapon != None) && ! GrenadeWeapon.IsIdle())
	{
//		log("calling ai interrupt on the grenade weapon " $ GrenadeWeapon);
		GrenadeWeapon.AIInterrupt();
	}

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();

	// unregister
	if (ThrowClient != None)
	{
		GrenadeWeapon.UnRegisterInterestedGrenadeThrowing(ThrowClient);
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
		return 0.0; // we use the grenade launcher one instead
	}
	return 1.0;	// use this one !
}

///////////////////////////////////////////////////////////////////////////////

function SetContinueToThrowGrenade()
{
	bContinueToThrowGrenade = true;
}

///////////////////////////////////////////////////////////////////////////////

private function float GetThrowSpeed(float ThrowAngle, vector ThrowOrigin)
{
	local float Distance, Grav, SinValue, ProjectileSpeed;

	Distance = VSize(vTargetLocation - ThrowOrigin);

	// we need a speed (for perfect aiming, of course)
    // R = (vi^2 / g) * (sin 2 theta)
    // (R / (sin 2 theta)) * g = vi^2
    // vi = sqrt((R / sin 2 theta) * g)
    Grav            = - m_Pawn.PhysicsVolume.Gravity.Z * 0.5;            // multiplied by 0.5 cause unreal's use of gravity in UnPhysic.cpp is real strange

	SinValue        = sin(2 * ThrowAngle * (Pi / 180.0));
	ProjectileSpeed = Sqrt((Distance / SinValue) * Grav);

//	log("ProjectileSpeed:"@ProjectileSpeed@" SinValue:"@SinValue@" Grav:"@Grav@" ThrowAngle:"@ThrowAngle);

	return ProjectileSpeed;
}

private function PrepareToThrowGrenade()
{
	local float ThrowAngle, ThrowSpeed;
	local vector InitialLocation;
	local rotator InitialRotation;

	ICanThrowWeapons(m_Pawn).GetThrownProjectileParams(InitialLocation, InitialRotation);
	ThrowAngle = ISwatAI(m_Pawn).GetThrowAngle() * RADIANS_TO_TWOBYTE;

	ThrowSpeed = GetThrowSpeed(ThrowAngle, InitialLocation);
	GrenadeWeapon.SetThrowSpeed(ThrowSpeed);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function EquipGrenade()
{
	GrenadeWeapon = ISwatOfficer(m_Pawn).GetThrownWeapon(GrenadeSlot);
	assert(GrenadeWeapon != None);

	GrenadeWeapon.LatentWaitForIdleAndEquip();
}

latent function ThrowGrenade()
{
	PrepareToThrowGrenade();

	if (ThrowClient != None)
	{
		GrenadeWeapon.RegisterInterestedGrenadeThrowing(ThrowClient);
	}

	GrenadeWeapon.LatentUse();
}

protected latent function PlayNodAnimation()
{
	local int SpecialChannel;

	SpecialChannel = m_Pawn.AnimPlaySpecial(NodAnimation, 0.1, ISwatAI(m_Pawn).GetUpperBodyBone());
	m_Pawn.FinishAnim(SpecialChannel);
}

state Running
{
 Begin:
	EquipGrenade();

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

	ThrowGrenade();

	ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

	succeed();
}

defaultproperties
{
	satisfiesGoal = class'UseGrenadeGoal'
}
