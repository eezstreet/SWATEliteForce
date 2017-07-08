///////////////////////////////////////////////////////////////////////////////
// SquadCloseDoorAction.uc - SquadCloseDoorAction class
// this action is used to organize the Officer's close door behavior

class SquadCloseDoorAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// automatically copied from our goal
var(parameters) Door		TargetDoor;

// behaviors we use
var private CloseDoorGoal	CurrentCloseDoorGoal;

// who is closing the door
var private Pawn			DoorCloser;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentCloseDoorGoal != None)
	{
		CurrentCloseDoorGoal.Release();
		CurrentCloseDoorGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function CloseTheDoor()
{
	// This may be a problem because the Close Door goal is on the Movement resource rather than the character resource.
	// Not sure if there are any ill effects from this, but there may be some.
	CurrentCloseDoorGoal = new class'CloseDoorGoal'(AI_Resource(DoorCloser.movementAI), TargetDoor);
	assert(CurrentCloseDoorGoal != None);
	CurrentCloseDoorGoal.AddRef();

	CurrentCloseDoorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentCloseDoorGoal.SetCloseDoorFromLeft(ISwatDoor(TargetDoor).PointIsToMyLeft(CommandOrigin));

	CurrentCloseDoorGoal.postGoal(self);
	WaitForGoal(CurrentCloseDoorGoal);
	CurrentCloseDoorGoal.unPostGoal(self);

	CurrentCloseDoorGoal.Release();
	CurrentCloseDoorGoal = None;
}

state Running
{
Begin:
	WaitForZulu();

	DoorCloser = GetClosestOfficerTo(TargetDoor, false, true);
	assert(DoorCloser != None);

	CloseTheDoor();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadCloseDoorGoal'
}