///////////////////////////////////////////////////////////////////////////////
// CommanderGoal.uc - the CommanderGoal class
// this base class is used by AIs to organize their behaviors

class CommanderGoal extends SwatCharacterGoal
	native;
///////////////////////////////////////////////////////////////////////////////

import enum ESkeletalRegion from Engine.Actor;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) PatrolList		Patrol;
var(parameters) bool			bStartIncapacitated;
var(parameters) name			StartIncapacitateIdleCategoryOverride;

///////////////////////////////////////////////////////////////////////////////
//
// Patrolling

function SetPatrol(PatrolList inPatrol)
{
	Patrol = inPatrol;
}

function BecomeIncapacitated(optional name IncapacitatedIdleCategoryOverride)
{
	// if the achieving action hasn't started yet, 
	// then it should spawn the incapacitated behavior when it starts
	if (achievingAction == None)
	{
		bStartIncapacitated                   = true;
		StartIncapacitateIdleCategoryOverride = IncapacitatedIdleCategoryOverride;
	}
	else
	{
		assert(CommanderAction(achievingAction) != None);
		CommanderAction(achievingAction).BecomeIncapacitated();
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName   = "Commander"
	bPermanent = true
}
