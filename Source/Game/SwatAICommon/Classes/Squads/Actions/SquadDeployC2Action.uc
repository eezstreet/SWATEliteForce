///////////////////////////////////////////////////////////////////////////////
// SquadDeployC2Action.uc - SquadDeployC2Action class
// this action is used to organize the Officer's deploy C2 behavior

class SquadDeployC2Action extends SquadStackUpAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private UseBreachingChargeGoal CurrentUseBreachingChargeGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentUseBreachingChargeGoal != None)
	{
		CurrentUseBreachingChargeGoal.Release();
		CurrentUseBreachingChargeGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function DeployC2()
{
	local Pawn Officer;
    local NavigationPoint SafeLocation;

	Officer = GetC2BreachingOfficer();
	assert(Officer != None);

	MoveUpC2Breacher(Officer);

	// Get the post-breaching location to move to -- at this point the breacher is ALWAYS the first officer
	SafeLocation = StackUpPoints[0];
	assert(SafeLocation != None);

	CurrentUseBreachingChargeGoal = new class'UseBreachingChargeGoal'(AI_Resource(Officer.characterAI), TargetDoor, SafeLocation);
	assert(CurrentUseBreachingChargeGoal != None);
	CurrentUseBreachingChargeGoal.AddRef();

	CurrentUseBreachingChargeGoal.postGoal(self);
	WaitForGoal(CurrentUseBreachingChargeGoal);
	CurrentUseBreachingChargeGoal.unPostGoal(self);

	CurrentUseBreachingChargeGoal.Release();
	CurrentUseBreachingChargeGoal = None;
}

state Running
{
Begin:
	StackUpSquad(true);

	DeployC2();		//<-- WaitforZulu() happens in UserBreachingCharge action
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadDeployC2Goal'
}