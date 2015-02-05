///////////////////////////////////////////////////////////////////////////////
// WatchNonHostileTargetAction.uc - the WatchNonHostileTargetAction class
// behavior that causes the Officer AI to watch AIs that are compliant or restrained

class WatchNonHostileTargetAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// AI that we're watching
var private Pawn					CurrentWatchTarget;

// behaviors we use
var private AimAtTargetGoal			CurrentAimAtTargetGoal;
var private RotateTowardActorGoal	CurrentRotateTowardActorGoal;

var config float					MinWatchTargetTime;
var config float					MaxWatchTargetTime;
var config float					MinDistanceToAimGun;

var config float					MinDeltaTimeBetweenSpeakingToTarget;
var config float					MaxDeltaTimeBetweenSpeakingToTarget;

// internal
var private Pawn					LastSpokenToWatchTarget;
var private float					NextSpokenToWatchTargetTime;

///////////////////////////////////////////////////////////////////////////////
// 
// Init / cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	// find the initial watch target
	FindInitialWatchTarget();
	
	if (m_Pawn.logTyrion)
		log(m_Pawn.Name $ " is going to watch CurrentWatchTarget: " $ CurrentWatchTarget);
}

function cleanup()
{
	super.cleanup();

	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}

	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}

	// let the hive know we're done with watching this target
	if (CurrentWatchTarget != None)
	{
		SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().RemoveWatchedAI(CurrentWatchTarget);
	}
}

///////////////////////////////////////////////////////////////////////////////
// 
// Selection Heuristic

private function Pawn GetPotentialWatchTarget()
{
	local Pawn PotentialWatchTarget;

	PotentialWatchTarget = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().FindTargetToWatchForOfficer(m_Pawn);

	return PotentialWatchTarget;
}

private function FindInitialWatchTarget()
{
	CurrentWatchTarget = GetPotentialWatchTarget();
	
	if (CurrentWatchTarget != None)
	{
		// claim the watch target
		SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().AddWatchedAI(CurrentWatchTarget);
	}
}


// returns true if we find a new potential watch target
// false if it isn't a new target
private function bool FindNewWatchTarget()
{
	local Pawn OriginalWatchTarget;

	OriginalWatchTarget = CurrentWatchTarget;

	assert(CurrentWatchTarget != None);
	// let the hive know we're done with watching this target (for now)
	SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().RemoveWatchedAI(CurrentWatchTarget);

	CurrentWatchTarget = GetPotentialWatchTarget();

	if (CurrentWatchTarget != None)
	{
		// let the hive know we're watching this target
		SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().AddWatchedAI(CurrentWatchTarget);
	}

	return (OriginalWatchTarget != CurrentWatchTarget);
}


function float selectionHeuristic( AI_Goal goal )
{
	local Pawn PotentialWatchTarget;

	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	// we can only be selected if the resources are available
	if (! AI_Resource(m_Pawn.characterAI).requiredResourcesAvailable(goal.priority, goal.priority, goal.priority))
		return 0.0;

	PotentialWatchTarget = GetPotentialWatchTarget();

	// check with the hive to determine if we are usable
	if (PotentialWatchTarget != None)
	{
		return 1.0;
	}
	else
	{
		return 0.0;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  failing.");

	// just fail
	InstantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
// 
// State Code

function AimAtWatchTarget()
{
	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.unPostGoal(self);
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}

	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.unPostGoal(self);
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}

	// only aim at them if they're a minimum distance away
	if (VSize2D(m_Pawn.Location - CurrentWatchTarget.Location) > MinDistanceToAimGun)
	{
		CurrentAimAtTargetGoal = new class'AimAtTargetGoal'(weaponResource(), achievingGoal.priority, CurrentWatchTarget);
		assert(CurrentAimAtTargetGoal != None);
		CurrentAimAtTargetGoal.AddRef();

		CurrentAimAtTargetGoal.SetAimOnlyWhenCanHitTarget(true);
		CurrentAimAtTargetGoal.SetAimWeapon(true);

		CurrentAimAtTargetGoal.postGoal(self);
	}
	else
	{
		CurrentRotateTowardActorGoal = new class'RotateTowardActorGoal'(movementResource(), achievingGoal.priority, CurrentWatchTarget);
		assert(CurrentRotateTowardActorGoal != None);
		CurrentRotateTowardActorGoal.AddRef();

		CurrentRotateTowardActorGoal.postGoal(self);
	}
}

private function SpeakToCompliantTarget()
{
	LastSpokenToWatchTarget     = CurrentWatchTarget;
	NextSpokenToWatchTargetTime = Level.TimeSeconds + RandRange(MinDeltaTimeBetweenSpeakingToTarget, MaxDeltaTimeBetweenSpeakingToTarget);

	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerCoveringTargetSpeech();
}

state Running
{
 Begin:	
	if (! class'Pawn'.static.checkConscious(CurrentWatchTarget))
	{
		fail(ACT_GENERAL_FAILURE);
	}

	AimAtWatchTarget();

	// only use the resources if we aren't already
	if ((CurrentAimAtTargetGoal != None) && (dummyMovementGoal == None))
		useResources(class'AI_Resource'.const.RU_LEGS);
	else if ((CurrentRotateTowardActorGoal != None) && (dummyWeaponGoal == None))
		useResources(class'AI_Resource'.const.RU_ARMS);

 Wait:
	sleep(RandRange(MinWatchTargetTime, MaxWatchTargetTime));

	if (CurrentWatchTarget.IsCompliant() &&
		((LastSpokenToWatchTarget != CurrentWatchTarget) || (Level.TimeSeconds >= NextSpokenToWatchTargetTime)))
	{
		SpeakToCompliantTarget();
	}

	// try and find a new watch target
	// if we find one, we will aim at them, 
	// if we don't we just wait for a bit and try again later
	if (FindNewWatchTarget())
	{
		goto('Begin');
	}
	else
	{
		goto('Wait');
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'WatchNonHostileTargetGoal'
}