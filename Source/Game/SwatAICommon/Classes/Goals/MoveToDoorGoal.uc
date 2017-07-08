///////////////////////////////////////////////////////////////////////////////
// MoveToDoorGoal.uc - MoveToDoorGoal class
// The goal that causes the AI to move to a door

class MoveToDoorGoal extends MoveToGoalBase;
///////////////////////////////////////////////////////////////////////////////

import enum AIDoorUsageSide from ISwatAI;

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

var(parameters) Door	TargetDoor;
var(parameters) bool	bPreferSides;

var AIDoorUsageSide		DoorUsageSide;
var Rotator				DoorUsageRotation;

///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r, int pri)
{
	assert(false);
}

overloaded function construct( AI_Resource r, Door inTargetDoor )
{
    Super.construct(r, priority);

	assert(inTargetDoor != None);
	TargetDoor = inTargetDoor;
}

overloaded function construct( AI_Resource r, int pri, Door inTargetDoor )
{
    Super.construct(r, pri);

	assert(inTargetDoor != None);
	TargetDoor = inTargetDoor;
}

function vector GetDestination()
{	
	local vector Destination;
	local Rotator DummyRotation;
	local ISwatDoor SwatDoorTarget;

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);

	SwatDoorTarget.GetOpenPositions(AI_MovementResource(resource).m_Pawn, false, Destination, DummyRotation);
	return Destination;
}

function SetPreferSides()
{
	bPreferSides = true;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 75
	goalName = "MoveToDoor"
}