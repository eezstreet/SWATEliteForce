///////////////////////////////////////////////////////////////////////////////
// AimAtTargetAction.uc - AimAtTargetAction class
// The action that causes the weapon resource to aim at a particular target with
// the current weapon

class AimAtTargetAction extends SwatWeaponAction
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;


// Copied from the goal
var(Parameters) private Actor    Target;
var(Parameters) private bool	 bOnlyWhenCanHitTarget;
var(Parameters) private bool	 bShouldFinishOnSuccess;
var(Parameters) private bool	 bAimWeapon;
var(Parameters) private bool	 bHoldAimForPeriodOfTime;
var(Parameters) private float	 HoldAimTime;
var(Parameters) private float	 MinDistanceToTargetToAim;

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function cleanup()
{
	super.cleanup();
    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_AimAtTargetAction);
}


///////////////////////////////////////////////////////////////////////////////
//
// Aim Mode Management

private function CheckAimingMode()
{
	if (bAimWeapon && m_Pawn.CanHit(Target))
	{
        ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_AimWeapon, kUBABCI_AimAtTargetAction);
	}
	else
	{
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_AimAtTargetAction);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function AimAtTarget()
{
    while (!bOnlyWhenCanHitTarget || (m_Pawn.CanHit(Target) && ((MinDistanceToTargetToAim == 0.0) || (VSize(Target.Location - m_Pawn.Location) < MinDistanceToTargetToAim))))
    {
        LatentAimAtActor(Target);
		yield();
    }
}

state Running
{
 Begin:
	// we no longer have a reference to the target, or it's died, so we can't do anything
	if ((Target == None) || (Target.IsA('Pawn') && !class'Pawn'.static.checkConscious(Pawn(Target))))
		succeed();

	CheckAimingMode();

    AimAtTarget();

	if (bShouldFinishOnSuccess)
	{
		// succeed when we can no longer aim at the target (if we should)
		succeed();
	}
	else if (bHoldAimForPeriodOfTime)
	{
		// succeed after aiming for a specified period of time
		sleep(HoldAimTime);
		succeed();
	}
	
	// else
	yield();
	goto('Begin');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'AimAtTargetGoal'
}