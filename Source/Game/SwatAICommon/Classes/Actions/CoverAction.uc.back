///////////////////////////////////////////////////////////////////////////////
// CoverAction.uc - the CoverAction class
// behavior that causes the Officer AI to cover a particular location

class CoverAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// behaviors
var private MoveToLocationGoal			CurrentMoveToLocationGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private AimAroundGoal				CurrentAimAroundGoal;

// internal
var private float						StartCanHitCoverLocationTime;
var private float						TimeToAnnounceStillCovering;

var private vector						LastCoverFromLocation;

// copied from our goal
var(parameters) vector					CoverLocation;
var(parameters) vector					CoverFromLocation;
var(parameters) vector					CommandOrigin;
var(parameters) bool					bShouldAimAround;

// config
var config float						InnerAimAroundFOVDegrees;
var config float						OuterAimAroundFOVDegrees;

var config float						MinDeltaWaitTimeToAnnounceStillCovering;
var config float						MaxDeltaWaitTimeToAnnounceStillCovering;

const kMinTimeToHitCoverLocation		= 0.333;
const kCoverUpdateTime					= 0.5;		// how often we check to make sure we are in position
const kMaxDistanceFromCoverFromLocation = 100.0;

///////////////////////////////////////////////////////////////////////////////
// 
// cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}
}


///////////////////////////////////////////////////////////////////////////////
// 
// State Code

latent function MoveToCoverFromLocation()
{
	CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(movementResource(), achievingGoal.priority, CoverFromLocation);
	assert(CurrentMoveToLocationGoal != None);
	CurrentMoveToLocationGoal.AddRef();

	CurrentMoveToLocationGoal.SetAcceptNearbyPath(true);
	CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);

	CurrentMoveToLocationGoal.postGoal(self);

	// wait until the move completes, or we can aim at the location that the officer is pointing at
	while (! CurrentMoveToLocationGoal.hasCompleted() && ! MovingCanAimAtCoverLocation())
	{
		yield();
	}

	CurrentMoveToLocationGoal.unPostGoal(self);

	CurrentMoveToLocationGoal.Release();
	CurrentMoveToLocationGoal = None;

	// set our last cover from location (where we are at this point)
	LastCoverFromLocation = m_Pawn.Location;
}

latent function RotateToFaceCoverLocation()
{
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(CoverLocation - m_Pawn.Location));
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

private function bool CanAimAtCoverLocation()
{
	local vector EyePoint;

	EyePoint    = m_Pawn.Location;
	EyePoint.Z += m_Pawn.BaseEyeHeight;

	return (m_Pawn.FastTrace(CoverLocation, EyePoint) == true);
}

private function bool MovingCanAimAtCoverLocation()
{
	// if we're moving to a cover location that's not the command origin, we just try and move there without stopping
	// otherwise we stop when we can hit the cover location
	if (CoverFromLocation != CommandOrigin)
	{
		return false;
	}
	else
	{
		if (CanAimAtCoverLocation())
		{
			if (StartCanHitCoverLocationTime == 0.0)
			{
				StartCanHitCoverLocationTime = m_Pawn.Level.TimeSeconds;
			}
			else if ((StartCanHitCoverLocationTime != 0.0) && (Level.TimeSeconds >= (StartCanHitCoverLocationTime + kMinTimeToHitCoverLocation)))
			{
				return true;
			}
		}
		else
		{
			StartCanHitCoverLocationTime = 0.0;
		}

		return false;
	}
}

function AimAroundAtCoverLocation()
{
	CurrentAimAroundGoal = new class'AimAroundGoal'(weaponResource(), achievingGoal.priority);
	assert(CurrentAimAroundGoal != None);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.SetAimWeapon(false);
	CurrentAimAroundGoal.SetDoOnce(false);
	CurrentAimAroundGoal.SetOnlyAimIfMoving(false);
	CurrentAimAroundGoal.SetAimInnerFovDegrees(InnerAimAroundFOVDegrees);
	CurrentAimAroundGoal.SetAimOuterFovDegrees(OuterAimAroundFOVDegrees);

	CurrentAimAroundGoal.postGoal(self);
}

private function SetTimeToAnnounceStillCovering()
{
	TimeToAnnounceStillCovering = Level.TimeSeconds + RandRange(MinDeltaWaitTimeToAnnounceStillCovering, MaxDeltaWaitTimeToAnnounceStillCovering);
}

private function bool HasMovedFarAwayFromCoverFromLocation()
{
	return (VSize2D(LastCoverFromLocation - m_Pawn.Location) > kMaxDistanceFromCoverFromLocation);
}

state Running
{
 Begin:
	clearDummyGoals();

	useResources(class'AI_Resource'.const.RU_ARMS);
	
	// if we aren't in a position to hit the target move into the command giver's position
	if (! CanAimAtCoverLocation())
	{
		MoveToCoverFromLocation();
	}

	RotateToFaceCoverLocation();

	useResources(class'AI_Resource'.const.RU_LEGS);

	if (bShouldAimAround)
	{
		clearDummyWeaponGoal();
		AimAroundAtCoverLocation();
	}

	// we don't complete until told to do something else
	SetTimeToAnnounceStillCovering();
 Waiting:

	sleep(kCoverUpdateTime);

	if (! bShouldAimAround && (Level.TimeSeconds > TimeToAnnounceStillCovering))
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerStillCoveringSpeech();

		SetTimeToAnnounceStillCovering();
	}

	if (! CanAimAtCoverLocation() && (! bShouldAimAround || HasMovedFarAwayFromCoverFromLocation()))
	{
		goto('Begin');
	}
	else
	{
		goto('Waiting');
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'CoverGoal'
}