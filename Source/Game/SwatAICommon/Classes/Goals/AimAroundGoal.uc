///////////////////////////////////////////////////////////////////////////////
// AimAroundGoal.uc - AimAroundGoal class
// The goal that causes the AI to aim around its location (somewhat randomly)
// in a natural fashion

class AimAroundGoal extends SwatWeaponGoal
	config(AI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////
//
// AimAroundGoal variables

// copied to our action
var(Parameters) private float		MinAimAtPointTime;
var(Parameters) private float		MaxAimAtPointTime;

var(Parameters) private float		MinWaitForNewPointTime;
var(Parameters) private float		MaxWaitForNewPointTime;

var(Parameters) private bool		bDoOnce;
var(Parameters) private bool		bOnlyAimIfMoving;
var(Parameters) protected float		ExtraDoorWeight;
var(Parameters) private bool		bAimWeapon;
var(Parameters) private bool		bUseUpperBodyProcedurally;
var(Parameters) private bool		bAimOnlyIfCharacterResourcesAvailable;

var(Parameters) private EUpperBodyAnimBehaviorClientId UpperBodyAnimBehaviorClientId;

// Points are weighted differently depending on whether the point is within
// the inner fov or the outer fov
var(Parameters) private float		AimInnerFovDot;
var(Parameters) private float		AimOuterFovDot;
var(Parameters) private float		PointTooCloseRadius;

var(Parameters) protected bool		bInitialDelay;
var(Parameters) protected float		MinInitialDelayTime;
var(Parameters) protected bool		MaxInitialDelayTime;

var(Parameters) public bool CancelWhenCompliant;
var(Parameters) public bool CancelWhenStunned;

// config variables
var config float					DefaultInnerFovDegrees;
var config float					DefaultOuterFovDegrees;

var config float					DefaultMinAimAtPointTime;
var config float					DefaultMaxAimAtPointTime;

var config float					DefaultMinWaitForNewPointTime;
var config float					DefaultMaxWaitForNewPointTime;

///////////////////////////////////////////////////////////////////////////////
//
// Constructors

overloaded function construct(AI_Resource r, optional int pri)
{
	// if the priority passed in is greater than 0 (the default), make it the priority of this behavior
	if (pri > 0)
		priority = pri;

    Super.construct(r, priority);

	assert(DefaultMinAimAtPointTime > 0.0);
	assert(DefaultMaxAimAtPointTime >= DefaultMinAimAtPointTime);

	MinAimAtPointTime = DefaultMinAimAtPointTime;
	MaxAimAtPointTime = DefaultMaxAimAtPointTime;

	MinWaitForNewPointTime = DefaultMinWaitForNewPointTime;
	MaxWaitForNewPointTime = DefaultMaxWaitForNewPointTime;

    // Default to a 90 degree aim fov
    SetAimInnerFovDegrees(DefaultInnerFovDegrees);
    SetAimOuterFovDegrees(DefaultOuterFovDegrees);
}

overloaded function construct(AI_Resource r, float inMinAimAtPointTime, float inMaxAimAtPointTime)
{
    Super.construct(r, priority);

	SetAimAtPointTime(inMinAimAtPointTime, inMaxAimAtPointTime);

    // Default to a 90 degree aim fov
    SetAimInnerFovDegrees(DefaultInnerFovDegrees);
    SetAimOuterFovDegrees(DefaultOuterFovDegrees);
}

///////////////////////////////////////////////////////////////////////////////
//
// Manipulators

function SetAimWeapon(bool inAimWeapon)
{
	bAimWeapon = inAimWeapon;
}

function SetDoOnce(bool inDoOnce)
{
	bDoOnce = inDoOnce;
}

function SetOnlyAimIfMoving(bool inOnlyAimIfMoving)
{
	bOnlyAimIfMoving = inOnlyAimIfMoving;
}

function SetExtraDoorWeight(float inExtraDoorWeight)
{
	ExtraDoorWeight = inExtraDoorWeight;
}

function SetAimInnerFovDegrees(float FovDegrees)
{
    AimInnerFovDot = SetAimFovDegrees(FovDegrees);
}

function SetAimOuterFovDegrees(float FovDegrees)
{
    AimOuterFovDot = SetAimFovDegrees(FovDegrees);
}

function SetAimAtPointTime(float inMinAimAtPointTime, float inMaxAimAtPointTime)
{
	assert(inMinAimAtPointTime > 0.0);
	assert(inMaxAimAtPointTime >= inMinAimAtPointTime);

	MinAimAtPointTime = inMinAimAtPointTime;
	MaxAimAtPointTime = inMaxAimAtPointTime;
}

private function float SetAimFovDegrees(float FovDegrees)
{
    // Halve the cone, and convert to dot product value
    FovDegrees /= 2.0;
    return Cos((FovDegrees / 180.0) * Pi);
}

// The "point too close radius" restricts a pawn from aiming at an awareness
// point that is within a certain distance from it. This can prevent the pawn
// from certain visual weirdness associated with aiming at an awareness point
// close to itself, while the pawn is moving.
function SetPointTooCloseRadius(float radius)
{
    PointTooCloseRadius = radius;
}

function SetCancelWhenCompliant(bool set)
{
	CancelWhenCompliant = set;
}

function SetCancelWhenStunned(bool set)
{
	CancelWhenStunned = set;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority = 35
    GoalName = "AimAround"

	MinAimAtPointTime = 2.0
	MaxAimAtPointTime = 5.0

    PointTooCloseRadius = 64.0
	bUseUpperBodyProcedurally = true
    UpperBodyAnimBehaviorClientId = kUBABCI_NonIdleAimAround
	bAimOnlyIfCharacterResourcesAvailable = false
}
