///////////////////////////////////////////////////////////////////////////////
// GuardAction.uc - the GuardAction class
// behavior that causes the Officer AI to move within a radius of an actor and complete there

class GuardAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// behaviors
var private MoveToActorGoal	CurrentMoveToActorGoal;

// copied from our goal
var(parameters) Actor		Target;

const kGuardMoveThreshold = 100.0;

///////////////////////////////////////////////////////////////////////////////
// 
// cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
// 
// State Code

latent function MoveToTarget()
{
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, Target);
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToActorGoal.SetAcceptNearbyPath(true);
	CurrentMoveToActorGoal.SetMoveToThreshold(kGuardMoveThreshold);

	CurrentMoveToActorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

state Running
{
 Begin:
	MoveToTarget();
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'GuardGoal'
}