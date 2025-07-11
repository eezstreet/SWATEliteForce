///////////////////////////////////////////////////////////////////////////////
// AttackTargetAction.uc - AttackTargetAction class
// The action that causes the weapon resource to shoot a particular target with
// the current weapon, then finish
//
// some ideas come from Marc Atkin's AI_WeaponFireAt behavior in Tribes

class AttackTargetAction extends SwatWeaponAction implements ISensorNotification
	config(AI)
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;
import enum FireMode from Engine.FiredWeapon;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(Parameters) Actor		Target;
var(Parameters) Pawn		TargetPawn;
var(Parameters) float		ChanceToSucceedAfterFiring;
var(Parameters) bool		bHavePerfectAim;
var(Parameters) bool		bOrderedToAttackTarget;
var(Parameters) float		WaitTimeBeforeFiring;
var(Parameters) bool        bSuppressiveFire;

// sensor we use to determine if we can hit the target
var private   TargetSensor	TargetSensor;

// internal
var private bool			bCanHitTarget;
var private bool            bIgnoreCanHit;
var private float			TimeToStopTryingToAim;
var private FiredWeapon		OtherWeapon;		// currently unequipped weapon

var private float			StartActionTime;
var private int             ShotsFired;

// config
var config float			MaximumTimeToWaitToAttack;
var config float            MaxRangeForLessLethal;

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	assert(m_Pawn != None);

	// set the initial amount of time
	SetTimeToStopTryingToAttack();

	// set bIgnoreCanHit
	bIgnoreCanHit = ISwatAI(m_Pawn).FireWhereAiming() || bSuppressiveFire;

	ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AttackTargetAction);
}

function cleanup()
{
	local FiredWeapon CurrentWeapon;

	super.cleanup();

	if ( TargetSensor != None )
	{
		TargetSensor.deactivateSensor( self );
		TargetSensor = None;
	}

	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
	if (CurrentWeapon != None)
	{
		if (!CurrentWeapon.IsIdle())
		{
			CurrentWeapon.AIInterrupt();
		}
	}

    // @HACK: See comments in ISwatAI::UnlockAim for more info.
    ISwatAI(m_pawn).UnlockAim();
    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_AttackTargetAction);
	ISwatEnemy(m_Pawn).UnBecomeAThreat(true, 3.0f);
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensors

private function ActivateTargetSensor()
{
	assert(Target != None);

	TargetSensor = TargetSensor(class'AI_Sensor'.static.activateSensor( self, class'TargetSensor', characterResource(), 0, 1000000 ));
	assert(TargetSensor != None);

	TargetSensor.setParameters( Target );
}

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if (m_Pawn.logTyrion)
		log("AttackTargetAction received sensor message from " $ sensor.name $ " value is "$ value.objectData);

	bCanHitTarget = true;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function bool AllowedToUseWeapon(FiredWeapon DesiredWeapon)
{
	return ISwatAI(m_Pawn).GetCommanderAction().AllowedToUseWeaponAgainst(DesiredWeapon, TargetPawn, ShotsFired);
}

// Determines whether we should continue firing upon the subject
function bool ShouldContinueFiringUponTarget()
{
	local FiredWeapon CurrentWeapon, OtherWeapon;

	if (TargetPawn != None)
	{
		CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
		OtherWeapon = GetOtherWeapon();

		if (!class'Pawn'.static.checkConscious(m_Pawn))
		{	// Not if we're dead...!
			return false;
		}
		else if (TargetPawn == None || !class'Pawn'.static.checkConscious(TargetPawn))
		{	// ...or if the target is dead...!
			return false;
		}
		else if (!AllowedToUseWeapon(CurrentWeapon) && !AllowedToUseWeapon(OtherWeapon))
		{
			return false;
		}
	}

	return true;
}

