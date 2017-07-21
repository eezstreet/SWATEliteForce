///////////////////////////////////////////////////////////////////////////////
// RestrainAndReportAction.uc - StackUpAction class
// The Action that causes the Officers to restrain a compliant suspect or hostage

class RestrainAndReportAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Pawn					CompliantTarget;

// behaviors we use
var private MoveToActorGoal				CurrentMoveToActorGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private ReportGoal CurrentReportGoal;

// the cuffs
var private HandheldEquipment			Handcuffs;

// arrested sensor
var private ArrestedSensor				TargetArrestedSensor;

// config
var config float						DistanceFromTargetToRestrain;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	// if the handcuffs are in the middle fo being used, interrupt it
	if (Handcuffs != None)
	{
		if (Handcuffs.IsBeingUsed())
		{
			IAmAQualifiedUseEquipment(Handcuffs).InstantInterrupt();
		}

		Handcuffs.AIInterrupt();
	}

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if(CurrentReportGoal != None)
	{
		CurrentReportGoal.Release();
		CurrentReportGoal = None;
	}

	// deactivate the arrested sensor
	DeactivateArrestedSensor();

	// unlock our aim (if it hasn't been done already)
	ISwatAI(m_Pawn).UnlockAim();

	// re-enable collision avoidance (if it isn't already)
	m_Pawn.EnableCollisionAvoidance();

	// re-enable collision avoidance on our target (if it isn't already)
	if (class'Pawn'.static.checkConscious(CompliantTarget))
	{
		CompliantTarget.EnableCollisionAvoidance();
	}

	// make sure the fired weapon is re-equipped
	ISwatOfficer(m_Pawn).InstantReEquipFiredWeapon();
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensors

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if (m_Pawn.logTyrion)
		log(Name $ " received sensor message from " $ sensor.name $ " value is "$ value.objectData);

	assert(sensor == TargetArrestedSensor);

	// if the sensor sends us a message that the target has been arrested by someone else,
	// we can complete successfully
	if ((value.objectData == CompliantTarget) && (ISwatAI(CompliantTarget).GetArrester() != m_Pawn))
	{
		instantSucceed();
	}
}

private function ActivateArrestedSensor()
{
	TargetArrestedSensor = ArrestedSensor(class'AI_Sensor'.static.activateSensor( self, class'ArrestedSensor', characterResource(), 0, 1000000 ));
	TargetArrestedSensor.setParameters(CompliantTarget);
}

private function DeactivateArrestedSensor()
{
	if (TargetArrestedSensor != None)
	{
		TargetArrestedSensor.deactivateSensor(self);
		TargetArrestedSensor = None;
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

	if ((CurrentMoveToActorGoal != None) && (goal == CurrentMoveToActorGoal) && (errorCode == ACT_CANT_FIND_PATH))
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerCouldntCompleteMoveSpeech();
	}

	// just fail
	InstantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveIntoPosition()
{
	// disable collision avoidance on the target
	CompliantTarget.DisableCollisionAvoidance();

	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, CompliantTarget);
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToActorGoal.SetMoveToThreshold(CompliantTarget.CollisionRadius + DistanceFromTargetToRestrain);

	// post the goal and wait for it to complete
	CurrentMoveToActorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

latent function RotateTowardsTarget()
{
	local rotator RotationToTarget;

	RotationToTarget = rotator(CompliantTarget.Location - m_Pawn.Location);

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, RotationToTarget);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;

	// make sure we're using the correct rotation
	ISwatAI(m_Pawn).AimToRotation(RotationToTarget);
	ISwatAI(m_Pawn).LockAim();
}

latent function RestrainTarget()
{
	if (IAmUsedOnOther(Handcuffs).CanUseOnOtherNow(CompliantTarget))
	{
		Handcuffs.LatentWaitForIdleAndEquip();

		// use the handcuffs on the target
		if (IAmUsedOnOther(Handcuffs).CanUseOnOtherNow(CompliantTarget))
		{
			TriggerReassuranceSpeech();
			IAmUsedOnOther(Handcuffs).LatentUseOn(CompliantTarget);
		}

		// re-equip our best fired weapon
		ISwatOfficer(m_Pawn).ReEquipFiredWeapon();

		if (ISwatAI(CompliantTarget).IsArrested())
			TriggerFinishedArrestSpeech();
	}
}

latent function ReportTarget()
{
	local ISwatAI target;

	target = ISwatAI(CompliantTarget);
	if(target.CanBeUsedNow()) {
		CurrentReportGoal = new class 'ReportGoal'(characterResource(), target, m_Pawn.controller);
		assert(CurrentReportGoal != None);
		CurrentReportGoal.AddRef();

		CurrentReportGoal.postGoal(self);
		WaitForGoal(CurrentReportGoal);
		CurrentReportGoal.unPostGoal(self);

		CurrentReportGoal.Release();
		CurrentReportGoal = None;
	}
}

private function TriggerReassuranceSpeech()
{
	if (CompliantTarget.IsA('SwatHostage') || CompliantTarget.IsA('SwatUndercover'))
	{
		if (ISwatAI(CompliantTarget).IsAggressive())
		{
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReassureAggressiveHostageSpeech();
		}
		else
		{
			ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReassurePassiveHostageSpeech();
		}
	}
}

private function TriggerFinishedArrestSpeech()
{
	if (CompliantTarget.IsA('SwatEnemy') && !CompliantTarget.IsA('SwatUndercover'))
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerArrestedSuspectSpeech();
	}

	ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerArrestedReportSpeech(CompliantTarget);
}

function TriggerTargetRestrainedSpeech()
{
	if (CompliantTarget.IsA('SwatEnemy') && !CompliantTarget.IsA('SwatUndercover'))
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportedSuspectSecuredSpeech();
	}
	else
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerReportedHostageSecuredSpeech();
	}
}

state Running
{
Begin:
	if (resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
	{
		ActivateArrestedSensor();

		useResources(class'AI_Resource'.const.RU_ARMS);

		// let the officers know that the target exists
		SwatAIRepository(Level.AIRepo).GetHive().NotifyOfficersOfTarget(CompliantTarget);

		// equip the handcuffs
		Handcuffs = ISwatOfficer(m_Pawn).GetItemAtSlot(Slot_Cuffs);
		assert(Handcuffs != None);

		if (IAmUsedOnOther(Handcuffs).CanUseOnOtherNow(CompliantTarget))
		{
			MoveIntoPosition();

			// no avoiding collision while we're handcuffing!
			m_Pawn.DisableCollisionAvoidance();

			if (IAmUsedOnOther(Handcuffs).CanUseOnOtherNow(CompliantTarget))
			{
				RotateTowardsTarget();

				useResources(class'AI_Resource'.const.RU_LEGS);

				RestrainTarget();

				ReportTarget();

				//TriggerTargetRestrainedSpeech();

				// unlock our aim
				ISwatAI(m_Pawn).UnlockAim();
			}

			// re-enable collision avoidance on us and the target
			CompliantTarget.EnableCollisionAvoidance();
			m_Pawn.EnableCollisionAvoidance();
		}
	}

	succeed();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'RestrainAndReportGoal'
}
