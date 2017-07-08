///////////////////////////////////////////////////////////////////////////////
// AttackTargetGoal.uc - AttackTargetGoal class
// The goal that causes the weapon resource to shoot a particular target with
// the current weapon, then finish

class AttackTargetGoal extends SwatWeaponGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// AttackTargetGoal variables

var(Parameters) Actor	Target;
var(Parameters) Pawn	TargetPawn;
var(Parameters) float	ChanceToSucceedAfterFiring;
var(Parameters) bool	bHavePerfectAim;
var(Parameters) bool	bOrderedToAttackTarget;
var(Parameters) float	WaitTimeBeforeFiring;

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
    Target     = inTarget;
	TargetPawn = Pawn(Target);
}

overloaded function construct( AI_Resource r, int pri, Actor inTarget )
{
    Super.construct(r, pri);

    assert(inTarget != None);
    Target     = inTarget;
	TargetPawn = Pawn(Target);
}

///////////////////////////////////////////////////////////////////////////////
// 
// Manipulators

function SetChanceToSucceedAfterFiring(float inChanceToSucceedAfterFiring)
{
	assert(inChanceToSucceedAfterFiring >= 0.0);
	assert(inChanceToSucceedAfterFiring <= 1.0);

	ChanceToSucceedAfterFiring = inChanceToSucceedAfterFiring;
}

function SetHavePerfectAim(bool inHavePerfectAim)
{
	bHavePerfectAim = inHavePerfectAim;
}

function SetOrderedToAttackTarget(bool inOrderedToAttackTarget)
{
	bOrderedToAttackTarget = inOrderedToAttackTarget;
}

function SetWaitTimeBeforeFiring(float inWaitTime)
{
	WaitTimeBeforeFiring = inWaitTime;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority = 80
    GoalName = "AttackTarget"

	WaitTimeBeforeFiring = 0
}

