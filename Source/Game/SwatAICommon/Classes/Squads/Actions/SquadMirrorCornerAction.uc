///////////////////////////////////////////////////////////////////////////////
// SquadMirrorCornerAction.uc - SquadMirrorCornerAction class
// this action is used to organize the Officer's mirroring of corners

class SquadMirrorCornerAction extends OfficerSquadAction;
///////////////////////////////////////////////////////////////////////////////

import enum EquipmentSlot from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private MirrorCornerGoal			CurrentMirrorCornerGoal;

// copied from our goal
var(parameters) Actor					TargetMirrorPoint;

const kMinDistanceToMirrorPoint = 250.0;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMirrorCornerGoal != None)
	{
		CurrentMirrorCornerGoal.Release();
		CurrentMirrorCornerGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function Pawn GetClosestOfficerWithOptiwand()
{
	local int i;
	local float IterDistance, ClosestDistance;
	local Pawn IterOfficer, ClosestOfficer;
	local vector MirroringFromPoint;

	MirroringFromPoint = IMirrorPoint(TargetMirrorPoint).GetMirroringFromPoint();

	for(i=0; i<squad().pawns.length; ++i)
	{
		IterOfficer = squad().pawns[i];

		if (ISwatOfficer(IterOfficer).GetItemAtSlot(Slot_Optiwand) != None)
		{ 
			if (! IterOfficer.FastTrace(MirroringFromPoint, IterOfficer.Location))
			{
				IterDistance = IterOfficer.GetPathfindingDistanceToPoint(MirroringFromPoint, true);
			}
			else
			{
				IterDistance = VSize(MirroringFromPoint - IterOfficer.Location);
			}

			if ((ClosestOfficer == None) || (IterDistance < ClosestDistance))
			{
				ClosestOfficer  = IterOfficer;
				ClosestDistance = IterDistance;
			}
		}
	}

	return ClosestOfficer;
}

latent function MirrorAroundCorner()
{
	local Pawn ClosestOfficer;

	ClosestOfficer = GetClosestOfficerWithOptiwand();

	if (ClosestOfficer != None)
	{
		CurrentMirrorCornerGoal = new class'MirrorCornerGoal'(AI_Resource(ClosestOfficer.characterAI), TargetMirrorPoint);
		assert(CurrentMirrorCornerGoal != None);
		CurrentMirrorCornerGoal.AddRef();

		CurrentMirrorCornerGoal.postGoal(self);
		WaitForGoal(CurrentMirrorCornerGoal);
		CurrentMirrorCornerGoal.unPostGoal(self);

		CurrentMirrorCornerGoal.Release();
		CurrentMirrorCornerGoal = None;
	}
}

state Running
{
Begin:
	WaitForZulu();

	MirrorAroundCorner();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'SquadMirrorCornerGoal'
}