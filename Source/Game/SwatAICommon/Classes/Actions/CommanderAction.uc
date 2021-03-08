///////////////////////////////////////////////////////////////////////////////
// CommanderAction.uc - the CommanderAction class
// this base class is used by AIs to organize their behaviors

class CommanderAction extends SwatCharacterAction
	implements Tyrion.ISensorNotification
	native
	abstract;
///////////////////////////////////////////////////////////////////////////////

import enum ESkeletalRegion from Engine.Actor;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) PatrolList				Patrol;
var(parameters) bool					bStartIncapacitated;
var(parameters) name					StartIncapacitateIdleCategoryOverride;

// Goals

var protected RestrainedGoal			CurrentRestrainedGoal;
var private FlashbangedGoal				CurrentFlashbangedGoal;
var private GassedGoal					CurrentGassedGoal;
var private PepperSprayedGoal			CurrentPepperSprayedGoal;
var protected  PatrolGoal				CurrentPatrolGoal;
var protected IncapacitatedGoal			CurrentIncapacitatedGoal;
var private IdleGoal					CurrentIdleGoal;
var private ReactToBeingShotGoal		CurrentReactToBeingShotGoal;
var private TasedGoal					CurrentTasedGoal;
var private StunnedByC2Goal				CurrentStunnedByC2Goal;
var private StungGoal					CurrentStungGoal;

var private MoveToActorGoal				CurrentMoveToActorGoal;			// for moving away from doors, etc.
var protected RotateTowardActorGoal		CurrentRotateTowardActorGoal;
var protected RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var protected AimAtTargetGoal			CurrentAimAtTargetGoal;
var private AvoidLocationGoal			CurrentAvoidLocationGoal;

// Sensors

var protected HearingSensor				HearingSensor;
var protected VisionSensor				VisionSensor;
var protected ThreatenedSensor			ThreatenedSensor;
var protected ComplySensor				ComplySensor;

// Morale / Compliance variables
struct native MoraleHistoryEntry
{
    var float  ChangeAmount;
    var string ReasonForChange;
};

var private array<MoraleHistoryEntry>   MoraleHistory;
var private float                       CurrentMorale;
var protected ComplianceGoal			CurrentComplianceGoal;
var private bool						bListeningForCompliance;
var private int							ComplianceOrdersIgnored;		// so Officers keep asking for compliance to a point

// Config
var config int							MaxComplianceOrdersToIgnore;
var config float						MaxMorale;

// Screaming
var private Timer						ScreamTimer;
var config float						MinScreamTime;
var config float						MaxScreamTime;

var config float						MinReactToGunshotDistance;

// Constants

const kMoveAwayFromLocationGoalPriority = 94;


///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	ActivateVisionSensor();
	ActivateHearingSensor();
	ActivateThreatenedSensor();

	FindIdleGoal();

	StartPatrolling();

	// if we're supposed to start incapacitated, do that
	if (bStartIncapacitated)
	{
		BecomeIncapacitated(StartIncapacitateIdleCategoryOverride);
	}
}

// if you override, call down the chain
protected function ActivateVisionSensor()
{
	VisionSensor = VisionSensor(class'AI_Sensor'.static.activateSensor( self, class'VisionSensor', resource, 0, 1000000 ));
	assert(VisionSensor != None);
}

private function ActivateHearingSensor()
{
	HearingSensor = HearingSensor(class'AI_Sensor'.static.activateSensor( self, class'HearingSensor', resource, 0, 1000000 ));
	assert(HearingSensor != None);
}

private function ActivateThreatenedSensor()
{
	ThreatenedSensor = ThreatenedSensor(class'AI_Sensor'.static.activateSensor( self, class'ThreatenedSensor', resource, 0, 1000000 ));
	assert(ThreatenedSensor != None);
}

protected function ActivateComplySensor()
{
	ComplySensor = ComplySensor(class'AI_Sensor'.static.activateSensor( self, class'ComplySensor', resource, 0, 1000000 ));
	assert(ComplySensor != None);
}

protected function InitializeMorale()
{
	ChangeMorale(ISwatAI(m_Pawn).GetInitialMorale(), "Initial Morale Setting");
}

private function FindIdleGoal()
{
	CurrentIdleGoal = IdleGoal(characterResource().findGoalByName("Idle"));
	assert(CurrentIdleGoal != None);
	CurrentIdleGoal.AddRef();
}


