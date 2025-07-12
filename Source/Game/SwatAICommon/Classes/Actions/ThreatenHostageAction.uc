///////////////////////////////////////////////////////////////////////////////
// ThreatenHostageAction.uc - ThreatenHostageAction class
// Action class that causes an Enemy to point his or her weapon at a nearby hostage

class ThreatenHostageAction extends SwatCharacterAction
	implements Engine.IInterestedPawnDied;
///////////////////////////////////////////////////////////////////////////////


var private Pawn						Hostage;
var private Pawn						Officer;

var private MoveToOpponentGoal			CurrentMoveToOpponentGoal;
var private AimAtTargetGoal				CurrentAimAtTargetGoal;
var private AttackTargetGoal			CurrentAttackTargetGoal;

var private config float				MinTimeToShootHostage;
var private config float				MaxTimeToShootHostage;

// the minimum distance between us and the closest officer to be able to threaten a hostage
var config private float				MinRequiredDistanceToOfficer;
var config private float				MinRequiredDistanceToHostage;
var config private float				MaxDistanceOfficerCanComeCloser;

var private config float				MinAgressiveThreatenHostageChance;
var private config float				MaxAgressiveThreatenHostageChance;

var private config float				MaxPassiveThreatenHostageChance;
var private config float				MinPassiveThreatenHostageChance;

var config name							ThreatenHostageTriggerEffectEvent;
var config array<name>					HostageResponseTriggerEffectEvents;

var config float						MinSleepTimeBetweenSpeech;
var config float						MaxSleepTimeBetweenSpeech;

var private DistanceToOfficersSensor	DistanceToOfficersSensor;

var private bool						bHurryUpAndKillHostage;
var private float						DistanceToHurryUp;

var private config float				RequiredHearingDistance;
const kWaitForOfficerAbleToHearUpdateTime = 0.25;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	// in case we weren't unregistered
	Level.UnRegisterNotifyPawnDied(self);

	if (CurrentMoveToOpponentGoal != None)
	{
		CurrentMoveToOpponentGoal.Release();
		CurrentMoveToOpponentGoal = None;
	}

	if (CurrentAimAtTargetGoal != None)
	{
		CurrentAimAtTargetGoal.Release();
		CurrentAimAtTargetGoal = None;
	}

	if (CurrentAttackTargetGoal != None)
	{
		CurrentAttackTargetGoal.Release();
		CurrentAttackTargetGoal = None;
	}

	if (DistanceToOfficersSensor != None)
	{
		DistanceToOfficersSensor.deactivateSensor(self);
		DistanceToOfficersSensor = None;
	}

	ISwatEnemy(m_Pawn).UnBecomeAThreat(true, 3.0);
}

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Messages

