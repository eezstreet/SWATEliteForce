///////////////////////////////////////////////////////////////////////////////
// RegroupAction.uc - RegroupAction class
// The Action that causes the AI to regroup around nearby Enemy AIs

class RegroupAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var config private float				MinRequiredRegroupDistanceFromOfficer;	// the minimum distance between us and the closest officer to be able to flee

var private AttackTargetGoal			CurrentAttackTargetGoal;
var private MoveToActorGoal				CurrentMoveToActorGoal;

var config private float				LowSkillAttackWhileRegroupingChance;
var config private float				MediumSkillAttackWhileRegroupingChance;
var config private float				HighSkillAttackWhileRegroupingChance;

var config private float				MinPassiveRegroupPercentageChance;
var config private float				MaxPassiveRegroupPercentageChance;
var config private float				MinAggressiveRegroupPercentageChance;
var config private float				MaxAggressiveRegroupPercentageChance;

var private DistanceToOfficersSensor	DistanceToOfficersSensor;
var private bool						bUseDistanceToOfficersSensor;

///////////////////////////////////////////////////////////////////////////////
//
// Init

function initAction(AI_Resource r, AI_Goal goal)
{
    super.initAction(r, goal);
    assert(m_Pawn != None);

	ISwatAI(m_Pawn).EnableFavorLowThreatPath();
	ISwatAICharacter(m_Pawn).ForceUpdateAwareness();

	if (!ISwatAI(m_Pawn).HasUsableWeapon())
	{
		ISwatEnemy(m_Pawn).GetEnemyCommanderAction().SetHasFledWithoutUsableWeapon();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

private function bool IsAnotherSwatEnemyAlive()
{
	local Pawn PawnIter;

	if (Level == None)
	{
		Level = m_Pawn.Level;
	}

	// find any swat enemy that isn't aware
	// this function is slow
    for (PawnIter = Level.pawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
    {
		if((PawnIter != m_Pawn) &&
		    class'Pawn'.static.checkConscious(PawnIter) && PawnIter.IsA('SwatEnemy') &&
			!ISwatAI(PawnIter).IsCompliant() &&
			!ISwatAI(PawnIter).IsArrested())
		{
			return true;
		}
	}

	// didn't find a single alive swat enemy
	return false;
}

private function bool IsWithinDistanceOfOfficers()
{
	local Hive HiveMind;

	HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();
	assert(HiveMind != None);
	assert(m_Pawn != None);

	return HiveMind.IsPawnWithinDistanceOfOfficers(m_Pawn, MinRequiredRegroupDistanceFromOfficer, true);
}

private function bool CanGetOutOfRoomSafely()
{
	local SwatAIRepository SwatAIRepo;
	local NavigationPointList DoorsInRoom;
	local Door DoorInRoom;
	local int i;
	local Hive HiveMind;

	HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);
	DoorsInRoom = SwatAIRepo.GetRoomNavigationPointsOfType(m_Pawn.GetRoomName(), 'SwatDoor');

	for(i=0; i<DoorsInRoom.GetSize(); ++i)
	{
		DoorInRoom = Door(DoorsInRoom.GetEntryAt(i));

		// if there is one door that we can use to get out of here, that isn't close too any player or officer, then we can get out safely
		if (! HiveMind.IsActorWithinDistanceOfOfficers(DoorInRoom, MinRequiredRegroupDistanceFromOfficer))
		{
//			log("there is no officer near " $ DoorInRoom $ ", so " $ m_Pawn.Name $ " can get away");
			return true;
		}
	}

//	log("there is no way " $ m_Pawn.Name $ " can get out of " $ m_Pawn.GetRoomName());
	return false;
}

function float selectionHeuristic( AI_Goal goal )
{
	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	if (IsAnotherSwatEnemyAlive())
	{
		if (! IsWithinDistanceOfOfficers())
		{
			if (CanGetOutOfRoomSafely())
			{
				// if we get chosen, we want to use the distance to officers sensor
				bUseDistanceToOfficersSensor = true;

				if (ISwatAI(m_Pawn).IsAggressive())
				{
					// return a random value that is at or below the maximum chance
					return FClamp(FRand(), MinAggressiveRegroupPercentageChance, MaxAggressiveRegroupPercentageChance);
				}
				else
				{
					// return a random value that is at least the minimum chance
					return FClamp(FRand(), MinPassiveRegroupPercentageChance, MaxPassiveRegroupPercentageChance);
				}
			}
		}
		else
		{
			// if we get chosen, we do not want to use the distance to officers sensor
			bUseDistanceToOfficersSensor = false;

			// return a low value but this behavior is still doable
			return FRand() * 0.1;
		}
	}

	return 0.0;
}

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (DistanceToOfficersSensor != None)
	{
		DistanceToOfficersSensor.deactivateSensor(self);
		DistanceToOfficersSensor = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Messages

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if (m_Pawn.logTyrion)
		log("RegroupAction received sensor message from " $ sensor.name $ " value is "$ value.integerData);

	// we only (currently) get messages from a distance sensor
	assert(sensor == DistanceToOfficersSensor);

	if (value.integerData == 1)
	{
		if (m_Pawn.logTyrion)
			log(m_Pawn.Name $ " is too close while " $ Name $ " running.  failing!");

		instantFail(ACT_TOO_CLOSE_TO_OFFICERS);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Attacking While Fleeing

function float GetSkillSpecificAttackChance()
{
	local EnemySkill CurrentEnemySkill;

	CurrentEnemySkill = ISwatEnemy(m_Pawn).GetEnemySkill();

	switch(CurrentEnemySkill)
	{
		case EnemySkill_Low:
            return LowSkillAttackWhileRegroupingChance;
        case EnemySkill_Medium:
            return MediumSkillAttackWhileRegroupingChance;
        case EnemySkill_High:
            return HighSkillAttackWhileRegroupingChance;
        default:
            assert(false);
            return 0.0;
	}
}

function bool ShouldAttackWhileRegrouping()
{
    local Pawn CurrentEnemy;

	assert(m_Pawn != None);

	if(!m_Pawn.IsA('SwatEnemy')) {
	    return false; // Sanity check - anything below this point might have unintended consequences
	}

    CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();
	if(CurrentEnemy == None)
	{
		return false;
	}

	if(CurrentEnemy.IsA('SniperPawn'))
	{
	    return false; // We should not be able to target SniperPawns
	}

	if(!m_Pawn.CanHit(CurrentEnemy))
	{
		return false; // Don't attack if we can't hit them
	}

	if(!ISwatAI(m_Pawn).HasUsableWeapon())
	{
	    return false; // Can't fire if we don't have a usable weapon
	}

	if(FRand() < GetSkillSpecificAttackChance())
	{
	    return false;
	}

    return true;
}

function AttackWhileRegrouping()
{
  local Pawn Enemy;

  Enemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();
  if(Enemy == None) {
    return;
  }

	CurrentAttackTargetGoal = new class'AttackTargetGoal'(weaponResource(), Enemy);
    assert(CurrentAttackTargetGoal != None);
	CurrentAttackTargetGoal.AddRef();

	CurrentAttackTargetGoal.postGoal(self);
}


///////////////////////////////////////////////////////////////////////////////
//
// Animation Swapping

function SwapInFullBodyFleeAnimations()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_RegroupAction);
		ISwatEnemy(m_Pawn).StartSprinting();
	}
}

function ResetFullBodyAnimations()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_RegroupAction);
		ISwatEnemy(m_Pawn).StopSprinting();
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function NavigationPoint FindRegroupDestination()
{
    local Pawn PawnIter;
    local SwatAIRepository SwatAIRepo;
	local name PawnRoomName, PawnIterRoomName;
	local NavigationPoint Destination;
	local array<NavigationPoint> PossibleDestinations;

    SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

	PawnRoomName = m_Pawn.GetRoomName();

	// find the closest Enemy not in our room
	// this function is slow
    for (PawnIter = Level.pawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
    {
		if ((PawnIter != m_Pawn) && PawnIter.IsA('SwatEnemy') && class'Pawn'.static.checkConscious(PawnIter) && !PawnIter.IsCompliant() && !PawnIter.IsArrested())
        {
			PawnIterRoomName = PawnIter.GetRoomName();

			if (PawnRoomName != PawnIterRoomName)
			{
				PossibleDestinations[PossibleDestinations.Length] = SwatAIRepo.FindRandomPointInRoom(PawnIterRoomName);
			}
        }
    }

	Destination = PossibleDestinations[Rand(PossibleDestinations.Length)];
    return Destination;
}

latent function Regroup()
{
    local NavigationPoint Destination;
	local Pawn CurrentEnemy;

    Destination = FindRegroupDestination();

    if (Destination != None)
    {
		CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

		// trigger the speech
		ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerFleeSpeech();

		if (CurrentEnemy != None)
		{
			// let the hive know so officers can "notice" it if they see us
			SwatAIRepository(Level.AIRepo).GetHive().NotifyEnemyFleeing(m_Pawn);
		}

		if (bUseDistanceToOfficersSensor)
		{
			// create a sensor so we fail if we get to close to the officers
			DistanceToOfficersSensor = DistanceToOfficersSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceToOfficersSensor', characterResource(), 0, 1000000 ));
			assert(DistanceToOfficersSensor != None);
			DistanceToOfficersSensor.SetParameters(MinRequiredRegroupDistanceFromOfficer, true);
		}

        CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, Destination);
        assert(CurrentMoveToActorGoal != None);
		CurrentMoveToActorGoal.AddRef();

		CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);

		// open doors frantically
		CurrentMoveToActorGoal.SetOpenDoorsFrantically(true);

		// close doors after ourselves
		CurrentMoveToActorGoal.SetShouldCloseOpenedDoors(true);

		// we want to use cover while moving
		CurrentMoveToActorGoal.SetUseCoveredPaths();

		// don't use the walk threshold (keep running)
		CurrentMoveToActorGoal.SetWalkThreshold(0.0);

        // post the move to goal and wait for it to complete
        CurrentMoveToActorGoal.postGoal(self);
		
		// trigger the speech
		ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerCallForHelpSpeech();

        WaitForGoal(CurrentMoveToActorGoal);
        CurrentMoveToActorGoal.unPostGoal(self);

		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
    }
}

