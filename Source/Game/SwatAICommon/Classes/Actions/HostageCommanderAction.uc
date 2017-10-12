///////////////////////////////////////////////////////////////////////////////
// HostageCommanderAction.uc - the CommanderAction class
// the Hostage commander organizes the Hostage AIs behaviors, and responds to stimuli

class HostageCommanderAction extends CommanderAction
	native;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private CowerGoal						CurrentCowerGoal;

var private Pawn							Rescuer;
var private HostageReactionToOfficersGoal	CurrentHostageReactionToOfficersGoal;

var private bool							bWasInDanger;

var config float							DangerUpdateTime;
var config float							RescuerUpdateTime;

var config float							FlashbangedMoraleModification;
var config float							GassedMoraleModification;
var config float							PepperSprayedMoraleModification;
var config float							StungMoraleModification;
var config float							TasedMoraleModification;
var config float							StunnedByC2MoraleModification;
var config float							ShotMoraleModification;

var config float							ReactToThrownGrenadeChance;
var config float							ScreamChance;

var config float							PassiveCrouchWhenHearsDeadlyNoiseChance;
var config float							AggressiveCrouchWhenHearsDeadlyNoiseChance;
var private bool							bHasHeardFirstDeadlyNoise;

var private float							NextTimeToPlayInDangerSpeech;
var config float							MinDeltaTimeToPlayInDangerSpeech;
var config float							MaxDeltaTimeToPlayInDangerSpeech;

const kRunFromGunshotPriority = 86;			// barely higher than the cower goal

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	// hostages use the comply sensor
	ActivateComplySensor();

	// hostages have morale
	InitializeMorale();
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentCowerGoal != None)
	{
		CurrentCowerGoal.Release();
		CurrentCowerGoal = None;
	}

	if (CurrentHostageReactionToOfficersGoal != None)
	{
		CurrentHostageReactionToOfficersGoal.Release();
		CurrentHostageReactionToOfficersGoal = None;
	}
}

