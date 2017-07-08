///////////////////////////////////////////////////////////////////////////////
// SquadDeployThrownItemThroughDoorGoal.uc - SquadDeployThrownItemThroughDoorGoal class
// this goal is used to organize the Officer's deploy thrown item through door behavior

class SquadDeployThrownItemThroughDoorGoal extends SquadMoveAndClearGoal;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// automatically copied to our action
var(parameters) EquipmentSlot	ThrownItemSlot;

///////////////////////////////////////////////////////////////////////////////
//
// Constructors

// Use this constructor
overloaded function construct( AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, Door inTargetDoor, EquipmentSlot inThrownItemSlot )
{
	super.construct(r, inCommandGiver, inCommandOrigin, inTargetDoor);

	ThrownItemSlot = inThrownItemSlot;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadDeployThrownItemThroughDoor"
    bIsCharacterInteractionCommandGoal=true
}