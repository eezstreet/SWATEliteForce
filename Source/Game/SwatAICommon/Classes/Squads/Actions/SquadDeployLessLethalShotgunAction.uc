///////////////////////////////////////////////////////////////////////////////

class SquadDeployLessLethalShotgunAction extends OfficerSquadAction;

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

var private DeployLessLethalShotgunGoal CurrentDeployLessLethalShotgunGoal;

// copied from our goal
var(parameters) Pawn TargetPawn;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentDeployLessLethalShotgunGoal != None)
	{
		CurrentDeployLessLethalShotgunGoal.Release();
		CurrentDeployLessLethalShotgunGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function DeployLessLethalShotgunOnTarget()
{
	local Pawn Officer;

	Officer = GetClosestOfficerWithEquipment(TargetPawn.Location, Slot_PrimaryWeapon, 'LessLethalSG');

	CurrentDeployLessLethalShotgunGoal = new class'DeployLessLethalShotgunGoal'(AI_Resource(Officer.characterAI), TargetPawn);
	assert(CurrentDeployLessLethalShotgunGoal != None);
	CurrentDeployLessLethalShotgunGoal.AddRef();

	CurrentDeployLessLethalShotgunGoal.postGoal(self);
	WaitForGoal(CurrentDeployLessLethalShotgunGoal);
	CurrentDeployLessLethalShotgunGoal.unPostGoal(self);

	CurrentDeployLessLethalShotgunGoal.Release();
	CurrentDeployLessLethalShotgunGoal = None;
}

state Running
{
Begin:
	WaitForZulu();

    DeployLessLethalShotgunOnTarget();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'SquadDeployLessLethalShotgunGoal'
}