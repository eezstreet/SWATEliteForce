///////////////////////////////////////////////////////////////////////////////
// SquadShareEquipmentGoal.uc - SquadShareEquipmentGoal class
// this goal is used when ordering an officer to share a piece of equipment with the player

class SquadShareEquipmentGoal extends SquadCommandGoal;
import enum EquipmentSlot from Engine.HandheldEquipment;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) EquipmentSlot Slot;

///////////////////////////////////////////////////////////////////////////////
//
// Constructors

// Use this constructor
overloaded function construct( AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, EquipmentSlot inSlot)
{
	super.construct(r, inCommandGiver, inCommandOrigin);

	Slot = inSlot;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadShareEquipment"
	bRepostElementGoalOnSubElementSquad = true
}
