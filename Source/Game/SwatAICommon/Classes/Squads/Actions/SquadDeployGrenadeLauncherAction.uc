///////////////////////////////////////////////////////////////////////////////

class SquadDeployGrenadeLauncherAction extends OfficerSquadAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private DeployGrenadeLauncherGoal CurrentDeployGrenadeLauncherGoal;

// copied from our goal
var(parameters) Actor TargetActor;		// takes precedence unless None
var(parameters) vector TargetLocation;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentDeployGrenadeLauncherGoal != None)
	{
		CurrentDeployGrenadeLauncherGoal.Release();
		CurrentDeployGrenadeLauncherGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function DeployGrenadeLauncherOnTarget()
{
	local Pawn Officer;

	Officer = GetClosestOfficerWithEquipment(TargetLocation, Slot_PrimaryWeapon, 'HK69GrenadeLauncher');
	if(Officer == None)
		Officer = GetClosestOfficerWithEquipment(TargetLocation, Slot_SecondaryWeapon, 'HK69GrenadeLauncher');

	CurrentDeployGrenadeLauncherGoal = new class'DeployGrenadeLauncherGoal'(AI_Resource(Officer.characterAI), TargetActor, TargetLocation);
	assert(CurrentDeployGrenadeLauncherGoal != None);
	CurrentDeployGrenadeLauncherGoal.AddRef();

	CurrentDeployGrenadeLauncherGoal.postGoal(self);
	WaitForGoal(CurrentDeployGrenadeLauncherGoal);
	CurrentDeployGrenadeLauncherGoal.unPostGoal(self);

	CurrentDeployGrenadeLauncherGoal.Release();
	CurrentDeployGrenadeLauncherGoal = None;
}

state Running
{
Begin:
	WaitForZulu();

    DeployGrenadeLauncherOnTarget();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'SquadDeployGrenadeLauncherGoal'
}
