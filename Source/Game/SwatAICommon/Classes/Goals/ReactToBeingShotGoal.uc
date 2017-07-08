///////////////////////////////////////////////////////////////////////////////
// ReactToBeingShotGoal.uc - ReactToBeingShotGoal class
// The goal that causes the AI to react to taking bullet

class ReactToBeingShotGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

import enum ESkeletalRegion from Engine.Actor;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) vector		HitLocation;
var(parameters) vector		HitNormal;
var(parameters) ESkeletalRegion RegionHit;


///////////////////////////////////////////////////////////////////////////////
//
// Constructor

overloaded function construct( AI_Resource r, ESkeletalRegion inRegionHit, vector inHitLocation, vector inHitNormal)
{
	super.construct( r );

	RegionHit   = inRegionHit;
	HitLocation = inHitLocation;
	HitNormal   = inHitNormal;
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 99
	goalName = "ReactToBeingShot"
}