function OnSensorMessage( AI_Sensor sensor, AI_SensorData value, Object userData )
{
//	if (m_Pawn.logTyrion)
		log("ThreatenHostage received sensor message from " $ sensor.name $ " value is "$ value.integerData);

	// we only (currently) get messages from a distance sensor
	assert(sensor == DistanceToOfficersSensor);

	if (value.integerData == 1)
	{
//		if (m_Pawn.logTyrion)
			log(m_Pawn.Name $ " on sensor message - CurrentAimAtTargetGoal: " $ CurrentAimAtTargetGoal $ " time is: " $ m_Pawn.Level.TimeSeconds);

		// if we're aiming, stop sleeping that so we can start shooting the hostage
		if (CurrentAimAtTargetGoal != None)
		{
			bHurryUpAndKillHostage = true;
		}
		else
		{
			if (m_Pawn.logTyrion)
				log(m_Pawn.Name $ " is too close while " $ Name $ " running.  failing!");

			instantFail(ACT_TOO_CLOSE_TO_OFFICERS);
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// IInterestedPawnDied Messages

function OnOtherPawnDied(Pawn DeadPawn)
{
	// if the hostage died and we didn't do the killing, fail so we do something else
	if ((DeadPawn == Hostage) && (CurrentAttackTargetGoal == None))
		instantFail(ACT_GENERAL_FAILURE);
}

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic

private function bool CanThreatenHostage()
{
	local FiredWeapon CurrentWeapon;

	if(ISwatAICharacter(m_Pawn).IsPolite())
			return false;

	Officer = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();
	Hostage = None;

	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

	if(ISwatAICharacter(m_Pawn).IsInsane()) {
		// insane people don't think like normal people do ;)
		if(CurrentWeapon != None && Officer != None)
			Hostage = GetClosestUsableHostageInRoom(Officer);
	}
	else if ((CurrentWeapon != None) && (Officer != None) && HasLineOfSightToAPlayer() && !IsWithinDistanceOfOfficers())
	{
		Hostage = GetClosestUsableHostageInRoom(Officer);
	}

	return Hostage != None;
}

private function bool IsWithinDistanceOfOfficers()
{
	local Hive HiveMind;

	HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();
	assert(HiveMind != None);
	assert(m_Pawn != None);

	return HiveMind.IsPawnWithinDistanceOfOfficers(m_Pawn, MinRequiredDistanceToOfficer, true);
}

private function bool HasLineOfSightToAPlayer()
{
	local Pawn Player;
	local Controller Iter;

	if (Level.NetMode == NM_Standalone)
	{
		Player = Level.GetLocalPlayerController().Pawn;

		return Player.LineOfSightTo(m_Pawn);
	}
	else
	{
		// we should be a coop game (and be the server)
		assert(Level.IsCOOPServer);

		// go through the (alive) players on the server, and see who has a LOS
		for (Iter = Level.ControllerList; Iter != None; Iter = Iter.NextController)
		{
			if (Iter.IsA('PlayerController'))
			{
				Player = Iter.Pawn;

				if (class'Pawn'.static.checkConscious(Player) && Player.LineOfSightTo(m_Pawn))
				{
					return true;
				}
			}
		}
	}

	// no player has line of sight
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

	// make sure we have a level
	if (Level == None)
	{
		Level = m_Pawn.Level;
	}

	if (CanThreatenHostage())
	{
		if (ISwatAICharacter(m_Pawn).IsInsane()) {
			return 0.8;
		}
		else if (ISwatAI(m_Pawn).IsAggressive())
		{
			// return a random value that is at least the minimum chance
			return FClamp(FRand(), MinAgressiveThreatenHostageChance, MaxAgressiveThreatenHostageChance);
		}
		else
		{
			return FClamp(FRand(), MinPassiveThreatenHostageChance, MaxPassiveThreatenHostageChance);
		}
	}
	else
	{
		return 0.0;
	}
}

// if the Hostage is within a 200 degree angle between from us to the officer
function bool IsHostageInUsableLocation(Pawn Officer, Pawn Hostage)
{
	assert(m_Pawn != None);

	return (Normal(Officer.Location - m_Pawn.Location) Dot Normal(Hostage.Location - m_Pawn.Location) > -0.5);
}

// this function is slow!
function Pawn GetClosestUsableHostageInRoom(Pawn Officer)
{
	local Pawn PawnIter, ClosestHostage;
	local float IterDistance, ClosestDistance;

	for(PawnIter = m_Pawn.Level.PawnList; PawnIter != None; PawnIter = PawnIter.nextPawn)
	{
		// if PawnIter is in the same room, is alive, and is a swat hostage
		if (PawnIter.IsA('SwatHostage') &&
			class'Pawn'.static.checkConscious(PawnIter) &&
			m_Pawn.IsInRoom(PawnIter.GetRoomName()) &&
			IsHostageInUsableLocation(Officer, PawnIter))
		{
			IterDistance = VSize(PawnIter.Location - m_Pawn.Location);

			if (IterDistance < MinRequiredDistanceToHostage)
			{
				// find the closest or just any if we haven't found one yet
				if ((ClosestHostage == None) || (IterDistance < ClosestDistance))
				{
					ClosestHostage  = PawnIter;
					ClosestDistance = IterDistance;
				}
			}
		}
	}

	return ClosestHostage;
}

///////////////////////////////////////////////////////////////////////////////
//
// Tests

function bool CanAimAtHostage()
{
	local FiredWeapon CurrentWeapon;

	CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

	if(!CurrentWeapon.HitsTargetWithNoInterruptions(Hostage))
	{	// We can't aim at them because our trace failed
		return false;
	}

	return ((CurrentWeapon != None) && m_Pawn.CanHitTarget(Hostage) && ISwatAI(m_pawn).AnimCanAimAtDesiredActor(Hostage));
}


///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function CreateDistanceToOfficersSensor(Pawn Officer)
{
    local float DistanceToOfficer;
    if (class'Pawn'.static.checkConscious(Officer))
    {
        DistanceToOfficer = VSize(Officer.Location - m_Pawn.Location);

        if (DistanceToOfficer >= MaxDistanceOfficerCanComeCloser)
            DistanceToHurryUp = DistanceToOfficer - MaxDistanceOfficerCanComeCloser;
        else
            DistanceToHurryUp = DistanceToOfficer;

		if (m_Pawn.logAI)
			log("ThreatenHostageAction ("$m_Pawn.Name$") - DistanceToOfficer: " $ DistanceToOfficer $ " MaxDistanceOfficerCanComeCloser: " $ MaxDistanceOfficerCanComeCloser $ " DistanceToHurryUp: " $ DistanceToHurryUp);
    }
    else
    {
        DistanceToHurryUp = MaxDistanceOfficerCanComeCloser;
    }

    // create a sensor so we fail if we get to close to the officers
    DistanceToOfficersSensor = DistanceToOfficersSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceToOfficersSensor', characterResource(), 0, 1000000 ));
    assert(DistanceToOfficersSensor != None);
    DistanceToOfficersSensor.SetParameters(DistanceToHurryUp, true);
}

latent function MoveTowardsHostage()
{
	CurrentMoveToOpponentGoal = new class'MoveToOpponentGoal'(movementResource(), achievingGoal.Priority, Hostage);
    assert(CurrentMoveToOpponentGoal != None);
	CurrentMoveToOpponentGoal.AddRef();

	CurrentMoveToOpponentGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToOpponentGoal.SetStopWhenSuccessful(true);

    // post the move to goal and wait for it to complete
    CurrentMoveToOpponentGoal.postGoal(self);
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None))
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
	}
    WaitForGoal(CurrentMoveToOpponentGoal);
    CurrentMoveToOpponentGoal.unPostGoal(self);

	CurrentMoveToOpponentGoal.Release();
	CurrentMoveToOpponentGoal = None;
}

