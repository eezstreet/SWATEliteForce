///////////////////////////////////////////////////////////////////////////////
// SquadDeployThrownItemGoal.uc - SquadDeployThrownItemGoal class
// this goal is used to organize the Officer's deploy thrown item behavior

class SquadDeployThrownItemGoal extends SquadCommandGoal;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) EquipmentSlot		ThrownItemSlot;
var(parameters) vector				TargetThrowLocation;


///////////////////////////////////////////////////////////////////////////////
//
// Constructors

// Use this constructor
overloaded function construct( AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, EquipmentSlot inThrownItemSlot, vector inTargetThrowLocation)
{
	super.construct(r, inCommandGiver, inCommandOrigin);

	ThrownItemSlot      = inThrownItemSlot;
	TargetThrowLocation = inTargetThrowLocation;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadDeployThrownItem"
}