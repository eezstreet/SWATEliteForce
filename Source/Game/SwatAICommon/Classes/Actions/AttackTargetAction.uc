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
var private float			TimeToStopTryingToAttack;
var private FiredWeapon		OtherWeapon;		// currently unequipped weapon

var private float			StartActionTime;
var private int             ShotsFired;

// config
var config float			MaximumTimeToWaitToAttack;

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	assert(m_Pawn != None);

	// set the initial amount of time
	SetTimeToStopTryingToAttack();

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

// takes care of reloading, equipping, etc.
latent function ReadyWeapon()
{
	local FiredWeapon CurrentWeapon, PendingWeapon;

    CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
	
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None))
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
	}
	
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
			}
		}
	}

	// if we don't have a weapon equipped, or if our current weapon is empty
    if ((CurrentWeapon == None) || CurrentWeapon.IsEmpty())
    {
        // we can't do anything if we're already using our backup, or don't have a backup
        if ((GetBackupWeapon() == None) || (CurrentWeapon == GetBackupWeapon()))
        {
			fail(ACT_NO_WEAPONS_AVAILABLE);
			return;
        }

		// switch our weapons
        SwitchWeapons();
    }

	// switch back to primary weapon if it wasn't empty and we were temporarily using less-lethal
	if (CurrentWeapon == GetBackupWeapon() && CurrentWeapon.IsLessLethal() && !GetPrimaryWeapon().IsEmpty())
	{
		SwitchWeapons();
	}
}

// allows us to set a firemode before attacking
// Ask each AI for their default fire mode
function SetFireMode(FiredWeapon CurrentWeapon)
{
	local FireMode DesiredFireMode;
	assert(CurrentWeapon != None);

	DesiredFireMode = ISwatAI(m_Pawn).GetDefaultAIFireModeForWeapon(CurrentWeapon);
	CurrentWeapon.SetCurrentFireMode(DesiredFireMode);
}

private function bool ShouldSucceed()
{
	// die roll to see if we should complete
	return (FRand() < ChanceToSucceedAfterFiring);
}

latent function AttackTarget()
{
  	local FiredWeapon CurrentWeapon;

	if(Target == None) {
		instantFail(ACT_INSUFFICIENT_RESOURCES_AVAILABLE); // Possibly fixes a bug (?)
	}

	StartActionTime = Level.TimeSeconds;

	ReadyWeapon();

  	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

	// we should have a weapon before we continue
	if (CurrentWeapon == None)
		instantFail(ACT_NO_WEAPONS_AVAILABLE);

	if (m_Pawn.LogTyrion)
		log(m_Pawn.Name $ " AttackTargetAction::AttackTarget - CurrentWeapon: " $ CurrentWeapon.Name $ " NeedsReload: " $ CurrentWeapon.NeedsReload() $ " CanReload: " $ CurrentWeapon.CanReload());

  	// if our current weapon is empty, and can reload, reload
  	if (CurrentWeapon.NeedsReload() && CurrentWeapon.CanReload())
  	{
		CurrentWeapon.LatentReload();
  	}
	else if (CurrentWeapon.IsEmpty())
	{
		instantFail(ACT_NO_WEAPONS_AVAILABLE);
	}

    ISwatAI(m_pawn).UnLockAim();
	AimAtActor(Target);
    // @HACK: See comments in ISwatAI::LockAim for more info.
    ISwatAI(m_pawn).LockAim();

	// interrupt anything the weapon is doing if it's not idle, we need to fire.
	if(! CurrentWeapon.IsIdle())
	{
		CurrentWeapon.AIInterrupt();
	}

  	// wait until we can hit the target (make sure the target is still conscious too!)
  	while(!bSuppressiveFire && !m_Pawn.CanHit(Target) && ((TargetPawn == None) || class'Pawn'.static.checkConscious(TargetPawn)))
  	{
		if (m_Pawn.logTyrion)
			log(m_Pawn.Name $ " is waiting to be able to hit target " $ TargetPawn);

    	yield();
  	}

  // if we can aim at the target
  if (ISwatAI(m_pawn).AnimCanAimAtDesiredActor(Target))
  {
		// make sure the correct aim behavior is set (in case it got unset when we couldn't aim at the desired target)
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AttackTargetAction);

		if (bHavePerfectAim)
			CurrentWeapon.SetPerfectAimNextShot();

		AimAndFireAtTarget(CurrentWeapon);

		if (ShouldSucceed())
		{
			instantSucceed();
		}
		else
		{
			// wait until we can use the weapon again
			sleep(ISwatAI(m_Pawn).GetTimeToWaitBetweenFiring(CurrentWeapon));
		}
  }
  else if (ISwatAI(m_pawn).AnimIsWeaponAimSet())
  {
      // if the weapon is currently aiming, but we can't hit the target, turn off upper body animation
	  // Don't. This might add a delay that gives suspects the upper hand.
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AttackTargetAction);
  }

  // @HACK: See comments in ISwatAI::UnlockAim for more info.
  ISwatAI(m_pawn).UnlockAim();
}

