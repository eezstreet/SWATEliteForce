///////////////////////////////////////////////////////////////////////////////

class SquadDeployTaserAction extends OfficerSquadAction;

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

var private DeployTaserGoal CurrentDeployTaserGoal;

// copied from our goal
var(parameters) Pawn TargetPawn;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentDeployTaserGoal != None)
	{
		CurrentDeployTaserGoal.Release();
		CurrentDeployTaserGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function DeployTaserOnTarget()
{
	local Pawn Officer;

	Officer = GetClosestOfficerWithEquipment(TargetPawn.Location, Slot_SecondaryWeapon, 'Taser');

	CurrentDeployTaserGoal = new class'DeployTaserGoal'(AI_Resource(Officer.characterAI), TargetPawn);
	assert(CurrentDeployTaserGoal != None);
	CurrentDeployTaserGoal.AddRef();

	CurrentDeployTaserGoal.postGoal(self);
	WaitForGoal(CurrentDeployTaserGoal);
	CurrentDeployTaserGoal.unPostGoal(self);

	CurrentDeployTaserGoal.Release();
	CurrentDeployTaserGoal = None;
}

state Running
{
Begin:
	WaitForZulu();

    DeployTaserOnTarget();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'SquadDeployTaserGoal'
}