///////////////////////////////////////////////////////////////////////////////

class SquadDeployPepperSprayAction extends OfficerSquadAction;

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

var private DeployPepperSprayGoal CurrentDeployPepperSprayGoal;

// copied from our goal
var(parameters) Pawn TargetPawn;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentDeployPepperSprayGoal != None)
	{
		CurrentDeployPepperSprayGoal.Release();
		CurrentDeployPepperSprayGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function DeployPepperSprayOnTarget()
{
	local Pawn Officer;

	Officer = GetClosestOfficerWithEquipment(TargetPawn.Location, Slot_PepperSpray);

	CurrentDeployPepperSprayGoal = new class'DeployPepperSprayGoal'(AI_Resource(Officer.characterAI), TargetPawn);
	assert(CurrentDeployPepperSprayGoal != None);
	CurrentDeployPepperSprayGoal.AddRef();

	CurrentDeployPepperSprayGoal.postGoal(self);
	WaitForGoal(CurrentDeployPepperSprayGoal);
	CurrentDeployPepperSprayGoal.unPostGoal(self);

	CurrentDeployPepperSprayGoal.Release();
	CurrentDeployPepperSprayGoal = None;
}

state Running
{
Begin:
	WaitForZulu();

    DeployPepperSprayOnTarget();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'SquadDeployPepperSprayGoal'
}