///////////////////////////////////////////////////////////////////////////////
// ThrowGrenadeGoal.uc - ThrowGrenadeGoal class
// this goal causes the AI to throw a grenade at a particular target
// does not do or cause movement, movement must be done by a prior goal
//  (possibly by using this goal in concert to throw a grenade)

class ThrowGrenadeGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum AIThrowSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) vector							TargetLocation;
var(parameters) vector							ThrowFromLocation;
var(parameters) EquipmentSlot					GrenadeSlot;
var(parameters) AIThrowSide						ThrowSide;
var(parameters) rotator							ThrowRotation;
var(parameters) bool							ThrowRotationOverridden;
var(parameters) bool							bWaitToThrowGrenade;
var(parameters) IInterestedGrenadeThrowing		ThrowClient;

const kBreachThrowGrenadeGoalPriority = 86;	// barely higher than the attack enemy or engage for compliance goals

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

// do not use this constructor!
overloaded function construct( AI_Resource r, int pri)	{ assert(false); }

// use this one
overloaded function construct( AI_Resource r, vector inTargetLocation, vector inThrowFromLocation, EquipmentSlot inGrenadeSlot, optional bool bIsBreachingThrow)
{
	if (bIsBreachingThrow)
		Priority = kBreachThrowGrenadeGoalPriority;

	super.construct( r, priority );

	TargetLocation    = inTargetLocation;
	ThrowFromLocation = inThrowFromLocation;
	GrenadeSlot	      = inGrenadeSlot;
}

///////////////////////////////////////////////////////////////////////////////
//
// Manipulators

function SetThrowRotation(Rotator inThrowRotation)
{
	ThrowRotation			= inThrowRotation;
	ThrowRotationOverridden = true;
}

function SetThrowSide(AIThrowSide inThrowSide)
{
	ThrowSide = inThrowSide;
}

function SetWaitToThrowGrenade(bool inWaitToThrowGrenade)
{
	bWaitToThrowGrenade = inWaitToThrowGrenade;
}

///////////////////////////////////////////////////////////////////////////////
//
// Clients

function RegisterForGrenadeThrowing(IInterestedGrenadeThrowing inThrowClient)
{
	ThrowClient = inThrowClient;
}

///////////////////////////////////////////////////////////////////////////////
//
// Grenade Throwing

function NotifyThrowGrenade()
{
	assert(bWaitToThrowGrenade == true);

	if (achievingAction != None)
	{
		ThrowGrenadeAction(achievingAction).NotifyThrowGrenade();
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 80
	goalName = "ThrowGrenade"
}
