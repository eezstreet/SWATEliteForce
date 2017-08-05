///////////////////////////////////////////////////////////////////////////////
// FleeAction.uc - FleeAction class
// The Action that causes the AI to flee

class FleeAction extends SwatCharacterAction
	dependsOn(ISwatEnemy);
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var config private float				MinRequiredFleeDistanceFromOfficer;	// the minimum distance between us and the closest officer to be able to flee

var protected AttackTargetGoal			CurrentAttackTargetGoal;
var protected MoveToActorGoal			CurrentMoveToActorGoal;

var private FleePoint					FleeDestination;

var config private float				LowSkillAttackWhileFleeingChance;
var config private float				MediumSkillAttackWhileFleeingChance;
var config private float				HighSkillAttackWhileFleeingChance;

var config private float				MinPassiveFleePercentageChance;
var config private float				MaxPassiveFleePercentageChance;
var config private float				MinAggressiveFleePercentageChance;
var config private float				MaxAggressiveFleePercentageChance;

var private DistanceToOfficersSensor	DistanceToOfficersSensor;
var private bool						bUseDistanceToOfficersSensor;

///////////////////////////////////////////////////////////////////////////////
//
// Init & cleanup

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

function cleanup()
{
    super.cleanup();

    ISwatAI(m_Pawn).DisableFavorLowThreatPath();

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

	ResetFullBodyAnimations();
}

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

private function bool IsWithinDistanceOfOfficers()
{
	local Hive HiveMind;

	HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();
	assert(HiveMind != None);
	assert(m_Pawn != None);

	return HiveMind.IsPawnWithinDistanceOfOfficers(m_Pawn, MinRequiredFleeDistanceFromOfficer, true);
}

// returns true if we find a flee destination
private function bool FindFleeDestination()
{
	FleeDestination = FindFleePointDestination();

	return (FleeDestination != None);
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

    if(ISwatPawn(m_Pawn).DoesBelieveDoorWedged(DoorInRoom)) {
      continue; // We can't use this door if we know it's wedged
    }
    if(ISwatPawn(m_Pawn).DoesBelieveDoorLocked(DoorInRoom)) {
      continue; // We can't use this door if we know it's locked
    }

		// if there is one door that we can use to get out of here, that isn't close too any player or officer, then we can get out safely
		if (! HiveMind.IsActorWithinDistanceOfOfficers(DoorInRoom, MinRequiredFleeDistanceFromOfficer))
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

	if (FindFleeDestination())
	{
		if (! IsWithinDistanceOfOfficers())
		{
//			log(m_Pawn $ " is NOT within the distance of the officers");

			if (CanGetOutOfRoomSafely())
			{
				// if we get chosen, we want to use the distance to officers sensor
				bUseDistanceToOfficersSensor = true;

				if (ISwatAI(m_Pawn).IsAggressive())
				{
					// return a random value that is at or below the maximum chance
					return FClamp(FRand(), MinAggressiveFleePercentageChance, MaxAggressiveFleePercentageChance);
				}
				else
				{
					// return a random value that is at least the minimum chance
					return FClamp(FRand(), MinPassiveFleePercentageChance, MaxPassiveFleePercentageChance);
				}
			}
		}
		else
		{
//			log(m_Pawn $ " is within the distance of the officers");

			// if we get chosen, we don't want to use the distance to officers sensor
			bUseDistanceToOfficersSensor = false;

			// return a low value but this behavior is still doable
			return FRand() * 0.1;
		}
	}

	return 0.0;
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Messages

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
	if (m_Pawn.logTyrion)
		log("FleeAction received sensor message from " $ sensor.name $ " value is "$ value.integerData);

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
            return LowSkillAttackWhileFleeingChance;
        case EnemySkill_Medium:
            return MediumSkillAttackWhileFleeingChance;
        case EnemySkill_High:
            return HighSkillAttackWhileFleeingChance;
        default:
            assert(false);
            return 0.0;
	}
}

function bool ShouldAttackWhileFleeing()
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

function AttackWhileFleeing()
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
		ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_FleeAction);
		ISwatEnemy(m_Pawn).StartSprinting();
	}
}

function ResetFullBodyAnimations()
{
	if (m_Pawn.IsA('SwatEnemy'))
	{
		ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_FleeAction);
		ISwatEnemy(m_Pawn).StopSprinting();
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function FleePoint FindFleePointDestination()
{
    local SwatAIRepository SwatAIRepo;
    local FleePoint Destination, Iter;
    local NavigationPointList AllFleePoints, ExcludesFleePoints;
    local int i;
	local Pawn CurrentEnemy, IterFleePointUser;

	local array<FleePoint> PossibleDestinations;

    SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

    // we exclude the flee points that are in the room we're in
    ExcludesFleePoints = SwatAIRepo.GetRoomNavigationPointsOfType(m_Pawn.GetRoomName(), 'FleePoint');
    AllFleePoints = SwatAIRepo.FindAllOfNavigationPointClass(class'FleePoint', ExcludesFleePoints);

	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

    // go through each point and find the closest
    for(i=0; i<AllFleePoints.GetSize(); ++i)
    {
        Iter = FleePoint(AllFleePoints.GetEntryAt(i));

//		log("Distance to ITer from Enemy is: " $ VSize2D(Iter.Location - CurrentEnemy.Location) $ " Required Distance is: " $ MinRequiredFleeDistanceFromOfficer);

        if ((CurrentEnemy == None) || !CurrentEnemy.IsInRoom(Iter.GetRoomName(CurrentEnemy)))
        {
			IterFleePointUser = Iter.GetFleePointUser();

			if ((IterFleePointUser == None) || (IterFleePointUser == m_Pawn))
			{
				PossibleDestinations[PossibleDestinations.Length] = Iter;
			}
        }
    }

	// all done with the excludes list
	SwatAIRepo.ReleaseNavigationPointList(ExcludesFleePoints);
	SwatAIRepo.ReleaseNavigationPointList(AllFleePoints);

	if (PossibleDestinations.Length > 0)
		Destination = PossibleDestinations[Rand(PossibleDestinations.Length)];

    return Destination;
}

latent function Flee()
{
	local Pawn CurrentEnemy;
	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

	// trigger the speech
	ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerFleeSpeech();

	if (CurrentEnemy != None)
	{
		// let the hive know so officers can "notice" it if they see us
		SwatAIRepository(Level.AIRepo).GetHive().NotifyEnemyFleeing(m_Pawn);

		if (bUseDistanceToOfficersSensor)
		{
			// create a sensor so we fail if we get to close to the officers
			DistanceToOfficersSensor = DistanceToOfficersSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceToOfficersSensor', characterResource(), 0, 1000000 ));
			assert(DistanceToOfficersSensor != None);
			DistanceToOfficersSensor.SetParameters(MinRequiredFleeDistanceFromOfficer, true);
		}
	}

	assert(FleeDestination != None);

    CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, FleeDestination);
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

    // remove the move to goal
    CurrentMoveToActorGoal.unPostGoal(self);
	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

state Running
{
Begin:
	waitForResourcesAvailable(achievingGoal.priority, achievingGoal.priority);

    if (ShouldAttackWhileFleeing())
	{
		AttackWhileFleeing();
	}
	else
	{
		// if we're not attacking while fleeing, use the full body flee (movement) animations
		SwapInFullBodyFleeAnimations();
	}

    Flee();

	// let the commander know to clean up after this particular behavior
	ISwatEnemy(m_Pawn).GetEnemyCommanderAction().FinishedMovingEngageBehavior();

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageOfficerGoal'
}