// remove any non death goals for when we die or become incapacitated
function RemoveNonDeathGoals()
{
	super.RemoveNonDeathGoals();

	// remove the cower goal
	if (CurrentCowerGoal != None)
	{
		CurrentCowerGoal.unPostGoal(self);
		CurrentCowerGoal.Release();
		CurrentCowerGoal = None;
	}

	// remove the hostage reaction to officers goal
	if (CurrentHostageReactionToOfficersGoal != None)
	{
		CurrentHostageReactionToOfficersGoal.unPostGoal(self);
		CurrentHostageReactionToOfficersGoal.Release();
		CurrentHostageReactionToOfficersGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (goal == CurrentCowerGoal)
	{
		CurrentCowerGoal.unPostGoal(self);
		CurrentCowerGoal.Release();
		CurrentCowerGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Senses

// overridden completely from normal implementation found in CommanderAction so Hostages can use hearing when compliant or restrained
protected function DisableSensingSystems()
{
	// we don't need awareness
	ISwatAI(m_Pawn).DisableAwareness();

	// disable vision permanently
	ISwatAI(m_Pawn).DisableVision(true);
}

///////////////////////////////////////////////////////////////////////////////
//
// Vision Notifications

function OnPawnEncounteredVisionNotification()
{
	local Pawn SeenPawn;

	SeenPawn = VisionSensor.LastPawnSeen;
	assert(SeenPawn != None);

	// we don't react to seeing enemies (for now), only officers
	// we do see them so it affects awareness though
	if (SeenPawn.IsA('SwatOfficer') || SeenPawn.IsA('SwatPlayer'))
	{
		if (Rescuer == None)
		{
			Rescuer = SeenPawn;

			// we only can run if we're not already running
			// the reason for this is because we could be cowering, but then become rescued
			if (! isRunning())
			{
				runAction();
			}
		}
	}
}

function OnPawnLostVisionNotification()
{
	// nothing yet.
}

///////////////////////////////////////////////////////////////////////////////
//
// Damage

//
function float GetShotMoraleModification()
{
	return ShotMoraleModification;
}

function NotifyNearbyHostageDowned(Pawn NearbyHostage)
{
	assert(NearbyHostage != None);

	ISwatHostage(m_Pawn).GetHostageSpeechManagerAction().TriggerDownedHostageSpeech();
}

///////////////////////////////////////////////////////////////////////////////
//
// Doors

// if we find a blocked door that is blocked by a player or officer, stop patrolling!
function NotifyDoorBlocked(Door BlockedDoor)
{
	// we're supposed to call down the chain
	super.NotifyDoorBlocked(BlockedDoor);

	if (ISwatDoor(BlockedDoor).WasBlockedBy('SwatOfficer') ||
		ISwatDoor(BlockedDoor).WasBlockedBy('SwatPlayer'))
	{
		// do some speech
		ISwatHostage(m_Pawn).GetHostageSpeechManagerAction().TriggerDoorBlockedSpeech();

		if (CurrentPatrolGoal != None)
		{
			CurrentPatrolGoal.unPostGoal(self);
			CurrentPatrolGoal.Release();
			CurrentPatrolGoal = None;
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Morale functions

function float GetFlashbangedMoraleModification()			{ return FlashbangedMoraleModification; }
function float GetGassedMoraleModification()				{ return GassedMoraleModification; }
function float GetPepperSprayedMoraleModification()			{ return PepperSprayedMoraleModification; }
function float GetStungMoraleModification()					{ return StungMoraleModification; }
function float GetTasedMoraleModification()					{ return TasedMoraleModification; }
function float GetStunnedByC2DetonationMoraleModification()	{ return StunnedByC2MoraleModification; }


function PostComplianceCheck(Pawn ComplianceIssuer, bool bWillComply)
{
	if (! bWillComply)
	{
		// we want them standing up
		if (m_Pawn.bIsCrouched)
		{
			m_Pawn.ShouldCrouch(false);
		}

		ISwatAI(m_Pawn).SetIdleCategory('NonCompliant');

		ISwatHostage(m_Pawn).GetHostageSpeechManagerAction().TriggerUncompliantSpeech();
	}
}

protected function NotifyBecameCompliant()
{
	Super.NotifyBecameCompliant();

	if (CurrentHostageReactionToOfficersGoal != None)
	{
		CurrentHostageReactionToOfficersGoal.unPostGoal(self);
		CurrentHostageReactionToOfficersGoal.Release();
		CurrentHostageReactionToOfficersGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Noise Notifications

function OnHeardNoise()
{
	local Actor HeardActor;
	local Pawn HeardPawn;
	local Pawn LastDoorInteractor;
	local name SoundCategory;
	local vector SoundOrigin;

	HeardActor    = HearingSensor.LastSoundMaker;
	HeardPawn	  = Pawn(HeardActor);
	SoundCategory = HearingSensor.LastSoundHeardCategory;
	SoundOrigin   = HearingSensor.LastSoundHeardOrigin;

	log("HeardActor: " $ HeardActor $ " HeardActor.Location: " $ HeardActor.Location $ " distance to heard actor: " $ VSize(HeardActor.Location - m_Pawn.Location) $ " line of sight to heard actor: " $ m_Pawn.LineOfSightTo(HeardActor));

	if (IsDeadlyNoise(SoundCategory))
	{
		OnHeardDeadlyNoise();

		if (HeardActor.IsA('FiredWeaponModel'))
		{
			HeardPawn = Pawn(FiredWeaponModel(HeardActor).HandheldEquipment.Owner);
			assert(HeardPawn != None);

			RotateToFaceNoise(HeardPawn);
		}
		else if (HeardActor.IsA('Ammunition') && (VSize(HeardActor.Location - m_Pawn.Location) < MinReactToGunshotDistance) && m_Pawn.LineOfSightTo(HeardActor))
		{
			ReactToNearbyGunshot(HeardActor);
		}
	}
	else if ((SoundCategory == 'Footsteps') && (Rescuer == None) && ! IsInDanger())
	{
		RotateToFaceNoise(HeardPawn);
	}
	else if ((SoundCategory == 'DoorInteraction') && (Rescuer == None) && ! IsInDanger())
	{
		LastDoorInteractor = ISwatDoor(HeardActor).GetLastInteractor();

		if (LastDoorInteractor.IsA('SwatPlayer') || LastDoorInteractor.IsA('SwatOfficer'))
		{
			if (HasLineOfSightToDoor(Door(HeardActor)))
				RotateToFace(LastDoorInteractor, 50);
		}
	}
}

private function ReactToNearbyGunshot(Actor HeardActor)
{
	local NavigationPoint RunAwayDestination;

	if (m_Pawn.IsCompliant() || m_Pawn.IsArrested())
	{
		PlayFlinch();
	}
	else
	{
		RunAwayDestination = ISwatAI(m_Pawn).FindRunToPoint(HeardActor.Location, MinReactToGunshotDistance);

		if (RunAwayDestination != None)
		{
			if (MoveToActor(RunAwayDestination, kRunFromGunshotPriority, true))
			{
				// scream!
				ISwatHostage(m_Pawn).GetHostageSpeechManagerAction().TriggerFleeSpeech();
				Scream();
			}
		}
		else
		{
			PlayFlinch();
		}
	}
}

protected function bool ShouldScream()
{
	return (FRand() < ScreamChance);
}

private function float GetHeardDeadlyNoiseCrouchChance()
{
	if (ISwatAI(m_Pawn).IsAggressive())
	{
		return AggressiveCrouchWhenHearsDeadlyNoiseChance;
	}
	else
	{
		return PassiveCrouchWhenHearsDeadlyNoiseChance;
	}
}

private function OnHeardDeadlyNoise()
{
	if (! bHasHeardFirstDeadlyNoise)
	{
		bHasHeardFirstDeadlyNoise = true;

		if (FRand() < GetHeardDeadlyNoiseCrouchChance())
		{
			m_Pawn.ShouldCrouch(true);
		}

		if (IsIdle())
			runAction();
	}
}

private function RotateToFaceNoise(Pawn HeardPawn)
{
	// if we aren't rotating or have finished rotating, rotate to face the heard pawn
	if (m_Pawn.LineOfSightTo(HeardPawn) && ((CurrentRotateTowardRotationGoal == None) || CurrentRotateTowardRotationGoal.hasCompleted()))
	{
		if (HeardPawn.IsA('SwatPlayer') || HeardPawn.IsA('SwatOfficer'))
		{
			RotateToRotation(rotator(HeardPawn.Location - m_Pawn.Location), 50);
		}
	}
}

protected function bool WillReactToGrenadeBeingThrown()
{
	return (FRand() < ReactToThrownGrenadeChance);
}

///////////////////////////////////////////////////////////////////////////////
//
// Threat Notifications

function OnThreatened()
{
	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " is threatened");

	// we're going to cower!
	if (isIdle())
	{
		runAction();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Queries
// returns true if we are currently threatened, if we can see an enemy, or there is an enemy in the same room as us
function bool IsInDanger()
{
	local Pawn VisibleEnemy;

	assert(m_Pawn != None);
	assert(ThreatenedSensorAction(ThreatenedSensor.sensorAction) != None);

	if (ThreatenedSensorAction(ThreatenedSensor.sensorAction).IsThreatened())
	{
		return true;
	}
	else if(!ISwatAICharacter(m_Pawn).IsFearless())
	{
		VisibleEnemy = VisionSensor.GetVisibleConsciousPawnClosestTo(m_Pawn.Location, 'SwatEnemy');

		if ((VisibleEnemy != None) && ! ISwatAI(VisibleEnemy).IsCompliant() && ! ISwatAI(VisibleEnemy).IsArrested())
		{
			return true;
		}

		return SwatAIRepository(m_Pawn.Level.AIRepo).DoesRoomContainAIs(m_Pawn.GetRoomName(), 'SwatEnemy', true);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function Cower()
{
	assert(CurrentCowerGoal == None);

	CurrentCowerGoal = new class'CowerGoal'(characterResource());
	assert(CurrentCowerGoal != None);
	CurrentCowerGoal.AddRef();

	CurrentCowerGoal.postGoal(self);
}

latent function ReactToRescuer()
{
	CurrentHostageReactionToOfficersGoal = new class'HostageReactionToOfficersGoal'(characterResource(), Rescuer, bWasInDanger);
	assert(CurrentHostageReactionToOfficersGoal != None);
	CurrentHostageReactionToOfficersGoal.AddRef();

	CurrentHostageReactionToOfficersGoal.postGoal(self);
	WaitForGoal(CurrentHostageReactionToOfficersGoal);

	// the CurrentHostageReactionToOfficersGoal may have been removed already if we became compliant
	if (CurrentHostageReactionToOfficersGoal != None)
	{
		CurrentHostageReactionToOfficersGoal.unPostGoal(self);
		CurrentHostageReactionToOfficersGoal.Release();
		CurrentHostageReactionToOfficersGoal = None;
	}
}

state Running
{
 Begin:
	pause();

	if (! m_Pawn.IsCompliant() && ! m_Pawn.IsArrested())
	{
		// unset our idle category
		ISwatAI(m_Pawn).SetIdleCategory('');

		if (ThreatenedSensor.threatenedBy != None)		// if we're currently being threatened
		{
			bWasInDanger = true;

			Cower();
		}

		// if we're still in danger, don't do anything
		while (IsInDanger())
		{
//			log(m_Pawn.Name $ " is in danger");

			bWasInDanger = true;

			// wait a bit in-between in danger speech
//			log("NextTimeToPlayInDangerSpeech: " $ NextTimeToPlayInDangerSpeech $ " Level.TimeSeconds: " $ Level.TimeSeconds);
			if (Level.TimeSeconds > NextTimeToPlayInDangerSpeech)
			{
				ISwatHostage(m_Pawn).GetHostageSpeechManagerAction().TriggerInDangerSpeech();

				NextTimeToPlayInDangerSpeech = Level.TimeSeconds + RandRange(MinDeltaTimeToPlayInDangerSpeech, MaxDeltaTimeToPlayInDangerSpeech);
			}

			sleep(DangerUpdateTime);
		}

		if (CurrentCowerGoal != None)
		{
			CurrentCowerGoal.unPostGoal(self);
			CurrentCowerGoal.Release();
			CurrentCowerGoal = None;
		}

		// if our situation changes
		if (Rescuer != None)
		{
			while (! m_Pawn.LineOfSightTo(Rescuer))
			{
				sleep(RescuerUpdateTime);
			}

			ReactToRescuer();
		}
	}

	yield();
	goto('Begin');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
