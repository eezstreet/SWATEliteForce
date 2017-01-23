///////////////////////////////////////////////////////////////////////////////
// OpenDoorAction.uc - OpenDoorGoal class
// The action that causes the AI to open a door
// Currently assumes that the door is reachable from our current location

class OpenDoorAction extends MoveToDoorAction
	config(AI);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) bool	bOpenFrantically;

// blocking
var config float		BlockedSleepTime;
var private bool		bIsDoorBlockedBeforeOpen;

var ISwatDoor			SwatDoorTarget;

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	SwatDoorTarget = ISwatDoor(TargetDoor);
	assert(SwatDoorTarget != None);
}

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

function bool ShouldContinueToOpenDoor()
{
	local Pawn PendingDoorInteractor;

	PendingDoorInteractor = SwatDoorTarget.GetPendingInteractor();

	return (TargetDoor.IsClosed() && !SwatDoorTarget.IsBroken() && !TargetDoor.IsOpening() && !TargetDoor.IsClosing() &&
		((PendingDoorInteractor == None) || (PendingDoorInteractor == m_Pawn)));
}

private function UpdateDoorKnowledge()
{
	if (m_Pawn.IsA('SwatOfficer'))
	{
		SwatAIRepository(Level.AIRepo).UpdateDoorKnowledgeForOfficers(TargetDoor);

		if (SwatDoorTarget.IsLocked())
		{
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportDoorLockedSpeech();
		}
		else if (SwatDoorTarget.IsWedged())
		{
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportDoorWedgedSpeech();
		}
	}
	else
	{
		if (SwatDoorTarget.IsWedged())
		{
			ISwatAI(m_Pawn).GetCommanderAction().NotifyDoorWedged(TargetDoor);
		}
		else if (SwatDoorTarget.IsLocked())
		{
			ISwatAI(m_Pawn).GetCommanderAction().NotifyDoorLocked(TargetDoor);
		}
	}

	// complete if it's wedged or locked and we can't open it
	if (SwatDoorTarget.IsWedged() || (SwatDoorTarget.IsLocked() && ! ISwatAI(m_Pawn).ShouldForceOpenLockedDoors()))
	{
		instantSucceed();
	}
	else if (bIsDoorBlockedBeforeOpen)
	{
		ISwatAI(m_Pawn).GetCommanderAction().NotifyDoorBlocked(TargetDoor);
	}
}

latent function OpenDoor()
{
	local name OpenAnimName;
	local int OpenDoorAnimChannel;

	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " is preparing to open door " $ TargetDoor.Name);

	// only try and open closed doors
	if (ShouldContinueToOpenDoor())
	{
		// set the door in the pawn
		ISwatAI(m_pawn).SetPendingDoor(TargetDoor);
		SwatDoorTarget.SetPendingInteractor(m_Pawn);

		if (m_Pawn.logAI)
			log(m_Pawn.Name $ " is now the pending interactor for " $ TargetDoor.Name);

		// move towards the door
		MoveToOpenDoor(TargetDoor);

		// make sure we're rotated correctly
		RotateAndLockToDoorUsageRotation();

		// make sure we should commit to playing the open door animation
		if (ShouldContinueToOpenDoor())
		{
			// save off whether the door is blocked right now
			bIsDoorBlockedBeforeOpen = SwatDoorTarget.IsBlockedFor(m_Pawn);

			// tell the pawn to play the opening animation - take over the arms
			OpenAnimName = SwatDoorTarget.GetOpenAnimation(m_Pawn, GetDoorUsageSide(), bOpenFrantically);

			if (m_Pawn.logAI)
				log(m_Pawn.Name $ " is playing the open door animation ("$OpenAnimName$") on " $ TargetDoor.Name $ " at time " $ m_Pawn.Level.TimeSeconds $ " DoorUsageSide: " $ GetDoorUsageSide() $ " bOpenFrantically: " $ bOpenFrantically);

			OpenDoorAnimChannel = m_Pawn.AnimPlaySpecial(OpenAnimName);

			m_Pawn.FinishAnim(OpenDoorAnimChannel);

			if (m_Pawn.logAI)
				log(m_Pawn.Name $ " finished playing the open door animation on " $ TargetDoor.Name $ " at time " $ m_Pawn.Level.TimeSeconds);
		}

		// unlock our aim
		ISwatAI(m_Pawn).UnlockAim();

		ISwatAI(m_Pawn).ClearPendingDoor();
		SwatDoorTarget.SetPendingInteractor(None);

		// re-enable collision avoidance
		m_Pawn.EnableCollisionAvoidance();
	}

	if (m_Pawn.logAI)
		log("Before UpdateDoorKnowledge - IsLocked(): " $ SwatDoorTarget.IsLocked() $ " IsClosed: " $ TargetDoor.IsClosed() $ " Should Force Open Locked Doors: " $ISwatAI(m_Pawn).ShouldForceOpenLockedDoors());

	UpdateDoorKnowledge();

	if (m_Pawn.logTyrion)
		log(m_Pawn.Name $ " is finished to opening door " $ TargetDoor.Name $ " IsClosed: " $ TargetDoor.IsClosed() $ " IsBroken: " $ SwatDoorTarget.IsBroken() $ " PendingInteractor " $ SwatDoorTarget.GetPendingInteractor());
}

state Running
{
 Begin:
	OpenDoor();

	// wait for it to open if it wasn't blocked
	// if it was blocked, try opening again soon
	if (! bIsDoorBlockedBeforeOpen)
	{
		while (TargetDoor.IsClosed() && !TargetDoor.IsOpening() && !SwatDoorTarget.IsBroken() && !SwatDoorTarget.IsWedged())
		{
			yield();
		}
	}
	else
	{
		sleep(BlockedSleepTime);
		goto('Begin');
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal    = class'OpenDoorGoal'
	BlockedSleepTime = 0.5
}
