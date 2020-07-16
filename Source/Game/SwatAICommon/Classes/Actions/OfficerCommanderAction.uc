///////////////////////////////////////////////////////////////////////////////
// OfficerCommanderAction.uc - the CommanderAction class
// the Officer Commander organizes the Officer AIs behaviors, and responds to stimuli

class OfficerCommanderAction extends CommanderAction
	native;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// Private internal
var private Hive						HiveMind;
var private Pawn						CurrentAssignment;
var private bool						bHasEngaged;

// Behaviors we use
var private EngageForComplianceGoal		CurrentEngageForComplianceGoal;
var private AttackEnemyGoal				CurrentAttackEnemyGoal;

var private IdleAimAroundGoal			CurrentIdleAimAroundGoal;
var private WatchNonHostileTargetGoal	CurrentWatchNonHostileTargetGoal;

var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

// Config
var config float						MinAimAtNoiseWhileMovingTime;
var config float						MaxAimAtNoiseWhileMovingTime;

var config float						MinFinishedEngagingTimeToAimAround;
var config float						MaxFinishedEngagingTimeToAimAround;

// Constants
const kRotateToFaceNoiseBehaviorPriority = 55;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	// set up watching non hostile targets
	SetupWatchingNonHostileTargets();

	// set up looking around when idle goal
	SetupIdleAimAroundGoal();
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentEngageForComplianceGoal != None)
	{
		CurrentEngageForComplianceGoal.Release();
		CurrentEngageForComplianceGoal = None;
	}

	if (CurrentAttackEnemyGoal != None)
	{
		CurrentAttackEnemyGoal.Release();
		CurrentAttackEnemyGoal = None;
	}

	if (CurrentWatchNonHostileTargetGoal != None)
	{
		CurrentWatchNonHostileTargetGoal.Release();
		CurrentWatchNonHostileTargetGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

	if (CurrentIdleAimAroundGoal != None)
	{
		CurrentIdleAimAroundGoal.Release();
		CurrentIdleAimAroundGoal = None;
	}
}

