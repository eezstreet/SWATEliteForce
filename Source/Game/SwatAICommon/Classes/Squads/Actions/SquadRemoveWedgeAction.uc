///////////////////////////////////////////////////////////////////////////////
// SquadRemoveWedgeAction.uc - SquadRemoveWedgeAction class
// this action is used to organize the Officer's Remove wedge behavior

class SquadRemoveWedgeAction extends SquadStackUpAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private RemoveWedgeGoal CurrentRemoveWedgeGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentRemoveWedgeGoal != None)
	{
		CurrentRemoveWedgeGoal.Release();
		CurrentRemoveWedgeGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// tells the first officer found with a wedge to Remove it
latent function RemoveWedge(Pawn Officer)
{
	CurrentRemoveWedgeGoal = new class'RemoveWedgeGoal'(AI_Resource(Officer.characterAI), TargetDoor);
	assert(CurrentRemoveWedgeGoal != None);
	CurrentRemoveWedgeGoal.AddRef();

	CurrentRemoveWedgeGoal.postGoal(self);
	WaitForGoal(CurrentRemoveWedgeGoal);
	CurrentRemoveWedgeGoal.unPostGoal(self);

	CurrentRemoveWedgeGoal.Release();
	CurrentRemoveWedgeGoal = None;
}

state Running
{
Begin:
	StackUpSquad(true);

	WaitForZulu();

	RemoveWedge(GetFirstOfficer());

	StackUpSquad(true);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadRemoveWedgeGoal'
}
