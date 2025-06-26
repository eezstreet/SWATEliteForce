///////////////////////////////////////////////////////////////////////////////
// ShareEquipmentGoal.uc - ShareEquipmentGoal class
// this goal is given to an officer when they are ordered to share a piece of equipment

class ShareEquipmentGoal extends OfficerCommandGoal;
import enum EquipmentSlot from Engine.HandheldEquipment;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) Pawn Destination;
var(parameters) EquipmentSlot Slot;

///////////////////////////////////////////////////////////////////////////////
//
// Constructor

overloaded function Construct(AI_Resource r, Pawn inDestination, EquipmentSlot inSlot)
{
	super.construct(r, priority);

    Destination = inDestination;
	Slot = inSlot;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority   = 75
    goalName   = "ShareEquipment"
}
