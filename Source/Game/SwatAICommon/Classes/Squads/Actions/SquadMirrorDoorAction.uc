///////////////////////////////////////////////////////////////////////////////
// SquadMirrorDoorAction.uc - SquadMirrorDoorAction class
// this action is used to organize the Officer's mirror door behavior

class SquadMirrorDoorAction extends SquadStackUpAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// who is mirroring
var private Pawn						OfficerWithMirror;

// behaviors we use
var private MirrorDoorGoal				CurrentMirrorDoorGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();
	
	if (CurrentMirrorDoorGoal != None)
	{
		CurrentMirrorDoorGoal.Release();
		CurrentMirrorDoorGoal = None;
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

latent function MirrorDoor()
{
	OfficerWithMirror = GetFirstOfficerWithMirror();

	if (OfficerWithMirror == None)
	{
		// just complete if we don't have a mirror.
		instantSucceed();
	}
	else
	{
		if (OfficerWithMirror != GetFirstOfficer())
		{
			ISwatOfficer(OfficerWithMirror).GetOfficerSpeechManagerAction().TriggerGenericMoveUpSpeech();

			SwapStackUpPositions(OfficerWithMirror, GetFirstOfficer());
		}

		CurrentMirrorDoorGoal = new class'MirrorDoorGoal'(AI_CharacterResource(OfficerWithMirror.characterAI), TargetDoor);
		assert(CurrentMirrorDoorGoal != None);
		CurrentMirrorDoorGoal.AddRef();

		CurrentMirrorDoorGoal.postGoal(self);
		WaitForGoal(CurrentMirrorDoorGoal);
		CurrentMirrorDoorGoal.unPostGoal(self);

		CurrentMirrorDoorGoal.Release();
		CurrentMirrorDoorGoal = None;
	}
}

state Running
{
 Begin:
	StackUpSquad(true);

	WaitForZulu();

	MirrorDoor();

	StackUpOfficer(OfficerWithMirror, StackUpPoints[0]);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'SquadMirrorDoorGoal'
}