// remove any non death goals for when we die or become incapacitated
function RemoveNonDeathGoals()
{
	super.RemoveNonDeathGoals();

	if (CurrentIdleAimAroundGoal != None)
	{
		CurrentIdleAimAroundGoal.unPostGoal(self);
		CurrentIdleAimAroundGoal.Release();
		CurrentIdleAimAroundGoal = None;
	}

	if (CurrentEngageForComplianceGoal != None)
	{
		CurrentEngageForComplianceGoal.unPostGoal(self);
		CurrentEngageForComplianceGoal.Release();
		CurrentEngageForComplianceGoal = None;
	}

	if (CurrentAttackEnemyGoal != None)
	{
		CurrentAttackEnemyGoal.unPostGoal(self);
		CurrentAttackEnemyGoal.Release();
		CurrentAttackEnemyGoal = None;
	}

	if (CurrentWatchNonHostileTargetGoal != None)
	{
		CurrentWatchNonHostileTargetGoal.unPostGoal(self);
		CurrentWatchNonHostileTargetGoal.Release();
		CurrentWatchNonHostileTargetGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.unPostGoal(self);
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function Hive GetHive()
{
	if (HiveMind == None)
	{
		assert(m_Pawn != None);
		HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();
		assert(HiveMind != None);
	}

	return HiveMind;
}

native function Pawn GetCurrentAssignment();

///////////////////////////////////////////////////////////////////////////////
//
// Watching Non-Hostile Targets

private function SetupWatchingNonHostileTargets()
{
	CurrentWatchNonHostileTargetGoal = new class'WatchNonHostileTargetGoal'(characterResource());
	assert(CurrentWatchNonHostileTargetGoal != None);
	CurrentWatchNonHostileTargetGoal.AddRef();

	CurrentWatchNonHostileTargetGoal.postGoal(self);
}

///////////////////////////////////////////////////////////////////////////////
//
// Idle Aiming Around

private function SetupIdleAimAroundGoal()
{
	CurrentIdleAimAroundGoal = new class'IdleAimAroundGoal'(weaponResource());
	assert(CurrentIdleAimAroundGoal != None);
	CurrentIdleAimAroundGoal.AddRef();

	CurrentIdleAimAroundGoal.postGoal(self);
}

///////////////////////////////////////////////////////////////////////////////
//
// Vision Notifications

// we have seen an Enemy of ours.  Deal with it!
function OnPawnEncounteredVisionNotification()
{
	local Pawn Enemy;

	if (VisionSensor.LastPawnSeen != None)
	{
		Enemy = VisionSensor.LastPawnSeen;
	}
	else
	{
		assert(VisionSensor.LastPawnLost != none);

		Enemy = VisionSensor.LastPawnSeen;
	}

	GetHive().OfficerSawPawn(m_Pawn, Enemy);
}

function OnPawnLostVisionNotification()
{
	assert(VisionSensor.LastPawnLost != None);

	// just let the hive know
	GetHive().OfficerLostPawn(m_Pawn, VisionSensor.LastPawnLost, VisionSensor.GetWasLostRecently(m_Pawn, VisionSensor.LastPawnLost));
}

///////////////////////////////////////////////////////////////////////////////
//
// Hearing Notifications

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

	if (IsDeadlyNoise(SoundCategory))
	{
//		log(m_Pawn.Name $ " heard a DeadlyNoise - HeardActor: " $ HeardActor $ " Is a fired weapon: " $ HeardActor.IsA('FiredWeaponModel'));

		if (HeardActor.IsA('FiredWeaponModel'))
		{
//			log("HeardActor.Owner: " $ FiredWeaponModel(HeardActor).HandheldEquipment.Owner);

			HeardPawn = Pawn(FiredWeaponModel(HeardActor).HandheldEquipment.Owner);
		}
		else if (HeardActor.IsA('Ammunition'))
		{
			// the owner's owner of ammunition is a pawn
			HeardPawn = Pawn(HeardActor.Owner.Owner);
		}

		if ((HeardPawn != None) && ISwatAI(m_Pawn).IsOtherActorAThreat(HeardPawn))
		{
			ISwatAI(m_pawn).GetKnowledge().UpdateKnowledgeAboutPawn(HeardPawn);

			if (m_Pawn.LineOfSightTo(HeardPawn))
			{
				RotateToFaceNoise(HeardPawn);
			}
			else if ((HeardActor != HeardPawn) && m_Pawn.LineOfSightTo(HeardActor))
			{
				RotateToFaceNoise(HeardActor);
			}
		}
	}
	else if (SoundCategory == 'Footsteps')
	{
		if (!HeardPawn.IsA('SwatPlayer') && ! ISwatAI(HeardPawn).isCompliant() && ! ISwatAI(HeardPawn).isArrested() &&
		   (HeardPawn.IsA('SwatHostage') || HeardPawn.IsA('SwatEnemy')))
		{
			ISwatAI(m_pawn).GetKnowledge().UpdateKnowledgeAboutPawn(HeardPawn);

			if (m_Pawn.LineOfSightTo(HeardPawn))
				RotateToFaceNoise(HeardPawn);
		}
	}
	else if (SoundCategory == 'DoorInteraction')
	{
		LastDoorInteractor = ISwatDoor(HeardActor).GetLastInteractor();

		// if we heard a door, and we have a line of sight to
		if (LastDoorInteractor.IsA('SwatHostage') || LastDoorInteractor.IsA('SwatEnemy'))
		{
			if (HasLineOfSightToDoor(Door(HeardActor)))
			{
				RotateToFaceNoise(HeardActor);
			}
		}
	}
}

private function RotateToFaceNoise(Actor NoisyActor)
{
	assert(NoisyActor != None);

//	log(m_Pawn.Name $ " RotateToFaceNoise - NoisyActor: " $ NoisyActor $ " LineOfSightTo: " $ m_Pawn.LineOfSightTo(NoisyActor) $ " FastTrace: " $ m_Pawn.FastTrace(NoisyActor.Location));

	// just aim if we're moving, rotate if not
	if (VSize(m_Pawn.Velocity) > 0.0)
	{
		if ((CurrentAimAtTargetGoal == None) || CurrentAimAtTargetGoal.hasCompleted())
		{
			AimAtTarget(NoisyActor, kRotateToFaceNoiseBehaviorPriority, true, MinAimAtNoiseWhileMovingTime, MaxAimAtNoiseWhileMovingTime);
		}
	}
	else
	{
		// if we aren't rotating or have finished rotating, rotate to face the heard pawn
		if ((CurrentRotateTowardActorGoal == None) || CurrentRotateTowardActorGoal.hasCompleted())
		{
			RotateToFace(NoisyActor, kRotateToFaceNoiseBehaviorPriority);
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Doors

// if we find a blocked door that is blocked by the player, play some speech
function NotifyDoorBlocked(Door BlockedDoor)
{
	// don't do anything if we've been told to ignore door blocking
	if(ISwatOfficer(m_Pawn).GetIgnoreDoorBlocking())
	{
		return;
	}

	// we're supposed to call down the chain
	super.NotifyDoorBlocked(BlockedDoor);

	if (ISwatDoor(BlockedDoor).WasBlockedBy('SwatPlayer'))
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerPlayerBlockingDoorSpeech();
	}
	else if (ISwatDoor(BlockedDoor).WasBlockedBy('SwatAICharacter'))
	{
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerCharacterBlockingDoorSpeech();
	}
}

function NotifyBlockingDoorClose(Door BlockedDoor)
{
	// don't do anything if we've been told to ignore door blocking
	if(ISwatOfficer(m_Pawn).GetIgnoreDoorBlocking())
	{
		return;
	}

	// we're supposed to call down the chain
	super.NotifyDoorBlocked(BlockedDoor);
}

function NotifyBlockingDoorOpen(Door BlockedDoor)
{
	// don't do anything if we've been told to ignore door blocking
	if(ISwatOfficer(m_Pawn).GetIgnoreDoorBlocking())
	{
		return;
	}

	// we're supposed to call down the chain
	super.NotifyDoorBlocked(BlockedDoor);
}

///////////////////////////////////////////////////////////////////////////////
//
// Hive Interface

private function bool ShouldEngageTarget(Pawn Target)
{
	if (m_Pawn.logTyrion)
		log("ShouldEngageTarget - CurrentAssignment: " $ CurrentAssignment $ " Target: " $ Target $ " CurrentAttackEnemyGoal: " $CurrentAttackEnemyGoal);

	if (CurrentAssignment != Target)
	{
		// if we're not currently assigned to this target, take him down!
		return true;
	}
	else if (Target.IsA('SwatEnemy') && (CurrentAttackEnemyGoal == None) &&
		(ISwatEnemy(Target).IsAThreat() || ShouldAttackRunner(Target)))
	{
		// if the target is a threatening swat enemy, and we're not attacking them, we must act!
		return true;
	}

	return false;
}

function EngageTarget(Pawn Target)
{
	assert(Target != None);

	if (ShouldEngageTarget(Target))
	{
		if (m_Pawn.logAI)
			log(m_Pawn.Name $ " told to engage new target: " $ Target.Name $ " at time " $ Level.TimeSeconds);

		CurrentAssignment = Target;

		// clear out any existing Engage goals (attack, engage for compliance)
		ClearEngageGoals();

		stopWaiting();
		runAction();
	}
}

function ClearAssignment()
{
	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " assignment cleared");

	CurrentAssignment = None;
}

// WARNING: only self or the Hive should call this.  Ahh friend classes, how I could use thee...
function ClearEngageGoals()
{
	if (CurrentAttackEnemyGoal != None)
	{
		CurrentAttackEnemyGoal.unPostGoal(self);
		CurrentAttackEnemyGoal.Release();
		CurrentAttackEnemyGoal = None;
	}

	if (CurrentEngageForComplianceGoal != None)
	{
		CurrentEngageForComplianceGoal.unPostGoal(self);
		CurrentEngageForComplianceGoal.Release();
		CurrentEngageForComplianceGoal = None;
	}

	// start the engaging loop up again
	stopWaiting();
	runAction();
}

function FindBetterEnemy()
{
	if ((CurrentAttackEnemyGoal != None) && (AttackEnemyAction(CurrentAttackEnemyGoal.achievingAction) != None))
	{
		if (! AttackEnemyAction(CurrentAttackEnemyGoal.achievingAction).IsMovingToAttack())
		{
			GetHive().UpdateOfficerAssignments();
		}
	}
}

private latent function EngageTargetForCompliance(Pawn Target)
{
	assert(CurrentEngageForComplianceGoal == None);

	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " is going to engage " $ Target.Name $ " for compliance");

	if(GetHive().IsMovingTo(self.m_Pawn))
	{
		CurrentEngageForComplianceGoal = new class'EngageForComplianceWhileMovingToGoal'(characterResource(), Target, 
			GetHive().GetMoveToGoalForOfficer(self.m_Pawn).Destination,
			GetHive().GetMoveToGoalForOfficer(self.m_Pawn).CommandGiver);
	}
	else
	{
		CurrentEngageForComplianceGoal = new class'EngageForComplianceGoal'(characterResource(), Target);
	}
	
	assert(CurrentEngageForComplianceGoal != None);
	CurrentEngageForComplianceGoal.AddRef();

	CurrentEngageForComplianceGoal.postGoal(self);
	WaitForGoal(CurrentEngageForComplianceGoal);
}

private latent function AttackTarget(Pawn Target)
{
	local AttackTargetGoal AttackGoal;

	assert(CurrentAttackEnemyGoal == None);

	if (m_Pawn.logAI)
		log(m_Pawn.Name $ " is going to attack " $ Target.Name);

	// If we're just moving to the destination, just attack.
	if(GetHive().IsMovingTo(self.m_Pawn) || GetHive().IsFallingIn(self.m_Pawn))
	{
		log("SwatOfficer: "$self.m_Pawn$" should now be attacking "$Target.name);
		AttackGoal = new class'AttackTargetGoal'(weaponResource(), Target);
		assert(AttackGoal != None);
		AttackGoal.AddRef();
		AttackGoal.postGoal(self);
		WaitForGoal(AttackGoal);
		log("SwatOfficer: "$self.m_Pawn$" has finished attacking "$Target.name);

		AttackGoal.unPostGoal(self);
		AttackGoal.Release();
		AttackGoal = None;
	}
	else
	{	// Otherwise, attack. Optionally while falling in.
		CurrentAttackEnemyGoal = new class'AttackEnemyGoal'(characterResource());
		assert(CurrentAttackEnemyGoal != None);
		CurrentAttackEnemyGoal.AddRef();

		CurrentAttackEnemyGoal.postGoal(self);
		WaitForGoal(CurrentAttackEnemyGoal);
	}
	
}

private function bool ShouldAttackRunner(Pawn target)
{
	return (target.IsA('SwatFlusher') || target.IsA('SwatEscaper')) &&
	  (ISwatOfficer(m_Pawn).GetPrimaryWeapon().IsLessLethal() || (ISwatOfficer(m_Pawn).GetBackupWeapon() != None && ISwatOfficer(m_Pawn).GetBackupWeapon().IsLessLethal()));
}

private function bool ShouldAttackUsingLessLethal(Pawn target)
{
	local FiredWeapon Item;

	if(ISwatAI(target).IsCompliant() || ISwatAI(target).IsArrested() || target.IsA('SwatUndercover'))
	{
		return false; // Don't target compliant or arrested people. And leave Carl Jennings alone!
	}

	Item = FiredWeapon(m_Pawn.GetActiveItem());

	if(Item == None || !Item.IsLessLethal() || Item.IsA('Taser')      || // Don't tase people, it can kill
		(Item.IsA('CSBallLauncher') && ISwatAI(target).IsGassed())    || // Pepperball is uselss on already gassed people
		(Item.IsA('BeanbagShotgunBase') && ISwatAI(target).IsStung()) || // Don't keep spamming beanbags at people.
		(Item.IsA('GrenadeLauncherBase')))                            	 // Don't use the grenade launcher. It's stupid.
	{
		return false;
	}

	if(GetHive().IsMovingTo(self.m_Pawn) || GetHive().IsFallingIn(self.m_Pawn))
	{	// The AI is trained to attack on the move in this state; we don't want them to walk up to people and start beaning them.
		return true;
	}

	return false;
}

private latent function EngageAssignment()
{
	local bool bCompletedEngagementGoals;

	// we should have an assignment here
	assert (CurrentAssignment != None);

	log("EngageAssignment() for "$self.m_Pawn.name);
	if(CurrentAssignment.IsA('SwatPlayer') || ShouldAttackRunner(CurrentAssignment) ||
		(CurrentAssignment.IsA('SwatEnemy') && ISwatEnemy(CurrentAssignment).IsAThreat()) ||	// Current assignment is a threat
		(CurrentAssignment.IsA('SwatEnemy') && !ISwatEnemy(CurrentAssignment).IsAThreat() && ShouldAttackUsingLessLethal(CurrentAssignment))	// Not a threat but we can use less lethal to subdue them
		)
	{
		log(""$self.m_Pawn.name$" should attack assignment "$CurrentAssignment.name$", so let's do that now!");
		AttackTarget(CurrentAssignment);

		if (CurrentAttackEnemyGoal != None)
		{
			bCompletedEngagementGoals = CurrentAttackEnemyGoal.hasCompleted();

			CurrentAttackEnemyGoal.unPostGoal(self);
			CurrentAttackEnemyGoal.Release();
			CurrentAttackEnemyGoal = None;
		}
	}
	else
	{
		EngageTargetForCompliance(CurrentAssignment);

		if (CurrentEngageForComplianceGoal != None)
		{
			bCompletedEngagementGoals = CurrentEngageForComplianceGoal.hasCompleted();

			CurrentEngageForComplianceGoal.unPostGoal(self);
			CurrentEngageForComplianceGoal.Release();
			CurrentEngageForComplianceGoal = None;
		}
	}

//	log(m_Pawn.Name $ " finished any enaging goal in engage assignment - bAchievedEngagementGoals: " $ bAchievedEngagementGoals $ " CurrentAssignment.IsConscious " $ class'Pawn'.static.checkConscious(CurrentAssignment));

	if (bCompletedEngagementGoals || !class'Pawn'.static.checkConscious(CurrentAssignment))
	{
		if (m_Pawn.logAI)
			log(m_Pawn.Name $ " calling finished assignment at time " $ Level.TimeSeconds);

		// let the Hive know we're all done
		CurrentAssignment = None;
		GetHive().FinishedAssignment();
	}
}

state Running
{
 Begin:
	// wait until we're told to run
	if (CurrentAssignment == None)
	{
		if (bHasEngaged)
		{
			sleep(RandRange(MinFinishedEngagingTimeToAimAround, MaxFinishedEngagingTimeToAimAround));

			if ((CurrentAssignment == None) && (CurrentWatchNonHostileTargetGoal.achievingAction == None) && (CurrentIdleAimAroundGoal.achievingAction != None))
			{
				CurrentIdleAimAroundGoal.achievingAction.instantFail(ACT_GENERAL_FAILURE);
			}
		}

		// CurrentAssignment could have changed while were sleeping above, so we check it again before pausing
		if (CurrentAssignment == None)
			pause();
	}

	// it is possible for our assignment to be cleared between the time we are paused,
	// when runAction is called, and when we actually continue executing state code
	// so in that case we should check again to make sure our assignment hasn't been cleared
	if (CurrentAssignment != None)
	{
		bHasEngaged = true;

		EngageAssignment();
	}

	yield();
	goto('Begin');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}