///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentComplianceGoal != None)
	{
		CurrentComplianceGoal.release();
		CurrentComplianceGoal = None;
	}

	if (CurrentRestrainedGoal != None)
	{
		CurrentRestrainedGoal.Release();
		CurrentRestrainedGoal = None;
	}

	if (CurrentFlashbangedGoal != None)
	{
		CurrentFlashbangedGoal.Release();
		CurrentFlashbangedGoal = None;
	}

	if (CurrentGassedGoal != None)
	{
		CurrentGassedGoal.Release();
		CurrentGassedGoal = None;
	}

	if (CurrentPepperSprayedGoal != None)
	{
		CurrentPepperSprayedGoal.Release();
		CurrentPepperSprayedGoal = None;
	}

	if (CurrentPatrolGoal != None)
	{
		CurrentPatrolGoal.Release();
		CurrentPatrolGoal = None;
	}

	if (CurrentIncapacitatedGoal != None)
	{
		CurrentIncapacitatedGoal.Release();
		CurrentIncapacitatedGoal = None;
	}

	if (CurrentIdleGoal != None)
	{
		CurrentIdleGoal.Release();
		CurrentIdleGoal = None;
	}

	if (CurrentReactToBeingShotGoal != None)
	{
		CurrentReactToBeingShotGoal.Release();
		CurrentReactToBeingShotGoal = None;
	}

	if (CurrentTasedGoal != None)
	{
		CurrentTasedGoal.Release();
		CurrentTasedGoal = None;
	}

	if (CurrentStunnedByC2Goal != None)
	{
		CurrentStunnedByC2Goal.Release();
		CurrentStunnedByC2Goal = None;
	}

	if (CurrentStungGoal != None)
	{
		CurrentStungGoal.Release();
		CurrentStungGoal = None;
	}

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}

	if (CurrentAvoidLocationGoal != None)
	{
		CurrentAvoidLocationGoal.Release();
		CurrentAvoidLocationGoal = None;
	}

	if (HearingSensor != None)
	{
		HearingSensor.deactivateSensor(self);
		HearingSensor = None;
	}

	if (VisionSensor != None)
	{
		VisionSensor.deactivateSensor(self);
		VisionSensor = None;
	}

	if (ThreatenedSensor != None)
	{
		ThreatenedSensor.deactivateSensor(self);
		ThreatenedSensor = None;
	}

	if (ComplySensor != None)
	{
		ComplySensor.deactivateSensor(self);
		ComplySensor = None;
	}

	if (ScreamTimer != None)
	{
		ScreamTimer.timerDelegate = None;
		ScreamTimer.Destroy();
		ScreamTimer = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.Name $ " was not achieved on " $ m_Pawn.Name $ " because of error " $ errorCode $ " child is " $ child);

	if ((goal == CurrentRestrainedGoal) && !ISwatAI(m_Pawn).IsArrested())
	{
		CurrentRestrainedGoal.unPostGoal(self);
		CurrentRestrainedGoal.Release();
		CurrentRestrainedGoal = None;

		// repost the compliance goal because restrained failed
		PostComplianceGoal();
	}
	else if ((goal == CurrentPatrolGoal) && ShouldRemoveFailedPatrolGoal())
	{
		CurrentPatrolGoal.unPostGoal(self);
		CurrentPatrolGoal.Release();
		CurrentPatrolGoal = None;
	}
	else if (goal == CurrentReactToBeingShotGoal)
	{
		CurrentReactToBeingShotGoal.unPostGoal(self);
		CurrentReactToBeingShotGoal.Release();
		CurrentReactToBeingShotGoal = None;
	}
}

protected function bool ShouldRemoveFailedPatrolGoal()
{
	return true;
}