// takes care of reloading, equipping, etc.
latent function ReadyWeapon()
{
	local FiredWeapon CurrentWeapon, PendingWeapon;

    CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
    OtherWeapon = GetOtherWeapon();
	
	// if we don't have a weapon equipped, first check and see if an item is being equipped
//	log(m_Pawn.Name $ " current weapon: " $ CurrentWeapon);
	if (CurrentWeapon == None)
	{
		PendingWeapon = FiredWeapon(m_Pawn.GetPendingItem());
//		log("PendingWeapon is: " $ PendingWeapon);

		if (PendingWeapon != None)
		{
			while (PendingWeapon.IsBeingEquipped())
			{
//				log("PendingWeapon is being equipped");
				yield();
			}

//			log("PendingWeapon IsEquipped: " $ PendingWeapon.IsEquipped());
			if (PendingWeapon.IsEquipped())
			{
				CurrentWeapon = PendingWeapon;

				// Become a threat after the suspect draws their weapon
				if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None))
				{
					ISwatEnemy(m_Pawn).BecomeAThreat();
				}
			}
		}
	}

	// if we don't have a weapon equipped, or if our current weapon is empty
    if (CurrentWeapon == None || !AllowedToUseWeapon(CurrentWeapon))
    {
        // we can't do anything if we're already using our backup, or don't have a backup
    	if (OtherWeapon == None || !AllowedToUseWeapon(OtherWeapon))
    	{
    		fail(ACT_NO_WEAPONS_AVAILABLE);
    		return;
    	}

		// switch our weapons
        SwitchWeapons();
    }
}

// allows us to set a firemode before attacking
// Ask each AI for their default fire mode
function SetFireMode(FiredWeapon CurrentWeapon)
{
	local FireMode DesiredFireMode;
	assert(CurrentWeapon != None);

	// Override the default fire mode if we are using suppressive fire.
	if (bSuppressiveFire && CurrentWeapon.HasFireMode(FireMode_Auto))
	{
		DesiredFireMode = FireMode_Auto;
	}
	else if (bSuppressiveFire && CurrentWeapon.HasFireMode(FireMode_Burst))
	{
		DesiredFireMode = FireMode_Burst;
	}
	else
	{
		DesiredFireMode = ISwatAI(m_Pawn).GetDefaultAIFireModeForWeapon(CurrentWeapon);
	}

	CurrentWeapon.SetCurrentFireMode(DesiredFireMode);
}

private function bool ShouldSucceed()
{
	// die roll to see if we should complete
	return (FRand() < ChanceToSucceedAfterFiring);
}

latent function AttackTarget(bool WaitForAiming)
{
	local FiredWeapon CurrentWeapon;

	StartActionTime = Level.TimeSeconds;
	ReadyWeapon();

	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
	if (CurrentWeapon == None || !AllowedToUseWeapon(CurrentWeapon))
	{
		instantFail(ACT_NO_WEAPONS_AVAILABLE);
		return;
	}

	if (CurrentWeapon.NeedsReload() && CurrentWeapon.CanReload())
	{
		CurrentWeapon.LatentReload();
	}
	
	//better non-lethal aim
	if (!bHavePerfectAim)
		AimAtActor(Target);
	else
		AimAtPoint(Pawn(Target).GetHeadLocation());
	
	ISwatAI(m_Pawn).LockAim();

	// Interrupt anything the weapon is doing
	if (!CurrentWeapon.IsIdle())
	{
		CurrentWeapon.AIInterrupt();
	}

	if (ISwatAI(m_Pawn).AnimCanAimAtDesiredActor(Target))
	{
		// make sure the correct aim behavior is set (in case it got unset when we couldn't aim at the desired target)
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AttackTargetAction);

		if (bHavePerfectAim)
		{
			CurrentWeapon.SetPerfectAimNextShot();
		}

		if (!WaitForAiming)
		{
			AimAndFireAtTarget(CurrentWeapon);
		}
		else
		{
			ShootInAimDirection(CurrentWeapon);
		}

		// Become a threat now
		if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None))
		{
			ISwatEnemy(m_Pawn).BecomeAThreat();
		}

		if (ShouldSucceed())
		{
			instantSucceed();
		}
		else
		{
			sleep(ISwatAI(m_Pawn).GetTimeToWaitBetweenFiring(CurrentWeapon));
		}
	}
	else if (ISwatAI(m_pawn).AnimIsWeaponAimSet())
	{
	    // if the weapon is currently aiming, but we can't hit the target, turn off upper body animation
		// Don't. This might add a delay that gives suspects the upper hand.
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AttackTargetAction);
	}

	ISwatAI(m_pawn).UnlockAim();
}

