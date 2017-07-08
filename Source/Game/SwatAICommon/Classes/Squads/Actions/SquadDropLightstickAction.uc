///////////////////////////////////////////////////////////////////////////////

class SquadDropLightstickAction extends OfficerSquadAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private DropLightstickGoal CurrentDropLightstickGoal;

// copied from our goal
var(parameters) Pawn TargetPawn;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentDropLightstickGoal != None)
	{
		CurrentDropLightstickGoal.Release();
		CurrentDropLightstickGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function DropLightstick()
{
	local Pawn Officer;

	Officer = GetClosestOfficerWithEquipment(TargetPawn.Location, Slot_Lightstick, 'Lightstick');
  if(Officer == None) {
    Officer = GetFirstOfficer();
    if(Officer != None) {
      ISwatOfficer(Officer).GetOfficerSpeechManagerAction().TriggerCantDeployLightstickSpeech();
    }
    return;
  }

	CurrentDropLightstickGoal = new class'DropLightstickGoal'(AI_Resource(Officer.characterAI), Officer.Location);
	assert(CurrentDropLightstickGoal != None);
	CurrentDropLightstickGoal.AddRef();

	CurrentDropLightstickGoal.postGoal(self);
	WaitForGoal(CurrentDropLightstickGoal);
	CurrentDropLightstickGoal.unPostGoal(self);

	CurrentDropLightstickGoal.Release();
	CurrentDropLightstickGoal = None;
}

state Running
{
Begin:
	  WaitForZulu();

    DropLightstick();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'SquadDropLightstickGoal'
}
