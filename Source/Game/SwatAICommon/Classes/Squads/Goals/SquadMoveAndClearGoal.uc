///////////////////////////////////////////////////////////////////////////////
// SquadMoveAndClearGoal.uc - SquadMoveAndClearGoal class
// this goal is used to organize the Officer's move & clear behavior

class SquadMoveAndClearGoal extends SquadStackUpGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private name	RoomNameToClear;

///////////////////////////////////////////////////////////////////////////////
//
// Constructors

// Use this constructor
overloaded function construct( AI_Resource r, Pawn inCommandGiver, vector inCommandOrigin, Door inTargetDoor, optional bool bInTriggerCouldntBreachLockedSpeech )
{
	super.construct(r, inCommandGiver, inCommandOrigin, inTargetDoor, bInTriggerCouldntBreachLockedSpeech);

	if (ISwatDoor(inTargetDoor).PointIsToMyLeft(inCommandOrigin))
	{
		RoomNameToClear = ISwatDoor(inTargetDoor).GetRightRoomName();
	}
	else
	{
		RoomNameToClear = ISwatDoor(inTargetDoor).GetLeftRoomName();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function name GetRoomNameToClear()
{
	return RoomNameToClear;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	goalName = "SquadMoveAndClear"
    bIsCharacterInteractionCommandGoal=true
}