latent function AimAtHostage()
{
	CurrentAimAtTargetGoal = new class'AimAtTargetGoal'(weaponResource(), achievingGoal.priority, Hostage);
	assert(CurrentAimAtTargetGoal != None);
	CurrentAimAtTargetGoal.AddRef();

	// post the aim at target goal
	CurrentAimAtTargetGoal.postGoal(self);
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None))
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
	}
}

latent function ShootHostage()
{
    CurrentAttackTargetGoal = new class'AttackTargetGoal'(weaponResource(), Hostage);
    assert(CurrentAttackTargetGoal != None);
	CurrentAttackTargetGoal.AddRef();

    // post the move to goal
    waitForGoal(CurrentAttackTargetGoal.postGoal(self));
	if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat() && (m_Pawn.GetActiveItem() != None))
	{
		ISwatEnemy(m_Pawn).BecomeAThreat();
	}
    CurrentAttackTargetGoal.unPostGoal(self);

	CurrentAttackTargetGoal.Release();
	CurrentAttackTargetGoal = None;
}

latent function TriggerThreatenHostageSpeech(bool bCreateDistanceSensor)
{
	ISwatAI(m_Pawn).LatentAITriggerEffectEvent(ThreatenHostageTriggerEffectEvent,,,,,,true);

	if (bCreateDistanceSensor)
	{
		CreateDistanceToOfficersSensor(Officer);
	}

	if (! bHurryUpAndKillHostage)
	{
		sleep(RandRange(MinSleepTimeBetweenSpeech, MaxSleepTimeBetweenSpeech));
	}

	if (! bHurryUpAndKillHostage)
	{
		ISwatAI(Hostage).LatentAITriggerEffectEvent(HostageResponseTriggerEffectEvents[Rand(HostageResponseTriggerEffectEvents.Length)],,,,,,true);
	}
}

latent function WaitToKillHostage()
{
	local float EndTime, HalfEndTime, RandomTime;
	local Pawn CurrentEnemy;

	while (m_Pawn.Controller.GetDistanceToSound(Officer, m_Pawn.Location, Officer.Location) >= RequiredHearingDistance)
	{
		CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

		if ((CurrentEnemy != Officer) && class'Pawn'.static.checkConscious(CurrentEnemy))
			Officer = CurrentEnemy;

		// trigger the speech
		TriggerThreatenHostageSpeech(false);

		sleep(kWaitForOfficerAbleToHearUpdateTime);
	}

    if (! CanAimAtHostage())
        instantFail(ACT_GENERAL_FAILURE);

	// trigger the speech one more time
	TriggerThreatenHostageSpeech(true);

	RandomTime  = RandRange(MinTimeToShootHostage, MaxTimeToShootHostage);

	EndTime     = RandomTime + Level.TimeSeconds;
	HalfEndTime = (RandomTime / 2.0) + Level.TimeSeconds;

	while ((Level.TimeSeconds < HalfEndTime) && ! bHurryUpAndKillHostage)
	{
        if (! CanAimAtHostage())
            instantFail(ACT_GENERAL_FAILURE);

		yield();
	}

	if (! bHurryUpAndKillHostage)
	{
		// trigger the speech again
		TriggerThreatenHostageSpeech(false);

		while ((Level.TimeSeconds < EndTime) && ! bHurryUpAndKillHostage)
		{
            if (! CanAimAtHostage())
                instantFail(ACT_GENERAL_FAILURE);

			yield();
		}
	}
}

state Running
{
 Begin:
	// fail if the hostage is already unconscious
	if (! class'Pawn'.static.checkConscious(Hostage))
		instantFail(ACT_GENERAL_FAILURE);

	// register ourselves to get notified when any pawn dies
	Level.RegisterNotifyPawnDied(self);

	waitForResourcesAvailable(achievingGoal.priority, achievingGoal.priority);

	while (! CanAimAtHostage())
	{
		MoveTowardsHostage();
		yield();
	}

	useResources(class'AI_Resource'.const.RU_LEGS);

	AimAtHostage();

	if(!ISwatAICharacter(m_Pawn).IsInsane())
		WaitToKillHostage();

	// remove the aim goal, cause we're going to shoot the hostage.
	CurrentAimAtTargetGoal.unPostGoal(self);
	CurrentAimAtTargetGoal.Release();
	CurrentAimAtTargetGoal = None;

	// shoot the hostage
	while (class'Pawn'.static.checkConscious(Hostage))
	{
        if (! CanAimAtHostage())
            instantFail(ACT_GENERAL_FAILURE);

		ShootHostage();
	}

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageOfficerGoal'
}
