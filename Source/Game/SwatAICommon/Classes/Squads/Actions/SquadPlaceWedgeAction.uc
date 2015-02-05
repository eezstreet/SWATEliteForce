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