protected latent function AimAndFireAtTarget(FiredWeapon CurrentWeapon)
{
	local float TimeElapsed;
	local float MandatedWait;
	// allows us to change our fire mode
	SetFireMode(CurrentWeapon);

	if (WaitTimeBeforeFiring > 0)
		Sleep(WaitTimeBeforeFiring);

	// suspects don't care if they need to acquire a target perfectly
	if(m_Pawn.IsA('SwatEnemy'))
	{
		LatentAimAtActor(Target, ISwatAI(m_Pawn).GetTimeToWaitBeforeFiring());
	}
	else
	{	// SWAT need perfect aim!
		LatentAimAtActor(Target);
	}

	// Make sure we wait a minimum of MandatedWait before firing, so shooting isn't instant
	TimeElapsed = Level.TimeSeconds - StartActionTime;
	MandatedWait = ISwatAI(m_Pawn).GetTimeToWaitBeforeFiring();
	if(TimeElapsed < MandatedWait) 
	{
		Sleep(MandatedWait - TimeElapsed);
	}

  	ShootWeaponAt(Target);
  	ShotsFired++;
}

protected latent function ShootInAimDirection(FiredWeapon CurrentWeapon)
{
	local float TimeElapsed;
	local float MandatedWait;
	// allows us to change our fire mode
	SetFireMode(CurrentWeapon);

	if (WaitTimeBeforeFiring > 0)
		Sleep(WaitTimeBeforeFiring);
		
		LatentAimAtActor(Target);
		
	// Make sure we wait a minimum of MandatedWait before firing, so shooting isn't instant
	TimeElapsed = Level.TimeSeconds - StartActionTime;
	MandatedWait = ISwatAI(m_Pawn).GetTimeToWaitBeforeFiring();
	if(TimeElapsed < MandatedWait) 
	{
		Sleep(MandatedWait - TimeElapsed);
	}

	ShootWeaponAt(Target);	// (actual shooting in aim direction is handled in "GetAimRotation"
	ShotsFired++;
}

private function AimAtLastSeenPosition()
{
	local AIKnowledge.KnowledgeAboutPawn TargetKnowledge;
	if (ISwatAI(m_Pawn).GetKnowledge().GetLastKnownKnowledgeAboutPawn(TargetPawn, TargetKnowledge))
	{
		AimAtPoint(TargetKnowledge.location);
	}
}

// returns true if the target is none, not an enemy, an enemy that is a threat, or if we've been ordered to attack (with a non-lethal)
// returns false otherwise
private function bool IsTargetAThreat()
{
	return ((TargetPawn == None) || !TargetPawn.IsA('SwatEnemy') || (ISwatEnemy(TargetPawn).IsAThreat() || bOrderedToAttackTarget ||
		TargetPawn.IsA('SwatFlusher') || TargetPawn.IsA('SwatEscaper') ));
}

private function SetTimeToStopTryingToAttack()
{
	assert(Level != None);

	TimeToStopTryingToAim = Level.TimeSeconds + MaximumTimeToWaitToAttack;

}

private function LogForOfficer(string logText)
{
	if(m_Pawn.IsA('SwatOfficer'))
	{
		Log(logText);
	}
}

state Running
{
 Begin:
	ShotsFired = 0;

	ActivateTargetSensor();

	// we're going to attack, so we might as well have a ready weapon when it comes time.
	ReadyWeapon();

	while (ShouldContinueFiringUponTarget())
	{
		// Check ReadyWeapon again here
		ReadyWeapon();

		if ( targetSensor.queryObjectValue() == None && !bIgnoreCanHit )
		{
			ISwatAI(m_Pawn).GetCommanderAction().FindBetterEnemy();

			AimAtLastSeenPosition();

			bCanHitTarget = false;
			while (!bCanHitTarget && (Level.TimeSeconds < TimeToStopTryingToAim))
				yield();

			if (Level.TimeSeconds >= TimeToStopTryingToAim)
			{
				instantFail(ACT_TIME_LIMIT_EXCEEDED);
			}
		}

		if (!ShouldContinueFiringUponTarget())
		{
			break;
		}

		AttackTarget(bIgnoreCanHit);
		yield();
	}

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'AttackTargetGoal'
    MaxRangeForLessLethal = 512.0f
}
