///////////////////////////////////////////////////////////////////////////////
// SquadMirrorDoorAction.uc - SquadMirrorDoorAction class
// this action is used to organize the Officer's mirror door behavior

class SquadCheckForTrapsAction extends SquadStackUpAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// who is mirroring
var private Pawn						OfficerWithMirror;

// behaviors we use
var private CheckTrapsGoal				CurrentCheckTrapsGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentCheckTrapsGoal != None)
	{
		CurrentCheckTrapsGoal.Release();
		CurrentCheckTrapsGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Queries

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function CheckTraps()
{
  local Pawn CheckingOfficer;

  CheckingOfficer = OfficersInStackUpOrder[0];

	if (CheckingOfficer == None)
	{
		// just complete
		instantSucceed();
	}
	else
	{
		ISwatOfficer(CheckingOfficer).GetOfficerSpeechManagerAction().TriggerGenericOrderReplySpeech();

		CurrentCheckTrapsGoal = new class'CheckTrapsGoal'(AI_CharacterResource(CheckingOfficer.characterAI), TargetDoor);
		assert(CurrentCheckTrapsGoal != None);
		CurrentCheckTrapsGoal.AddRef();

		CurrentCheckTrapsGoal.postGoal(self);
		WaitForGoal(CurrentCheckTrapsGoal);
		CurrentCheckTrapsGoal.unPostGoal(self);

		CurrentCheckTrapsGoal.Release();
		CurrentCheckTrapsGoal = None;
	}
}

state Running
{
 Begin:
	StackUpSquad(true);

	WaitForZulu();

	CheckTraps();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'SquadCheckForTrapsGoal'
}