function CallForHelp()
{
	local Pawn PawnIter;
	local Pawn CurrentEnemy;

	// trigger the speech
	ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerCallForHelpSpeech();

	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

	// make sure the enemy still is set
	if (CurrentEnemy != None)
	{
		// find any swat enemy that is conscious and in our room and let them know about our enemy!
		for (PawnIter = Level.pawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
		{
			if(class'Pawn'.static.checkConscious(PawnIter) && PawnIter.IsA('SwatEnemy') &&
				(ISwatEnemy(PawnIter).GetCurrentState() < EnemyState_Aware) && PawnIter.IsInRoom(m_Pawn.GetRoomName()))
			{
				// if that current enemy is still alive, go after them
				ISwatEnemy(PawnIter).GetEnemyCommanderAction().CreateBarricadeGoal(CurrentEnemy.Location, false, false);
			}
		}
	}
}

state Running
{
Begin:
	waitForResourcesAvailable(achievingGoal.priority, achievingGoal.priority);

	if (ShouldAttackWhileRegrouping())
	{
		AttackWhileRegrouping();
	}
	else
	{
		// if we're not attacking while fleeing, use the full body flee (movement) animations
		SwapInFullBodyFleeAnimations();
	}

	// move to the position
    Regroup();

    // let everyone know
	CallForHelp();

	// let the commander know to clean up after this particular behavior
	ISwatEnemy(m_Pawn).GetEnemyCommanderAction().FinishedMovingEngageBehavior();

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageOfficerGoal'
}