function goalAchievedCB( AI_Goal goal, AI_Action child )
{
	super.goalAchievedCB(goal, child);

	// cleanup after a react to being shot goal completes
	if (goal == CurrentReactToBeingShotGoal)
	{
		CurrentReactToBeingShotGoal.Release();
		CurrentReactToBeingShotGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Messages

// does the sound category describe a noise that happens when people can be killed
function bool IsDeadlyNoise(name SoundCategory)
{
	if ((SoundCategory == 'Gunshots') ||
		(SoundCategory == 'BulletHitSpangs') ||
		(SoundCategory == 'Explosions'))
	{
		return true;
	}
	else
	{
		return false;
	}
}

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	// don't log hearing sensor messages, there's just too many of them
	if (m_Pawn.logTyrion && (sensor != HearingSensor))
		log(m_Pawn.Name $ "'s CommanderAction received sensor message from " $ sensor.name $ " value is "$ value.integerData);

	if (Sensor == VisionSensor)
	{
		// if LastPawnSeen isn't None, we just saw somebody
		if (VisionSensor.LastPawnSeen != None)
		{
			OnPawnEncounteredVisionNotification();
		}
		else
		{
			// sanity check
			assert(VisionSensor.LastPawnLost != None);
			OnPawnLostVisionNotification();
		}
	}
	else if (Sensor == HearingSensor)
	{
		OnHeardNoise();
	}
	else if (Sensor == ThreatenedSensor)
	{
		if (ThreatenedSensor.ThreatenedBy != None)
		{
			OnThreatened();
		}
		else // (ThreatenedBy == None)
		{
			OnNoLongerThreatened();
		}
	}
	else if (Sensor == ComplySensor)
	{
		assert(value.objectData != None);
		assert(value.objectData.IsA('Pawn'));

		OnComplianceIssued(Pawn(value.objectData));
	}
}

// Events that should be overridden
function OnPawnEncounteredVisionNotification();
function OnPawnLostVisionNotification();
function OnHeardNoise();
function OnThreatened();
function OnNoLongerThreatened();

// Noise helper function
protected function bool HasLineOfSightToDoor(Door TestDoor)
{
	local array<Actor> DoorModels;
	local int i;

	DoorModels = ISwatDoor(TestDoor).GetDoorModels();

	for(i=0; i<DoorModels.Length; ++i)
	{
		if (m_Pawn.LineOfSightTo(DoorModels[i]))
		{
			return true;
		}
	}

	// no line of sight
	return false;
}

///////////////////////////////////////////////////////////////////////////////
//
// Compliance

// This is a shared event response (no overriding!)
// Called when someone orders us to comply
function OnComplianceIssued(Pawn ComplianceIssuer)
{
	local bool bWillComply;
	local float RandomChance;
        local float FlashlightOnChanceModifier = 0.2;

	if (m_Pawn.logAI)
		log("Compliance issued from: "$ComplianceIssuer.Name$" to: "$m_Pawn.name);

	if (! ISwatAI(m_Pawn).IsArrested() &&
		! ISwatAI(m_Pawn).IsCompliant() &&
		! m_Pawn.IsIncapacitated())
	{
		// allow subclasses to do some things before we check compliance
		PreComplianceCheck(ComplianceIssuer);

		if (bListeningForCompliance)
		{
			// formula for compliance check is
			// if the percentage chance (1 - Frand()) is greater than the current morale, we will comply
			// otherwise we do nothing
			RandomChance = 1.0 - FRand();
			
			//if the ComplianceIssuer Officer has flashlight on with a weapon equipped 
			if ( ComplierIssuer.isA('SwatOfficer') &&  SwatPawn(ComplianceIssuer).GetFlashlightState() && SwatPawn(ComplianceIssuer).hasFiredWeaponEquipped() )
			{
				RandomChance = RandomChance + FlashlightOnChanceModifier;
			}
			
			if (RandomChance >= GetCurrentMorale())
			{
				if (m_Pawn.logAI)
					log(m_Pawn.Name$" will comply - morale is: " $ GetCurrentMorale() $ " RandomChance is: " $ RandomChance);

				bWillComply = true;
			}
			else
			{
				if (m_Pawn.logAI)
					log(m_Pawn.Name$" will not comply - morale is: " $ GetCurrentMorale() $ " RandomChance is: " $ RandomChance);

				bWillComply = false;
			}

			// don't listen for compliance until morale changes
			bListeningForCompliance = false;
			// and if we are armed, insane suspects, become threats (SANITY CHECKS DAMN IT!)
            if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard')) || (!m_Pawn.IsA('SwatHostage'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None) && ISwatAICharacter(m_Pawn).IsInsane())
            {
                ISwatEnemy(m_Pawn).BecomeAThreat();
            }

			// reset how many compliance orders we've ignored
			ComplianceOrdersIgnored = 0;

			if (bWillComply)
			{
				PostComplianceGoal();
			}
		}
		else
		{
			// we're ignoring another compliance order
			++ComplianceOrdersIgnored;

			// let the hive know if we've had enough (heh heh, it's supposed to look like the officer has had enough...)
			if (IsIgnoringComplianceOrders())
			{
				SwatAIRepository(Level.AIRepo).GetHive().NotifyAIIgnoringOfficers(m_Pawn);
			}
		}

		PostComplianceCheck(ComplianceIssuer, bWillComply);
	}
}

// allows subclasses to do things before and after we check for compliance
function PreComplianceCheck(Pawn ComplianceIssuer);
function PostComplianceCheck(Pawn ComplianceIssuer, bool bWillComply);


// query to see if we're ignoring compliance orders
// after a certain number of compliance orders, we are now ignoring compliance
native function bool IsIgnoringComplianceOrders();

function bool IsListeningForCompliance()
{
	return bListeningForCompliance;
}

// overridden completely by HostageCommanderAction
protected function DisableSensingSystems()
{
	// we don't need awareness or senses anymore
	ISwatAI(m_Pawn).DisableAwareness();
	DisableSenses(true);
}

private function PostComplianceGoal()
{
	// if we haven't already complied
	if (! ISwatAI(m_Pawn).IsCompliant())
	{
		ISwatAI(m_Pawn).SetIsCompliant(true);
	}

	if (CurrentComplianceGoal == None)
	{
		CurrentComplianceGoal = new class'ComplianceGoal'(characterResource());
		assert(CurrentComplianceGoal != None);
		CurrentComplianceGoal.AddRef();

		CurrentComplianceGoal.postGoal(self);
	}

	// compliant AIs have a smaller collision radius
	ISwatAI(m_Pawn).NotifyBecameCompliant();

	// allow subclasses to extend functionality
	NotifyBecameCompliant();

	// disable awareness, vision, and (maybe) hearing
	// (marc: disable because AI's may become non-compliant again)
	//DisableSensingSystems();

	// make sure we're paused
	// (marc: now handled in state code)
	//gotostate('');
}

// subclasses should call down the chain
protected function NotifyBecameCompliant()
{
	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.unPostGoal(self);
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.unPostGoal(self);
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.unPostGoal(self);
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.unPostGoal(self);
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}

	if (CurrentAvoidLocationGoal != None)
	{
		CurrentAvoidLocationGoal.unPostGoal(self);
		CurrentAvoidLocationGoal.Release();
		CurrentAvoidLocationGoal = None;
	}
}

