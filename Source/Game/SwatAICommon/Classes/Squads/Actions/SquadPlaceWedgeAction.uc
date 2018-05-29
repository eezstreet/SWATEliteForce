///////////////////////////////////////////////////////////////////////////////
// SquadPlaceWedgeAction.uc - SquadPlaceWedgeAction class
// this action is used to organize the Officer's place wedge behavior

class SquadPlaceWedgeAction extends SquadStackUpAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private PlaceWedgeGoal	CurrentPlaceWedgeGoal;
var private CloseDoorGoal	CurrentCloseDoorGoal;

// internal
var private Pawn			OfficerWithWedge;
var private StackupPoint	OfficerWithWedgeStackupPoint;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function Cleanup()
{
	super.cleanup();

	if (CurrentPlaceWedgeGoal != None)
	{
		CurrentPlaceWedgeGoal.Release();
		CurrentPlaceWedgeGoal = None;
	}

	if(CurrentCloseDoorGoal != None)
	{
		CurrentCloseDoorGoal.Release();
		CurrentCloseDoorGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Queries

function int GetFirstOfficerWithWedgeIndex()
{
	local int i;
	local Pawn Officer;

	for(i=0; i<OfficersInStackUpOrder.Length; ++i)
	{
		Officer = OfficersInStackUpOrder[i];

		if(class'Pawn'.static.checkConscious(Officer) &&
		   (ISwatOfficer(Officer).GetItemAtSlot(Slot_Wedge) != None))
		{
			return i;
		}
	}

	// it's ok to get here
	return -1;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// tells the first officer found with a wedge to place it
latent function PlaceWedge()
{
	local int OfficerWithWedgeIndex;

	OfficerWithWedgeIndex = GetFirstOfficerWithWedgeIndex();

	if (OfficerWithWedgeIndex == -1)
	{
		// just complete if we don't have a wedge.
		instantSucceed();
	}
	else
	{
		OfficerWithWedge             = OfficersInStackUpOrder[OfficerWithWedgeIndex];
		OfficerWithWedgeStackupPoint = StackupPoints[OfficerWithWedgeIndex];

		// If the door is open, shut it.
		if(TargetDoor.IsOpen())
		{
			CurrentCloseDoorGoal = new class'CloseDoorGoal'(AI_Resource(OfficerWithWedge.movementAI), TargetDoor);
			assert(CurrentCloseDoorGoal != None);
			CurrentCloseDoorGoal.AddRef();

			CurrentCloseDoorGoal.postGoal(self);
			WaitForGoal(CurrentCloseDoorGoal);
			CurrentCloseDoorGoal.unPostGoal(self);

			CurrentCloseDoorGoal.Release();
			CurrentCloseDoorGoal = None;

			// Wait until the door is closed
			while(!TargetDoor.IsClosed())
			{
				yield();
			}
		}

		CurrentPlaceWedgeGoal = new class'PlaceWedgeGoal'(AI_Resource(OfficerWithWedge.characterAI), TargetDoor);
		assert(CurrentPlaceWedgeGoal != None);
		CurrentPlaceWedgeGoal.AddRef();

		CurrentPlaceWedgeGoal.postGoal(self);
		WaitForGoal(CurrentPlaceWedgeGoal);
		CurrentPlaceWedgeGoal.unPostGoal(self);

		CurrentPlaceWedgeGoal.Release();
		CurrentPlaceWedgeGoal = None;
	}
}

state Running
{
Begin:
	StackUpSquad(true);

	WaitForZulu();

	PlaceWedge();

    StackUpOfficer(OfficerWithWedge, OfficerWithWedgeStackupPoint);
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadPlaceWedgeGoal'
}
