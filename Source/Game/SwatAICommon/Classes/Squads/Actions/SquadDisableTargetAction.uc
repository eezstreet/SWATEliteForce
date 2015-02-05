///////////////////////////////////////////////////////////////////////////////

class SquadDisableTargetAction extends OfficerSquadAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private DisableTargetGoal CurrentDisableTargetGoal;

// copied from our goal
var(parameters) Actor Target;

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function vector GetDisableFromPoint()
{
    local IDeployedC2Charge DeployedC2Charge;
    local ISwatDoor SwatDoor;
	local vector DisablePoint;
	local Rotator DummyRotation;

    // Special case for deployed c2 charge
    DeployedC2Charge = IDeployedC2Charge(Target);
    if (DeployedC2Charge != None)
    {
        SwatDoor = DeployedC2Charge.GetDoorDeployedOn();
        if (SwatDoor != None)
        {
            SwatDoor.GetOpenPositions(CommandGiver, false, DisablePoint, DummyRotation);
            return DisablePoint;
        }
    }

    return Target.Location;
}

latent function DisableTarget()
{
    local Pawn Officer;
	local bool bUseDisableTargetMoveThreshold;

    Officer = GetClosestOfficerWithEquipment(Target.Location, Slot_Toolkit);

	// we only use the disable target move threshold if we're dealing with a target that isn't a c2 charge
	bUseDisableTargetMoveThreshold = (IDeployedC2Charge(Target) == None);
	
    CurrentDisableTargetGoal = new class'DisableTargetGoal'(AI_Resource(Officer.characterAI), Target, GetDisableFromPoint(), bUseDisableTargetMoveThreshold);
    assert(CurrentDisableTargetGoal != None);
    CurrentDisableTargetGoal.AddRef();

    CurrentDisableTargetGoal.postGoal(self);
    WaitForGoal(CurrentDisableTargetGoal);
    CurrentDisableTargetGoal.unPostGoal(self);

    CurrentDisableTargetGoal.Release();
    CurrentDisableTargetGoal = None;
}

state Running
{
Begin:
	WaitForZulu();

    DisableTarget();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    satisfiesGoal = class'SquadDisableTargetGoal'
}

///////////////////////////////////////////////////////////////////////////////
