///////////////////////////////////////////////////////////////////////////////
// AimAtTargetGoal.uc - AimAtTargetGoal class
// The goal that causes the weapon resource to aim at a particular target with
// the current weapon

class AimAtTargetGoal extends SwatWeaponGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// AimAtTargetGoal variables

var(Parameters) private Actor    Target;
var(Parameters) private bool	 bOnlyWhenCanHitTarget;
var(Parameters) private bool	 bShouldFinishOnSuccess;
var(Parameters) private bool	 bAimWeapon;
var(Parameters) private bool	 bHoldAimForPeriodOfTime;
var(Parameters) private float	 HoldAimTime;
var(Parameters) private float	 MinDistanceToTargetToAim;

///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, Actor inTarget )
{
    Super.construct(r, priority);

    assert(inTarget != None);
    Target = inTarget;
}

overloaded function construct( AI_Resource r, int pri, Actor inTarget )
{
    Super.construct(r, pri);

    assert(inTarget != None);
    Target = inTarget;
}


///////////////////////////////////////////////////////////////////////////////

function SetAimOnlyWhenCanHitTarget(bool inOnlyAimWhenCanHitTarget)
{
	bOnlyWhenCanHitTarget = inOnlyAimWhenCanHitTarget;
}

function SetShouldFinishOnSuccess(bool inShouldFinishOnSuccess)
{
	bShouldFinishOnSuccess = inShouldFinishOnSuccess;
}

function SetAimWeapon(bool inAimWeapon)
{
	bAimWeapon = inAimWeapon;
}

overloaded function SetHoldAimTime(float inHoldAimTime)
{
	assert(inHoldAimTime >= 0.0);

	bHoldAimForPeriodOfTime = true;
	HoldAimTime = inHoldAimTime;
}

overloaded function SetHoldAimTime(float inMinHoldAimTime, float inMaxHoldAimTime)
{
	SetHoldAimTime(RandRange(inMinHoldAimTime, inMaxHoldAimTime));
}

function SetMinDistanceToTargetToAim(float inMinDistanceToTargetToAim)
{
	MinDistanceToTargetToAim = inMinDistanceToTargetToAim;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority = 75
    GoalName = "AimAtTarget"
	bOnlyWhenCanHitTarget = false
	bShouldFinishOnSuccess = false
	bAimWeapon = true
}

