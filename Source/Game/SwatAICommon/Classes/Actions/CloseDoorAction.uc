///////////////////////////////////////////////////////////////////////////////
// CloseDoorAction.uc - CloseDoorAction class
// The action that causes the AI to close a door
// Currently assumes that the door is reachable from our current location

class CloseDoorAction extends MoveToDoorAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// copied from our goal
var(parameters) bool	CloseDoorFromBehind;
var(parameters) bool	CloseDoorFromLeft;

// internal
var private ISwatDoor	SwatDoorTarget;

///////////////////////////////////////////////////////////////////////////////
// 
// Cleanup

function cleanup()
{
	super.cleanup();

	// stop animating
	ISwatAI(m_Pawn).AnimStopSpecial();

	// unlock our aim (if it isn't already)
	ISwatAI(m_Pawn).UnlockAim();

	// re-enable collision avoidance (if it isn't already)
	m_Pawn.EnableCollisionAvoidance();

	// clear out any transient values about the pawn using the door (in case they weren't unset)
	ISwatAI(m_Pawn).ClearPendingDoor();
	SwatDoorTarget.SetPendingInteractor(None);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function bool ShouldContinueToCloseDoor()
{
	local Pawn PendingDoorInteractor;

	assert(SwatDoorTarget != None);

	PendingDoorInteractor = SwatDoorTarget.GetPendingInteractor();

	return (!TargetDoor.IsEmptyDoorway() && !TargetDoor.IsClosed() && !SwatDoorTarget.IsBroken() && 
		    ((PendingDoorInteractor == None) || (PendingDoorInteractor == m_Pawn)));
}

latent function CloseDoor()
{
	local name CloseAnimName;
	local int CloseDoorAnimChannel;
	local Pawn PendingDoorInteractor;

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);
	
	PendingDoorInteractor = SwatDoorTarget.GetPendingInteractor();

	while (TargetDoor.IsOpening())
		yield();

	// only close open doors that are real doors, aren't broken, and aren't going to be interacted with
	if (ShouldContinueToCloseDoor())
	{
		// no avoiding collision while we're closing the door!
		m_Pawn.DisableCollisionAvoidance();

		// set the door in the pawn
		ISwatAI(m_pawn).SetPendingDoor(TargetDoor);
		SwatDoorTarget.SetPendingInteractor(m_Pawn);

		// only try and close the door if we fit at the close door location
		if (m_Pawn.FitsAtLocation(SwatDoorTarget.GetClosePoint(CloseDoorFromLeft)))
		{
			// move towards the door
			MoveToCloseDoor(TargetDoor, CloseDoorFromLeft, CloseDoorFromBehind);

			// make sure we're rotated correctly
			RotateAndLockToDoorUsageRotation();

			if (ShouldContinueToCloseDoor())
			{
				// tell the pawn to play the closing animation
				CloseAnimName = SwatDoorTarget.GetCloseAnimation(m_Pawn, CloseDoorFromBehind);
				CloseDoorAnimChannel = m_Pawn.AnimPlaySpecial(CloseAnimName);

				m_Pawn.FinishAnim(CloseDoorAnimChannel);
			}

			// unlock our aim
			ISwatAI(m_Pawn).UnlockAim();
		}
		else if (m_Pawn.IsA('SwatOfficer'))
		{
			// if we're a swat officer, and were told to close the door, report that we can't get into position to close the door
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerCouldntCompleteMoveSpeech();
		}

		ISwatAI(m_Pawn).ClearPendingDoor();
		SwatDoorTarget.SetPendingInteractor(None);

		// re-enable collision avoidance
		m_Pawn.EnableCollisionAvoidance();
	}
}

state Running
{
 Begin:
	CloseDoor();	
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'CloseDoorGoal'
}
