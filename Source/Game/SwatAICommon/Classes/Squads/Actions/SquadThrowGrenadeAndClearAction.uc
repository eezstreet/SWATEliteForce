///////////////////////////////////////////////////////////////////////////////
// SquadThrowGrenadeAndClearAction.uc - SquadThrowGrenadeAndClearAction class
// this action is used as base for throwing a grenade and then clearing (Bang & Clear, Gas & Clear)

class SquadThrowGrenadeAndClearAction extends SquadMoveAndClearAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Callbacks

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	// if the goal that was achieved is the open door goal
	// start running again.
	// NOTE that this must be called before the super.goalAchievedCB 
	// because the super will unpost and release the goal
	if (goal == CurrentOpenDoorGoal)
	{
		if (isIdle())
			runAction();
	}

	super.goalAchievedCB(goal, child);
}

///////////////////////////////////////////////////////////////////////////////
//
// Stacking up

// any grenade throws in a move and clear should be preceded by a stack up 
// (according to the designers, and I agree)
protected function bool ShouldStackUpIfOfficersInRoomToClear() { return true; }


///////////////////////////////////////////////////////////////////////////////
//
// State Code

// one officer opens the door, the second will throw the grenade
// if there is no second officer, then the first will throw it
latent function PrepareToMoveSquad(optional bool bNoZuluCheck)
{
	MoveUpThrower();

	Super.PrepareToMoveSquad(bNoZuluCheck);

	if (CanInteractWithTargetDoor())
	{
		// prepare for the door to be opened
		PreTargetDoorOpened();
		WaitForZulu();
		OpenDoorForThrowingGrenade();

		// door has been opened
		PostTargetDoorOpened();
	}
	else
	{
		PrepareToMoveThroughOpenDoorway();
	}
}

protected latent function PrepareToMoveThroughOpenDoorway();
protected latent function PreTargetDoorOpened();
protected latent function PostTargetDoorOpened();

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}