function RemoveComplianceGoal()
{
	if (CurrentComplianceGoal != None)
	{
		CurrentComplianceGoal.unPostGoal(self);
		CurrentComplianceGoal.Release();
		CurrentComplianceGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Restrained

function NotifyBeginArrest(Pawn inRestrainer)
{
	assert(inRestrainer != None);

	if (CurrentRestrainedGoal != None)
	{
		CurrentRestrainedGoal.unPostGoal(self);
		CurrentRestrainedGoal.Release();
		CurrentRestrainedGoal = None;
	}

	CurrentRestrainedGoal = new class'RestrainedGoal'(characterResource(), inRestrainer);
	assert(CurrentRestrainedGoal != None);
	CurrentRestrainedGoal.AddRef();

	CurrentRestrainedGoal.postGoal(self);
}

function NotifyArrestInterrupted()
{
	if ((CurrentRestrainedGoal != None) && (CurrentRestrainedGoal.achievingAction != None))
	{
		assert(CurrentRestrainedGoal.achievingAction.IsA('RestrainedAction'));

		RestrainedAction(CurrentRestrainedGoal.achievingAction).RestrainInterrupted();
	}
}

function NotifyRestrained()
{
	RemoveComplianceGoal();

	ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerRestrainedSpeech();
}

function bool IsRestrainedGoalRunning()
{
	return ((CurrentRestrainedGoal != None) && !CurrentRestrainedGoal.hasCompleted());
}

///////////////////////////////////////////////////////////////////////////////
//
// Idling

function ResetIdling()
{
	// if the current idle goal is not none, it could be none because the AI is dying or incapacitated
	if (CurrentIdleGoal != None)
	{
		if (CurrentIdleGoal.achievingAction != None)
		{
			CurrentIdleGoal.achievingAction.instantSucceed();
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Patrolling

function StartPatrolling()
{
	if (Patrol != None)
	{
		// create and post the Patrol goal
		CurrentPatrolGoal = new class'SwatAICommon.PatrolGoal'( characterResource(), Patrol );
		assert(CurrentPatrolGoal != None);
		CurrentPatrolGoal.AddRef();

		CurrentPatrolGoal.postGoal( self );
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Death / Damage

// called by the commander, not directly
function BecomeIncapacitated(optional name IncapaciatedIdleCategoryOverride)
{
	// remove any non death goals
	RemoveNonDeathGoals();

	// if we didn't start incapacitated, remove the idle goal
	if (! bStartIncapacitated)
	{
		RemoveIdleGoal();
	}

	if (CurrentIncapacitatedGoal == None)
	{
		CurrentIncapacitatedGoal = new class'SwatAICommon.IncapacitatedGoal'(characterResource(), bStartIncapacitated, IncapaciatedIdleCategoryOverride);
		assert(CurrentIncapacitatedGoal != None);
		CurrentIncapacitatedGoal.AddRef();

		CurrentIncapacitatedGoal.postGoal(self);
	}
}

private function RemoveIdleGoal()
{
	// remove the idle goal
	if (CurrentIdleGoal != None)
	{
		CurrentIdleGoal.unPostGoal(None);
		CurrentIdleGoal.Release();
		CurrentIdleGoal = None;
	}
}

// removes any goals that aren't related to dying or incapacitation
// (except Idle, which is special case)
// subclasses should always call down the chain
function RemoveNonDeathGoals()
{
	// disable the screaming timer
	if (ScreamTimer != None)
	{
		ScreamTimer.timerDelegate = None;
		ScreamTimer.Destroy();
		ScreamTimer = None;
	}

	// disable hearing permanently (in case it wasn't -- hostage and enemies do this, officers don't)
	ISwatAI(m_Pawn).DisableHearing(true);

	// remove the compliance goal
	if (CurrentComplianceGoal != None)
	{
		CurrentComplianceGoal.unPostGoal(self);
		CurrentComplianceGoal.Release();
		CurrentComplianceGoal = None;
	}

	// remove the restrained goal
	if (CurrentRestrainedGoal != None)
	{
		CurrentRestrainedGoal.unPostGoal(self);
		CurrentRestrainedGoal.Release();
		CurrentRestrainedGoal = None;
	}

	// remove the flashbanged goal
	if (CurrentFlashbangedGoal != None)
	{
		CurrentFlashbangedGoal.unPostGoal(self);
		CurrentFlashbangedGoal.Release();
		CurrentFlashbangedGoal = None;
	}

	// remove the gassed goal
	if (CurrentGassedGoal != None)
	{
		CurrentGassedGoal.unPostGoal(self);
		CurrentGassedGoal.Release();
		CurrentGassedGoal = None;
	}

	// remove the pepper sprayed goal
	if (CurrentPepperSprayedGoal != None)
	{
		CurrentPepperSprayedGoal.unPostGoal(self);
		CurrentPepperSprayedGoal.Release();
		CurrentPepperSprayedGoal = None;
	}

	// remove the stunned by c2 goal
	if (CurrentStunnedByC2Goal != None)
	{
		CurrentPepperSprayedGoal.unPostGoal(self);
		CurrentPepperSprayedGoal.Release();
		CurrentPepperSprayedGoal = None;
	}

	// remove the stung goal
	if (CurrentStungGoal != None)
	{
		CurrentStungGoal.unPostGoal(self);
		CurrentStungGoal.Release();
		CurrentStungGoal = None;
	}

	// remove the patrol goal
	if (CurrentPatrolGoal != None)
	{
		CurrentPatrolGoal.unPostGoal(self);
		CurrentPatrolGoal.Release();
		CurrentPatrolGoal = None;
	}

	// remove the react to being shot goal
	if (CurrentReactToBeingShotGoal != None)
	{
		CurrentReactToBeingShotGoal.unPostGoal(self);
		CurrentReactToBeingShotGoal.Release();
		CurrentReactToBeingShotGoal = None;
	}

	// remove the tased goal
	if (CurrentTasedGoal != None)
	{
		CurrentTasedGoal.unPostGoal(self);
		CurrentTasedGoal.Release();
		CurrentTasedGoal = None;
	}

	// remove the move to goal
	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.unPostGoal(self);
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	// remove the rotate toward goal
	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.unPostGoal(self);
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.unPostGoal(self);
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	// remove the aim at target goal
	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.unPostGoal(self);
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}

	// remove the avoid location goal
	if (CurrentAvoidLocationGoal != None)
	{
		CurrentAvoidLocationGoal.unPostGoal(self);
		CurrentAvoidLocationGoal.Release();
		CurrentAvoidLocationGoal = None;
	}
}

// we are going to die (not incapacitated), remove all unnecessary goals
function RemoveGoalsToDie()
{
	// remove any non-death goals
	RemoveNonDeathGoals();

	// remove the incapacitated goal because now we're dead
	if (CurrentIncapacitatedGoal != None)
	{
		CurrentIncapacitatedGoal.unPostGoal(self);
		CurrentIncapacitatedGoal.Release();
		CurrentIncapacitatedGoal = None;
	}

	// remove the idle goal
	RemoveIdleGoal();
}

// subclasses should call down the chain
function OnSkeletalRegionHit(ESkeletalRegion RegionHit, vector HitLocation, vector HitNormal, int Damage, class<DamageType> DamageType)
{
	if ((Damage > 0) && m_Pawn.IsConscious())
	{
   		// only react if we're not already reacting
		if ((CurrentIncapacitatedGoal == None) &&
			(CurrentReactToBeingShotGoal == None))
		{
			CurrentReactToBeingShotGoal = new class'ReactToBeingShotGoal'(characterResource(), RegionHit, HitLocation, HitNormal);
			assert(CurrentReactToBeingShotGoal != None);
			CurrentReactToBeingShotGoal.AddRef();

			CurrentReactToBeingShotGoal.postGoal(self);
		}
		else if ((CurrentReactToBeingShotGoal != None) && (CurrentReactToBeingShotGoal.achievingAction != None))
		{
			ReactToBeingShotAction(CurrentReactToBeingShotGoal.achievingAction).PlayQuickHit(HitLocation);
		}

		NotifyTookHit();

		// Allow subclasses to decrement morale,
		// but we don't start listening for compliance to avoid having players shooting a character in a leg to get him to comply
		ChangeMorale(-GetShotMoraleModification(), "Shot", true);
	}
}

// subclasses may implement
function NotifyTookHit();

// override me
function float GetShotMoraleModification()
{
	return 0.0;
}

///////////////////////////////////////////////////////////////////////////////
//
// Scream / Flinching

protected function Scream()
{
	if (ScreamTimer == None)
	{
		ScreamTimer               = m_Pawn.Spawn(class'Timer');
		ScreamTimer.TimerDelegate = TriggerScreamSpeech;
	}

	ScreamTimer.StartTimer(RandRange(MinScreamTime, MaxScreamTime), false, true);
}

function TriggerScreamSpeech()
{
	if (m_Pawn.IsConscious())
	{
		ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerScreamSpeech();
	}
}

protected function bool ShouldScream()
{
	return false;
}

protected function PlayFlinch()
{
	local name FlinchAnimationName;

	log("PlayFlinch called on server for " $ m_Pawn.Name);

	// don't flinch if we're already animating on the special channel or if we're moving
	if (! m_Pawn.IsAnimating(m_Pawn.AnimGetSpecialChannel()) && (VSize(m_Pawn.Velocity) == 0.0) && !ISwatAI(m_Pawn).IsTurning())
	{
		FlinchAnimationName = ISwatAI(m_Pawn).GetFlinchAnimation();

		m_Pawn.AnimPlaySpecial(FlinchAnimationName, 0.1);

		// scream if we're supposed to
		if (ShouldScream())
		{
			Scream();
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Stunned functions

function float GetFlashbangedMoraleModification()			{ return 0.0; }
function float GetGassedMoraleModification()				{ return 0.0; }
function float GetPepperSprayedMoraleModification()			{ return 0.0; }
function float GetStungMoraleModification()					{ return 0.0; }
function float GetTasedMoraleModification()					{ return 0.0; }
function float GetStunnedByC2DetonationMoraleModification()	{ return 0.0; }
function float GetUnobservedComplianceMoraleModification()	{ return 0.0; }

function bool ShouldRunWhenFlashBanged()    { return true;  }
function bool ShouldRunWhenGassed()         { return true;  }
function bool ShouldRunWhenPepperSprayed()  { return false; }
function bool ShouldRunWhenStung()          { return true;  }
function bool ShouldRunWhenTased()          { return false; }
function bool ShouldRunWhenStunnedByC2()    { return true;  }

function NotifyFlashbanged(vector FlashbangLocation, float StunnedDuration)
{
	// create the reaction behavior
	if (CurrentFlashbangedGoal != None)
	{
		if (CurrentFlashbangedGoal.hasCompleted() || (CurrentFlashbangedGoal.achievingAction == None))
		{
			CurrentFlashbangedGoal.unPostGoal(self);
			CurrentFlashbangedGoal.Release();
			CurrentFlashbangedGoal = None;
		}
		else
		{
			assert(FlashbangedAction(CurrentFlashbangedGoal.achievingAction) != None);
			FlashbangedAction(CurrentFlashbangedGoal.achievingAction).ExtendBeingStunned(StunnedDuration);
		}
	}

	if (CurrentFlashbangedGoal == None)
	{
		CurrentFlashbangedGoal = new class'FlashbangedGoal'(characterResource(), FlashbangLocation, StunnedDuration);
		assert(CurrentFlashbangedGoal != None);
		CurrentFlashbangedGoal.AddRef();

        CurrentFlashbangedGoal.bShouldRunFromStunningDevice = ShouldRunWhenFlashBanged();
		CurrentFlashbangedGoal.postGoal(self);
	}
}

function NotifyGassed(vector GasContainerLocation, float StunnedDuration)
{
	// create the reaction behavior
	if (CurrentGassedGoal != None)
	{
		if (CurrentGassedGoal.hasCompleted() || (CurrentGassedGoal.achievingAction == None))
		{
			CurrentGassedGoal.unPostGoal(self);
			CurrentGassedGoal.Release();
			CurrentGassedGoal = None;
		}
		else
		{
			assert(GassedAction(CurrentGassedGoal.achievingAction) != None);
			GassedAction(CurrentGassedGoal.achievingAction).ExtendBeingStunned(StunnedDuration);
		}
	}

	if (CurrentGassedGoal == None)
	{
		CurrentGassedGoal = new class'GassedGoal'(characterResource(), GasContainerLocation, StunnedDuration);
		assert(CurrentGassedGoal != None);
		CurrentGassedGoal.AddRef();

        CurrentGassedGoal.bShouldRunFromStunningDevice = ShouldRunWhenGassed();
		CurrentGassedGoal.postGoal(self);
	}
}

function NotifyPepperSprayed(vector PepperSprayLocation, float StunnedDuration)
{
	// create the reaction behavior
	if (CurrentPepperSprayedGoal != None)
	{
		if (CurrentPepperSprayedGoal.hasCompleted() || (CurrentPepperSprayedGoal.achievingAction == None))
		{
			CurrentPepperSprayedGoal.unPostGoal(self);
			CurrentPepperSprayedGoal.Release();
			CurrentPepperSprayedGoal = None;
		}
		else
		{
			PepperSprayedAction(CurrentPepperSprayedGoal.achievingAction).ExtendBeingStunned(StunnedDuration);
		}
	}

	if (CurrentPepperSprayedGoal == None)
	{
		CurrentPepperSprayedGoal = new class'PepperSprayedGoal'(characterResource(), PepperSprayLocation, StunnedDuration);
		assert(CurrentPepperSprayedGoal != None);
		CurrentPepperSprayedGoal.AddRef();

        CurrentPepperSprayedGoal.bShouldRunFromStunningDevice = ShouldRunWhenPepperSprayed();
		CurrentPepperSprayedGoal.postGoal(self);
	}
}

function bool IsAffectedByPepperSpray()
{
	return (CurrentPepperSprayedGoal != None) && ! CurrentPepperSprayedGoal.hasCompleted();
}

function NotifyTased(vector TaserLocation, float StunnedDuration)
{
	if (CurrentTasedGoal != None)
	{
		if (CurrentTasedGoal.hasCompleted() || (CurrentTasedGoal.achievingAction == None))
		{
			CurrentTasedGoal.unPostGoal(self);
			CurrentTasedGoal.Release();
			CurrentTasedGoal = None;
		}
		else
		{
			assert(TasedAction(CurrentTasedGoal.achievingAction) != None);
			TasedAction(CurrentTasedGoal.achievingAction).ExtendBeingStunned(StunnedDuration);
		}
	}

	if (CurrentTasedGoal == None)
	{
		CurrentTasedGoal = new class'TasedGoal'(characterResource(), TaserLocation, StunnedDuration);
		assert(CurrentTasedGoal != None);
		CurrentTasedGoal.AddRef();

        CurrentTasedGoal.bShouldRunFromStunningDevice = ShouldRunWhenTased();
		CurrentTasedGoal.postGoal(self);
	}
}

function NotifyStunnedByC2Detonation(vector C2ChargeLocation, float StunnedDuration)
{
	// create the reaction behavior
	if (CurrentStunnedByC2Goal != None)
	{
		if (CurrentStunnedByC2Goal.hasCompleted() || (CurrentStunnedByC2Goal.achievingAction == None))
		{
			CurrentStunnedByC2Goal.unPostGoal(self);
			CurrentStunnedByC2Goal.Release();
			CurrentStunnedByC2Goal = None;
		}
		else
		{
			assert(StunnedByC2Action(CurrentStunnedByC2Goal.achievingAction) != None);
			StunnedByC2Action(CurrentStunnedByC2Goal.achievingAction).ExtendBeingStunned(StunnedDuration);
		}
	}

	if (CurrentStunnedByC2Goal == None)
	{
		CurrentStunnedByC2Goal = new class'StunnedByC2Goal'(characterResource(), C2ChargeLocation, StunnedDuration);
		assert(CurrentStunnedByC2Goal != None);
		CurrentStunnedByC2Goal.AddRef();

        CurrentStunnedByC2Goal.bShouldRunFromStunningDevice = ShouldRunWhenStunnedByC2();
		CurrentStunnedByC2Goal.postGoal(self);
	}
}

// if grenade is none, then we got hit by the bean bag
function NotifyStung(Actor Grenade, vector StungGrenadeLocation, float StunnedDuration)
{
	// create the reaction behavior
	if (CurrentStungGoal != None)
	{
		if (CurrentStungGoal.hasCompleted() || (CurrentStungGoal.achievingAction == None))
		{
			CurrentStungGoal.unPostGoal(self);
			CurrentStungGoal.Release();
			CurrentStungGoal = None;
		}
		else
		{
			assert(StungAction(CurrentStungGoal.achievingAction) != None);
			StungAction(CurrentStungGoal.achievingAction).ExtendBeingStunned(StunnedDuration);
		}
	}

	if (CurrentStungGoal == None)
	{
		CurrentStungGoal = new class'StungGoal'(characterResource(), Grenade, StungGrenadeLocation, StunnedDuration);
		assert(CurrentStungGoal != None);
		CurrentStungGoal.AddRef();

        CurrentStungGoal.bShouldRunFromStunningDevice = ShouldRunWhenStung();
		CurrentStungGoal.postGoal(self);
	}
}

// subclasses should override
protected function bool WillReactToGrenadeBeingThrown() { return true; }

function NotifyGrenadeThrown(SwatGrenadeProjectile ThrownGrenade)
{
	if (! ISwatAI(m_Pawn).IsCompliant() && !ISwatAI(m_Pawn).IsArrested())
	{
		if ((CurrentAvoidLocationGoal != None) && CurrentAvoidLocationGoal.hasCompleted())
		{
			CurrentAvoidLocationGoal.unPostGoal(self);
			CurrentAvoidLocationGoal.Release();
			CurrentAvoidLocationGoal = None;
		}

		if (CurrentAvoidLocationGoal == None)
		{
			if (WillReactToGrenadeBeingThrown() && m_Pawn.CanSee(ThrownGrenade))
			{
				CurrentAvoidLocationGoal = new class'AvoidLocationGoal'(characterResource(), ThrownGrenade.Location);
				assert(CurrentAvoidLocationGoal != None);
				CurrentAvoidLocationGoal.AddRef();

				CurrentAvoidLocationGoal.postGoal(self);
			}
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Morale functions

function float GetCurrentMorale()
{
    return CurrentMorale;
}

function ChangeMorale(float inChangeAmount, string inReasonForChange, optional bool bDoNotStartListeningForCompliance)
{
    local MoraleHistoryEntry NewMoraleHistoryEntry;

	// don't change morale if we are already compliant or restrained
	if ((CurrentComplianceGoal == None || inReasonForChange == "Unobserved Compliance") && (CurrentRestrainedGoal == None))
	{
		// changes that are 0 don't affect us
		if (inChangeAmount != 0.0)
		{
			// construct the history entry so we can keep track of how morale changed
			NewMoraleHistoryEntry.ChangeAmount    = inChangeAmount;
			NewMoraleHistoryEntry.ReasonForChange = inReasonForChange;

			MoraleHistory[MoraleHistory.Length]   = NewMoraleHistoryEntry;

			// now add to the current value
			CurrentMorale                        += inChangeAmount;

			// make sure we don't go over the MaxMorale value
			CurrentMorale						  = FMin(CurrentMorale, MaxMorale);

			if (m_Pawn.logAI)
				log("morale changed "$inChangeAmount$" for "$m_Pawn.Name$" because "$inReasonForChange);

			// if our morale has changed negatively, and we supposed to start listening for compliance
			// we are now listening for compliance
			if ((inChangeAmount < 0.0) && !bDoNotStartListeningForCompliance)
				bListeningForCompliance = true;
		}
	}
}

function int GetMoraleHistoryCount()
{
    return MoraleHistory.Length;
}

function string GetMoraleHistoryEntrySummary(int Index)
{
    assert(Index >= 0);
    assert(Index < MoraleHistory.Length);

    return "Morale changed "$ MoraleHistory[Index].ChangeAmount $" because " $ MoraleHistory[Index].ReasonForChange;
}

///////////////////////////////////////////////////////////////////////////////
//
// Utility Functions

protected function RotateToFace(Actor Target, int BehaviorPriority)
{
	assert(Target != None);

	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.unPostGoal(self);
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}

	CurrentRotateTowardActorGoal = new class'RotateTowardActorGoal'(movementResource(), BehaviorPriority, Target);
	assert(CurrentRotateTowardActorGoal != None);
	CurrentRotateTowardActorGoal.AddRef();

	CurrentRotateTowardActorGoal.postGoal(self);
}

protected function RotateToRotation(Rotator Rotation, int BehaviorPriority)
{
	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.unPostGoal(self);
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), BehaviorPriority, Rotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
}

protected function AimAtTarget(Actor Target, int BehaviorPriority, bool bAimWeapon, optional float MinAimAtTargetTime, optional float MaxAimAtTargetTime)
{
	assert(Target != None);

	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.unPostGoal(self);
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}

	CurrentAimAtTargetGoal = new class'AimAtTargetGoal'(weaponResource(), BehaviorPriority, Target);
	assert(CurrentAimAtTargetGoal != None);
	CurrentAimAtTargetGoal.AddRef();

	if ((MinAimAtTargetTime > 0.0) && (MaxAimAtTargetTime > 0.0))
	{
		CurrentAimAtTargetGoal.SetHoldAimTime(MinAimAtTargetTime, MaxAimAtTargetTime);
	}

	CurrentAimAtTargetGoal.SetAimOnlyWhenCanHitTarget(true);
	CurrentAimAtTargetGoal.SetAimWeapon(bAimWeapon);

	CurrentAimAtTargetGoal.postGoal(self);
}

///////////////////////////////////////////////////////////////////////////////
//
// Doors

// notification that we are blocking a door that someone is trying to close
function NotifyBlockingDoorClose(Door BlockedDoor)
{
	if (m_Pawn.logAI)
		log("NotifyBlockingDoorClose called for " $ m_Pawn);

	MoveMinimumDistanceAwayFromLocation(BlockedDoor.Location, BlockedDoor.CollisionRadius + (m_Pawn.CollisionRadius * 1.5));
}

// notification that we are blocking a door that someone is trying to open
// NOTE: we may need to have subclasses override functionality in the future [crombie]
function NotifyBlockingDoorOpen(Door BlockedDoor)
{
	ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerHitByDoorSpeech();

	MoveMinimumDistanceAwayFromLocation(BlockedDoor.Location, BlockedDoor.CollisionRadius + (m_Pawn.CollisionRadius * 2.0));
}

protected function bool CanMoveToActor()
{
	return ((CurrentMoveToActorGoal == None) || CurrentMoveToActorGoal.hasCompleted());
}

// returns true if we moved, false if we didn't
protected function bool MoveToActor(Actor Destination, int MovementBehaviorPriority, optional bool bZeroWalkThreshold)
{
	assert(Destination != None);
	assert(MovementBehaviorPriority > 0);

	if (m_Pawn.logAI)
		log("MoveToActor - CurrentMoveToActorGoal: " $ CurrentMoveToActorGoal);

	if (CurrentMoveToActorGoal != None)
	{
		// if the current move to actor goal was achieved, remove it so we can start a new one
		// if it wasn't achieved, we should let the current one take its course
		if (CurrentMoveToActorGoal.hasCompleted())
		{
			CurrentMoveToActorGoal.unPostGoal(self);
			CurrentMoveToActorGoal.Release();
			CurrentMoveToActorGoal = None;
		}
	}

	// move to the point
	if (CurrentMoveToActorGoal == None)
	{
		CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), MovementBehaviorPriority, Destination);
		assert(CurrentMoveToActorGoal != None);
		CurrentMoveToActorGoal.AddRef();

		CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);

		if (bZeroWalkThreshold)
			CurrentMoveToActorGoal.SetWalkThreshold(0.0);

		if (m_Pawn.logAI)
			log(m_Pawn.Name $ " going to move to: " $ Destination);

		CurrentMoveToActorGoal.postGoal(self);

		// we moved
		return true;
	}

	// we didn't move
	return false;
}

protected function MoveMinimumDistanceAwayFromLocation(vector Location, float MinimumDistance)
{
	local NavigationPoint ClosestPointToMoveTo;

	// don't find a new place to move to if we're already moving
	if (CanMoveToActor())
	{
		// find the navigation points a minimum distance from the location
		ClosestPointToMoveTo = SwatAIRepository(Level.AIRepo).GetClosestNavigationPointInRoom(m_Pawn.GetRoomName(), Location, MinimumDistance);

		if (ClosestPointToMoveTo != None)
			MoveToActor(ClosestPointToMoveTo, kMoveAwayFromLocationGoalPriority);
	}
}

// subclasses may override but should call down the chain
function NotifyDoorWedged(Door WedgedDoor)
{
	// update our knowledge about the door
	ISwatPawn(m_Pawn).SetDoorWedgedBelief(WedgedDoor, true);
}

function NotifyDoorLocked(Door LockedDoor)
{
	// update our knowledge about the door
	ISwatPawn(m_Pawn).SetDoorLockedBelief(LockedDoor, true);
}

function NotifyDoorBlocked(Door LockedDoor);

///////////////////////////////////////////////////////////////////////////////
//
// Engaging

// stub function
function FindBetterEnemy();

///////////////////////////////////////////////////////////////////////////////
//
// Debug

event SetDebugMoraleHistoryInfo()
{
    local int i;

    m_Pawn.AddDebugMessage(" ");

    for(i=0; i<GetMoraleHistoryCount(); ++i)
    {
        m_Pawn.AddDebugMessage(GetMoraleHistoryEntrySummary(i), class'Canvas'.Static.MakeColor(255,220,255));
    }

	m_Pawn.AddDebugMessage("Current Morale Value: " $ GetCurrentMorale(), class'Canvas'.Static.MakeColor(220,255,220));
}

event SetDebugBlackboardInfo()
{
    m_Pawn.AddDebugMessage("Name:               "@m_Pawn.Name);
    m_Pawn.AddDebugMessage("Morale:             "@GetCurrentMorale());
	m_Pawn.AddDebugMessage("Aggressive:         "@ISwatAI(m_Pawn).IsAggressive());
	m_Pawn.AddDebugMessage("Idle Category:      "@ISwatAI(m_Pawn).GetIdleCategory());

    // allow subclasses to add debug messages
    SetSpecificDebugInfo();
}

// override this function
function SetSpecificDebugInfo();

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal           = class'CommanderGoal'
	bListeningForCompliance = true
}
