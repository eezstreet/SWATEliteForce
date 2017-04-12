///////////////////////////////////////////////////////////////////////////////
// InvestigateACtion.uc - BarricadeAction class
// The Action that causes the AI to barricade

class InvestigateAction extends SuspiciousAction;
///////////////////////////////////////////////////////////////////////////////

const kMinInvestigateTime = 8.0;
const kMaxInvestigateTime = 15.0;

///////////////////////////////////////////////////////////////////////////////
//
// InvestigateAction variables

var private AimAroundGoal			CurrentAimAroundGoal;
var private AimAtPointGoal			CurrentAimAtPointGoal;

var private MoveToLocationGoal		CurrentMoveToLocationGoal;
var private RotateTowardPointGoal	CurrentRotateTowardPointGoal;

var config float					MinInvestigateDelayTime;
var config float					MaxInvestigateDelayTime;
var config float					ReactionSpeechChance;
var config float					MinInvestigateTime;
var config float					MaxInvestigateTime;

var private Timer					InvestigateTimeoutTimer;

// copied from our goal
var(parameters) vector				InvestigateLocation;
var(parameters) bool				bShouldWalkToInvestigate;

const kMinLookAtInvestigateDistance = 100.0;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}

	if (CurrentAimAtPointGoal != None)
	{
		CurrentAimAtPointGoal.Release();
		CurrentAimAtPointGoal = None;
	}

	if (CurrentMoveToLocationGoal != None)
	{
		CurrentMoveToLocationGoal.Release();
		CurrentMoveToLocationGoal = None;
	}

	if (CurrentRotateTowardPointGoal != None)
	{
		CurrentRotateTowardPointGoal.Release();
		CurrentRotateTowardPointGoal = None;
	}

	if (InvestigateTimeoutTimer != None)
	{
		InvestigateTimeoutTimer.timerDelegate = None;
		InvestigateTimeoutTimer.Destroy();
		InvestigateTimeoutTimer = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	instantFail(errorCode);
}

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	super.goalAchievedCB(goal, child);

	if (goal == CurrentMoveToLocationGoal)
	{
		if (isIdle())
			runAction();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveToInvestigationDestination()
{
    CurrentMoveToLocationGoal = new class'MoveToLocationGoal'(movementResource(), achievingGoal.Priority, InvestigateLocation);
    assert(CurrentMoveToLocationGoal != None);
	CurrentMoveToLocationGoal.AddRef();

	CurrentMoveToLocationGoal.SetRotateTowardsFirstPoint(true);
	CurrentMoveToLocationGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToLocationGoal.SetAcceptNearbyPath(true);
	CurrentMoveToLocationGoal.SetShouldWalkEntireMove(bShouldWalkToInvestigate);

    // post the move to goal
    CurrentMoveToLocationGoal.postGoal(self);
}

latent function AimAtInvestigationLocation()
{
	// first, remove the aim around goal, if it's around
	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.unPostGoal(self);
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}

	CurrentAimAtPointGoal = new class'AimAtPointGoal'(weaponResource(), InvestigateLocation);
	assert(CurrentAimAtPointGoal != None);
	CurrentAimAtPointGoal.AddRef();

	// post the aim at point goal
	CurrentAimAtPointGoal.postGoal(self);
}

function AimAround(float InnerFOVDegrees, float OuterFOVDegrees, bool bOnlyAimIfMoving)
{
	// first, remove the aim at point goal, if it's around
	if (CurrentAimAtPointGoal != None)
	{
		CurrentAimAtPointGoal.unPostGoal(self);
		CurrentAimAtPointGoal.Release();
		CurrentAimAtPointGoal = None;
	}

	// now create the aim around goal
    CurrentAimAroundGoal = new class'AimAroundGoal'(weaponResource());
    assert(CurrentAimAroundGoal != None);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.SetAimInnerFovDegrees(InnerFOVDegrees);
	CurrentAimAroundGoal.SetAimOuterFovDegrees(OuterFOVDegrees);
	CurrentAimAroundGoal.SetAimWeapon(true);
	CurrentAimAroundGoal.SetOnlyAimIfMoving(bOnlyAimIfMoving);
    CurrentAimAroundGoal.postGoal(self);
}

function bool CanLookAtInvestigateLocation()
{
	return (m_Pawn.FastTrace(m_Pawn.Location, InvestigateLocation) || 
		(VSize(m_Pawn.Location - InvestigateLocation) < kMinLookAtInvestigateDistance));
}

private function StartInvestigateTimeoutTimer()
{
	assert(InvestigateTimeoutTimer == None);

	InvestigateTimeoutTimer = m_Pawn.Spawn(class'Timer', m_Pawn);
	InvestigateTimeoutTimer.timerDelegate = instantSucceed;
	InvestigateTimeoutTimer.startTimer(RandRange(MinInvestigateTime, MaxInvestigateTime), false);
}

state Running
{
Begin:
	// use all the resources
	useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);

	sleep(RandRange(MinInvestigateDelayTime, MaxInvestigateDelayTime));

	// trigger the sound based on a die roll
	if (FRand() < ReactionSpeechChance)
	{
		// trigger the investigate speech
		ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerInvestigateSpeech();
	}

	StartInvestigateTimeoutTimer();

	CheckWeaponStatus();

	// clear the resources
	ClearDummyWeaponGoal();
	ClearDummyMovementGoal();

	// aim around while we move to our investigation destination
    AimAround(45.0, 60.0, true);
    MoveToInvestigationDestination();

	UseResources(class'AI_Resource'.const.RU_ARMS);

	// poll. grrr.
	while (! CanLookAtInvestigateLocation())
	{
		yield();	
	}

	ClearDummyWeaponGoal();

	AimAtInvestigationLocation();

	pause();

    // aim around again
    AimAround(180.0, 360.0, false);

	sleep(RandRange(kMinInvestigateTime, kMaxInvestigateTime));
	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'InvestigateGoal'
}