latent function WildGunnerAttackTarget()
{
    local FiredWeapon CurrentWeapon;	
	
	StartActionTime = Level.TimeSeconds;
	
	ReadyWeapon();

    CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

	// we should have a weapon before we continue
	if (CurrentWeapon == None)
		instantFail(ACT_NO_WEAPONS_AVAILABLE);

	if (m_Pawn.LogTyrion)
		log(m_Pawn.Name $ " AttackTargetAction::AttackTarget - CurrentWeapon: " $ CurrentWeapon.Name $ " NeedsReload: " $ CurrentWeapon.NeedsReload() $ " CanReload: " $ CurrentWeapon.CanReload());

    // if our current weapon is empty, and can reload, reload
    if (CurrentWeapon.NeedsReload() && CurrentWeapon.CanReload())
    {
		CurrentWeapon.LatentReload();
    }
	else if (CurrentWeapon.IsEmpty())
	{
		instantFail(ACT_NO_WEAPONS_AVAILABLE);
	}

    ISwatAI(m_pawn).UnLockAim();	// in case WildGunnerAdjustAimAction locked it when this code was executed
	AimAtActor(Target);
    // @HACK: See comments in ISwatAI::LockAim for more info.
    ISwatAI(m_pawn).LockAim();

	// interrupt anything the weapon is doing if it's not idle, we need to fire.
	if(! CurrentWeapon.IsIdle())
	{
		CurrentWeapon.AIInterrupt();
	}

	// if we can aim at the target
  if (ISwatAI(m_pawn).AnimCanAimAtDesiredActor(Target))
  {
		// make sure the correct aim behavior is set (in case it got unset when we couldn't aim at the desired target)
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AttackTargetAction);

		if (bHavePerfectAim)
			CurrentWeapon.SetPerfectAimNextShot();

	ShootInAimDirection(CurrentWeapon);

		if (ShouldSucceed())
		{
			instantSucceed();
		}
		else
		{
			// wait until we can use the weapon again
			sleep(ISwatAI(m_Pawn).GetTimeToWaitBetweenFiring(CurrentWeapon));
		}
  }
  else if (ISwatAI(m_pawn).AnimIsWeaponAimSet())
  {
  	// make sure the correct aim behavior is set (in case it got unset when we couldn't aim at the desired target)
	ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AttackTargetAction);  
  }
    // @HACK: See comments in ISwatAI::UnlockAim for more info.
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

private function bool ShouldContinueAttackingWithLessLethal()
{
	local FiredWeapon Item;

	if(ISwatAI(TargetPawn).IsCompliant() || ISwatAI(TargetPawn).IsArrested())
	{
		return false; // Don't shoot at compliant or arrested people
	}

	Item = FiredWeapon(m_Pawn.GetActiveItem());
	if(Item == None || !Item.IsLessLethal() || Item.IsA('Taser')   						|| // Don't tase people, it can kill
		(Item.IsA('CSBallLauncher') && ISwatAI(target).IsGassed()) 						|| // Pepperball is uselss on already gassed people
		(Item.IsA('BeanbagShotgunBase') && ShotsFired > 2 && ISwatAI(target).IsStung()) || // Only shoot three times with the beanbag shotgun.
		(Item.IsA('GrenadeLauncherBase')))                            					   // Don't use the grenade launcher. It's stupid.
	{
		return false;
	}

	return true; // Keep attacking I guess?
}

