///////////////////////////////////////////////////////////////////////////////
// StackUpAction.uc - StackUpAction class
// The Action that causes the Officers to stack up on a door

class StackUpAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// StackUpAction variables

var private ReloadGoal					CurrentReloadGoal;
var private MoveToActorGoal				CurrentMoveToActorGoal;
var private AimAtTargetGoal				CurrentAimAtTargetGoal;

var config float						DistanceToStartWalking;
var private bool						bShouldWalk;
var config float						MinDistanceToAimAtDoor;

// copied from our goal automatically
var(Parameters) StackupPoint			StackUpPoint;
var(Parameters) bool					bRunToStackupPoint;

///////////////////////////////////////////////////////////////////////////////
//
// Mid-Behavior Manipulating

function SetStackUpPoint(StackUpPoint NewStackUpPoint)
{
	StackUpPoint = NewStackUpPoint;	
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function Cleanup()
{
	super.cleanup();
	
	if (CurrentReloadGoal != None)
	{
		CurrentReloadGoal.Release();
		CurrentReloadGoal = None;
	}

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Aiming at Targets

function PostReloadGoal()
{
	assert(CurrentReloadGoal == None);

	CurrentReloadGoal = new class'ReloadGoal'(weaponResource(), achievingGoal.priority);
	assert(CurrentReloadGoal != None);
	CurrentReloadGoal.AddRef();
	CurrentReloadGoal.postGoal(self);
	
	assert(CurrentReloadGoal != None);
	CurrentReloadGoal.unPostGoal(self);

	CurrentReloadGoal.Release();
	CurrentReloadGoal = None;
}

function PostAimAtTargetGoal()
{
	assert(CurrentAimAtTargetGoal == None);

	CurrentAimAtTargetGoal = new class'AimAtTargetGoal'(weaponResource(), achievingGoal.priority, StackUpPoint.ParentDoor);
	assert(CurrentAimAtTargetGoal != None);
	CurrentAimAtTargetGoal.AddRef();

    CurrentAimAtTargetGoal.SetAimOnlyWhenCanHitTarget(true);						// only aim if we can
    CurrentAimAtTargetGoal.SetShouldFinishOnSuccess(false);							// don't stop aiming
	CurrentAimAtTargetGoal.SetAimWeapon(false);										// use low ready
	CurrentAimAtTargetGoal.SetMinDistanceToTargetToAim(MinDistanceToAimAtDoor);		// only aim if we're within the specified distance

	CurrentAimAtTargetGoal.postGoal(self);
}

function RemoveAimAtTargetGoal()
{
	assert(CurrentAimAtTargetGoal != None);
	CurrentAimAtTargetGoal.unPostGoal(self);

	CurrentAimAtTargetGoal.Release();
	CurrentAimAtTargetGoal = None;
}

///////////////////////////////////////////////////////////////////////////////
//
// Movement Code

latent function MoveToStackUpPoint()
{
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, StackUpPoint);
    assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);

	// set our walk threshold if we're not supposed to run
	if (bRunToStackupPoint)
	{
		CurrentMoveToActorGoal.SetWalkThreshold(0.0);
	}
	else
	{
		CurrentMoveToActorGoal.SetWalkThreshold(DistanceToStartWalking);
	}

	// post the move to goal and wait for it to complete
    CurrentMoveToActorGoal.postGoal(self);
    WaitForGoal(CurrentMoveToActorGoal);
    CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

state Running
{
Begin:
	SleepInitialDelayTime(true);
	
//	PostReloadGoal();

	PostAimAtTargetGoal();
	
	MoveToStackUpPoint();

	RemoveAimAtTargetGoal();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'StackUpGoal'
}