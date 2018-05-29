///////////////////////////////////////////////////////////////////////////////
// SquadMirrorDoorAction.uc - SquadMirrorDoorAction class
// this action is used to organize the Officer's mirror door behavior

class SquadCheckForTrapsAction extends SquadStackUpAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

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

function Pawn GetFirstOfficerWithMirror()
{
	local int i;
	local Pawn Officer;

	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		Officer = OfficersInStackUpOrder[i];

		if(class'Pawn'.static.checkConscious(Officer) &&
		   (ISwatOfficer(Officer).GetItemAtSlot(Slot_Optiwand) != None))
		{
			return Officer;
		}
	}

	// it's ok to get here
	return None;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function CheckTraps()
{
	local Pawn CheckingOfficer;

	CheckingOfficer = GetFirstOfficerWithMirror();

	if (CheckingOfficer == None)
	{
		// just complete
		instantSucceed();
	}
	else
	{
		if (CheckingOfficer != GetFirstOfficer())
		{
			ISwatOfficer(CheckingOfficer).GetOfficerSpeechManagerAction().TriggerGenericMoveUpSpeech();

			SwapStackUpPositions(CheckingOfficer, GetFirstOfficer());
		}
		else
		{
			ISwatOfficer(CheckingOfficer).GetOfficerSpeechManagerAction().TriggerGenericOrderReplySpeech();
		}

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