private function SetTimeToStopTryingToAttack()
{
	assert(Level != None);

	TimeToStopTryingToAttack = Level.TimeSeconds + MaximumTimeToWaitToAttack;
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
	if (m_Pawn.logTyrion )
		log( self.name $ " started " $ Name $ " at time " $ Level.TimeSeconds );

	ShotsFired = 0;

	LogForOfficer("AttackTargetAction: " $m_Pawn.name$" has started action.");

	ActivateTargetSensor();

	LogForOfficer("AttackTargetAction: "$m_Pawn.name$" has activated their target sensor.");

	// we're going to attack, so we might as well have a ready weapon when it comes time.
	ReadyWeapon();

	// switch to secondary weapon if shooting at a runner and current weapon is lethal
	if (TargetPawn != None && !FiredWeapon(m_Pawn.GetActiveItem()).IsLessLethal()
		&& (ISwatEnemy(TargetPawn) != None && !ISwatEnemy(TargetPawn).IsAThreat()))	// Don't shoot at them with a lethal weapon if they aren't a threat!!
	{
		OtherWeapon = GetOtherWeapon();
		if (Otherweapon != None && OtherWeapon.IsLessLethal() && !OtherWeapon.IsEmpty())
			SwitchWeapons();
	}

	while (class'Pawn'.static.checkConscious(m_Pawn) &&										// while we are conscious AND
		   ((TargetPawn == None) || class'Pawn'.static.checkConscious(TargetPawn)) &&		// the other person is conscious AND
		   (!m_Pawn.IsA('SwatOfficer') || TargetPawn.IsA('SwatPlayer') ||					// we are not a SWAT officer OR we are targetting the player, OR...
		   	IsTargetAThreat() || 															// the target is a threat (pointing gun at people, etc) OR
		   	(FiredWeapon(m_Pawn.GetActiveItem()).IsLessLethal() &&							// we are using a less lethal item
		   		ShouldContinueAttackingWithLessLethal())									// we should continue using that less lethal item
		   	))
	{
		if ( targetSensor.queryObjectValue() == None )
		{
			if (m_Pawn.logTyrion)
				log(m_Pawn.Name $ " pausing because queryObjectValue == None");

			ISwatAI(m_Pawn).GetCommanderAction().FindBetterEnemy();

			AimAtLastSeenPosition();

			bCanHitTarget = false;
			while (!bCanHitTarget && (Level.TimeSeconds < TimeToStopTryingToAttack))
				yield();

			if (m_Pawn.logTyrion)
				log(m_Pawn.Name $ " was told to run");

			if (!class'Pawn'.static.checkConscious(TargetPawn))
			{
				if (m_Pawn.logTyrion )
					log( self.name $ " stopped. TARGET DEAD!" );
				succeed();
			}
			else if (Level.TimeSeconds >= TimeToStopTryingToAttack)
			{
				if (m_Pawn.logTyrion)
					log(self.Name $ " ran out of time to attack.  failing!");

				instantFail(ACT_TIME_LIMIT_EXCEEDED);
			}
		}

		SetTimeToStopTryingToAttack();
		if (ISwatAI(m_pawn).FireWhereAiming())
			WildGunnerAttackTarget();
		else
			AttackTarget();
		yield();
	}

	if (m_Pawn.logTyrion )
	{
		if ((TargetPawn != None) && ! class'Pawn'.static.checkConscious(TargetPawn))
			log(self.name $ " stopped because " $ TargetPawn.Name $ " isn't conscious at time " $ Level.TimeSeconds);
		else if (! class'Pawn'.static.checkConscious(m_Pawn))
			log(self.name $ " stopped because my pawn ("$m_Pawn.Name$") isn't conscious at time " $ Level.TimeSeconds);
		else if ((TargetPawn != None) && TargetPawn.IsA('SwatEnemy') && !ISwatEnemy(TargetPawn).IsAThreat())
			log(self.name $ " stopped because " $ TargetPawn.Name $ " isn't currently a threat at time " $ Level.TimeSeconds);
	}

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'AttackTargetGoal'
}
