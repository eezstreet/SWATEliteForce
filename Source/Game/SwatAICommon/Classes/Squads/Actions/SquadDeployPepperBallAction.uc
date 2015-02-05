///////////////////////////////////////////////////////////////////////////////

class SquadDeployPepperBallAction extends OfficerSquadAction;

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

var private DeployPepperBallGoal CurrentDeployPepperBallGoal;

// copied from our goal
var(parameters) Pawn TargetPawn;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentDeployPepperBallGoal != None)
	{
		CurrentDeployPepperBallGoal.Release();
		CurrentDeployPepperBallGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function DeployPepperBallOnTarget()
{
	local Pawn Officer;

	Officer = GetClosestOfficerWithEquipment(TargetPawn.Location, Slot_PrimaryWeapon, 'CSBallLauncher');

	CurrentDeployPepperBallGoal = new class'DeployPepperBallGoal'(AI_Resource(Officer.characterAI), TargetPawn);
	assert(CurrentDeployPepperBallGoal != None);
	CurrentDeployPepperBallGoal.AddRef();

	CurrentDeployPepperBallGoal.postGoal(self);
	WaitForGoal(CurrentDeployPepperBallGoal);
	CurrentDeployPepperBallGoal.unPostGoal(self);

	CurrentDeployPepperBallGoal.Release();
	CurrentDeployPepperBallGoal = None;
}

state Running
{
Begin:
	WaitForZulu();

    DeployPepperBallOnTarget();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'SquadDeployPepperBallGoal'
}