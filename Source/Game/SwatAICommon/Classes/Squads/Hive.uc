///////////////////////////////////////////////////////////////////////////////
// Hive.uc - the Hive class
// The Hive is used to organize functionality between the officers

class Hive extends Core.Object
	native
	config(AI);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private HiveBlackboard		Blackboard;
var			SwatAIRepository	SwatAIRepo;

var private array<Pawn>         HiveAwarenessPawns;
var private AwarenessProxy		HiveAwareness;
var private float               AwarenessCounter;
var private bool                bAwarenessDisabled;

var array<CachedEngageInfo>		CachedEngagements;

var config float				PlayerDamageThreshold;		// the threshold of damage that we will take from the player
var private float				CurrentPlayerDamage;		// how much damage we have taken
var private bool				bTriggeredFirstShotReaction;
var private bool				bTriggeredSecondShotReaction;
var private bool				bTriggeredThirdShotReaction;

var private array<Pawn>			ThreateningUncompliantAssignments;
var private array<Pawn>			NonThreateningUncompliantAssignments;

// maximum distance that we will watch targets
var config float				MaxWatchTargetDistance;

const kMinAwarenessUpdateTime = 0.333;
const kMaxAwarenessUpdateTime = 0.666;

// time, in seconds, before we update the cached NavigationPoints in a room that can hit a particular opponent
const kRequestEngagePointStaleDelta = 2.0;

struct native WeightedAssignment
{
	var float	Weight;
	var Pawn	Officer;
	var Pawn	Assignment;
};


///////////////////////////////////////////////////////////////////////////////
//
// Constructor

overloaded function construct()
{
    Blackboard = new(None) class'HiveBlackboard';
    assert(Blackboard != None);
}

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

native function int GetNumOfficers();
native function Pawn GetOfficer(int Index);

function Pawn GetClosestOfficerTo(Actor Target, optional bool bRequiresLineOfSight)
{
	assert(Target != None);

	return SwatAIRepo.GetElementSquad().GetClosestOfficerTo(Target, bRequiresLineOfSight);
}

function Pawn GetClosestOfficerThatCanHit(Actor Target)
{
	assert(Target != None);

	return SwatAIRepo.GetElementSquad().GetClosestOfficerThatCanHit(Target);
}

///////////////////////////////////////////////////////////////////////////////
//
// Hive Awareness

function AwarenessProxy GetAwareness()
{
    return HiveAwareness;
}

function DisableAwareness()
{
    bAwarenessDisabled = true;
}

function EnableAwareness()
{
    bAwarenessDisabled = false;
}

function AddOfficerToHiveAwareness(Pawn Officer)
{
    HiveAwarenessPawns[HiveAwarenessPawns.length] = Officer;

    // If the awareness object has not yet been created, and all officers in
    // the element squad have been constructed, create the awareness object
    // for those pawns.
    if (HiveAwareness == None && (HiveAwarenessPawns.length == SwatAIRepo.Level.Game.GetNumSpawnedOfficers()))
    {
        HiveAwareness = class'SwatAIAwareness.AwarenessFactory'.static.CreateAwarenessForMultiplePawns(HiveAwarenessPawns);
    }
}

function RemoveOfficerFromHiveAwareness(Pawn Officer)
{
    local int i;
    for (i = 0; i < HiveAwarenessPawns.length; i++)
    {
        if (HiveAwarenessPawns[i] == Officer)
        {
            HiveAwarenessPawns.Remove(i, 1);
        }
    }

    if (HiveAwarenessPawns.length == 0)
    {
        HiveAwareness.Term();
        HiveAwareness = None;
    }
}

///////////////////////////////////////////////////////////////////////////////
//
// Notifications

private function CheckUpdateOfficerAssignmentsForEnemy(Pawn Enemy)
{
	local int i;

	assert(Enemy != None);
	assert(Enemy.IsA('SwatEnemy'));

	for(i=0; i<Blackboard.EncounteredEnemies.Length; ++i)
	{
		// if we have encountered this enemy, update officer assignments so that we deal with him
		if (Blackboard.EncounteredEnemies[i] == Enemy)
		{
			UpdateOfficerAssignments();
			break;
		}
	}
}

private function CheckUpdateOfficerAssignmentsForHostage(Pawn Hostage)
{
	local int i;

	assert(Hostage != None);
	assert(Hostage.IsA('SwatHostage'));

	for(i=0; i<Blackboard.EncounteredHostages.Length; ++i)
	{
		// if we have encountered this hostage, update officer assignments so that we deal with him
		if (Blackboard.EncounteredHostages[i] == Hostage)
		{
			UpdateOfficerAssignments();
			break;
		}
	}
}

// notification that an enemy has become a threat
function NotifyEnemyBecameThreat(Pawn Enemy)
{
	CheckUpdateOfficerAssignmentsForEnemy(Enemy);
}

// notification that an enemy is stunned
function NotifyEnemyStunned(Pawn Enemy)
{
	CheckUpdateOfficerAssignmentsForEnemy(Enemy);
}

// notification that a hostage is stunned
function NotifyHostageStunned(Pawn Hostage)
{
	CheckUpdateOfficerAssignmentsForHostage(Hostage);
}

// notification that an enemy has unbecome a threat
function NotifyEnemyUnbecameThreat(Pawn Enemy)
{
	CheckUpdateOfficerAssignmentsForEnemy(Enemy);
}

function NotifyEnemyFleeing(Pawn Enemy)
{
	assert(Enemy != None);

	SwatAIRepo.GetElementSquad().TriggerEnemyFleeingSpeech(Enemy);
}

// notification that an AI has become compliant
function NotifyAIBecameCompliant(Pawn AI)
{
	Blackboard.RemoveAssignedTarget(AI);

	UpdateOfficerAssignments();
}

// notification that the AI has finished complying and is on the ground
function NotifyCompliantAIFinishedComplying(Pawn AI)
{
	if (! Blackboard.IsACompliantAI(AI))
	{
		SwatAIRepo.GetElementSquad().TriggerTargetCompliantSpeech(AI);

		Blackboard.AddCompliantAI(AI);
	}
}

function NotifyAIBecameRestrained(Pawn AI)
{
	Blackboard.RemoveCompliantAI(AI);
	Blackboard.AddRestrainedAI(AI);
}

function RemoveWatchedAI(Pawn AI)
{
	Blackboard.RemoveWatchedAI(AI);
}

function AddWatchedAI(Pawn AI)
{
	Blackboard.AddWatchedAI(AI);
}

private function bool FindCompliantTargetToWatch(Pawn Officer, out Pawn CompliantTarget)
{
	local int i;
	local Pawn CompliantAIIter;
	local array<Pawn> CompliantTargets;

	for(i=0; i<Blackboard.CompliantAIs.Length; ++i)
	{
		CompliantAIIter = Blackboard.CompliantAIs[i];

//		log("CompliantAIIter is: " $ CompliantAIIter $ " IsAIBeingWatched: " $ Blackboard.IsAIBeingWatched(CompliantAIIter) $ " LineOfSight: " $ Officer.LineOfSightTo(CompliantAIIter));
//		log("Distance to CompliantIter: " $ VSize(CompliantAIIter.Location - Officer.Location) $ " MaxWatchTargetDistance: " $ MaxWatchTargetDistance);

		if (!Blackboard.IsAIBeingWatched(CompliantAIIter) &&
			(VSize(CompliantAIIter.Location - Officer.Location) < MaxWatchTargetDistance) &&
			(Officer == GetClosestOfficerThatCanHit(CompliantAIIter)))
		{
			CompliantTargets[CompliantTargets.Length] = CompliantAIIter;
		}
	}

	if (CompliantTargets.Length > 0)
	{
		CompliantTarget = CompliantTargets[Rand(CompliantTargets.Length)];
		return true;
	}
	else
	{
		return false;
	}
}

private function bool FindRestrainedTargetToWatch(Pawn Officer, out Pawn RestrainedTarget)
{
	local int i;
	local Pawn RestrainedAIIter;
	local array<Pawn> RestrainedTargets;

	for(i=0; i<Blackboard.RestrainedAIs.Length; ++i)
	{
		RestrainedAIIter = Blackboard.RestrainedAIs[i];

		if (!Blackboard.IsAIBeingWatched(RestrainedAIIter) &&
			(VSize(RestrainedAIIter.Location - Officer.Location) < MaxWatchTargetDistance) &&
			(Officer == GetClosestOfficerThatCanHit(RestrainedAIIter)))
		{
			RestrainedTargets[RestrainedTargets.Length] = RestrainedAIIter;
		}
	}

	if (RestrainedTargets.Length > 0)
	{
		RestrainedTarget = RestrainedTargets[Rand(RestrainedTargets.Length)];
		return true;
	}
	else
	{
		return false;
	}
}

function Pawn FindTargetToWatchForOfficer(Pawn Officer)
{
	local Pawn TargetToWatch;

	if (FindCompliantTargetToWatch(Officer, TargetToWatch) ||
		FindRestrainedTargetToWatch(Officer, TargetToWatch))
	{
		return TargetToWatch;
	}
	else
	{
		// didn't find a target to watch
		return None;
	}
}

function NotifyAIDied(Pawn AI)
{
	assert(AI != None);

	Blackboard.RemoveAssignedTarget(AI);

	// just in case this AI was in any of the blackboard's lists
	Blackboard.RemoveCompliantAI(AI);
	Blackboard.RemoveRestrainedAI(AI);
	Blackboard.RemoveWatchedAI(AI);

	// update officer assignments if we have encountered this AI
	if (Blackboard.HasAIBeenEncountered(AI))
	{
		UpdateOfficerAssignments();
	}

	if (AI.IsA('SwatEnemy'))
	{
		SwatAIRepo.GetElementSquad().TriggerSuspectDownSpeech(AI);
	}
	else if (AI.IsA('SwatHostage'))
	{
		SwatAIRepo.GetElementSquad().TriggerHostageDownSpeech(AI);
	}
    else
    {
		// sanity check!
		assert(AI.IsA('SwatTrainer'));
        // @TODO: Will we have this speech in the game? [darren]
		//SwatAIRepo.GetElementSquad().TriggerTrainerDownSpeech(AI);
    }
}

// Notification from a swat officer that he has been fully-constructed
function NotifyOfficerConstructed(Pawn Officer)
{
    AddOfficerToHiveAwareness(Officer);
}

function NotifyOfficerDestroyed(Pawn Officer)
{
    RemoveOfficerFromHiveAwareness(Officer);
}

function NotifyOfficerDied(Pawn Officer)
{
	assert(Officer != None);

	ClearEngagingPointForOfficer(Officer);

	UpdateOfficerAssignments();

	SwatAIRepo.GetElementSquad().TriggerOfficerDownSpeech(Officer);
    RemoveOfficerFromHiveAwareness(Officer);
}

function NotifyPlayerDied(Pawn Player)
{
	assert(Player != None);

	SwatAIRepo.GetElementSquad().TriggerLeadDownSpeech(Player);
}

///////////////////////////////////////////////////////////////////////////////
//
// Queries

function bool IsPawnWithinDistanceOfOfficers(Pawn TestPawn, float Distance, bool bRequiresLineOfSight)
{
	local int i;
	local Pawn IterOfficer, Player;
	local Controller Iter;

	assert(TestPawn != None);

	if (TestPawn.Level.NetMode == NM_Standalone)
	{
		Player = TestPawn.Level.GetLocalPlayerController().Pawn;

		// make sure the player is alive before testing based on them
		if (class'Pawn'.static.checkConscious(Player))
		{
			if ((VSize2D(Player.Location - TestPawn.Location) < Distance) && (! bRequiresLineOfSight || TestPawn.LineOfSightTo(Player)))
				return true;
		}

		// now check the AIs
		for(i=0; i<GetNumOfficers(); ++i)
		{
			IterOfficer = GetOfficer(i);

			if ((VSize2D(IterOfficer.Location - TestPawn.Location) < Distance) && (! bRequiresLineOfSight || TestPawn.LineOfSightTo(IterOfficer)))
				return true;
		}
	}
	else
	{
		// we should be a coop game (and be the server)
		assert(TestPawn.Level.IsCOOPServer);

		// go through the (alive) players on the server, and see who is close enough
		for (Iter = TestPawn.Level.ControllerList; Iter != None; Iter = Iter.NextController)
		{
			if (Iter.IsA('PlayerController'))
			{
				IterOfficer = Iter.Pawn;

				if (class'Pawn'.static.checkConscious(IterOfficer))
				{
					if ((VSize2D(IterOfficer.Location - TestPawn.Location) < Distance) && (! bRequiresLineOfSight || TestPawn.LineOfSightTo(IterOfficer)))
						return true;
				}
			}
		}
	}

	return false;
}

function bool IsActorWithinDistanceOfOfficers(Actor TestActor, float Distance)
{
	local int i;
	local Pawn IterOfficer, Player;
	local Controller Iter;

	assert(TestActor != None);

	if (TestActor.Level.NetMode == NM_Standalone)
	{
		Player = TestActor.Level.GetLocalPlayerController().Pawn;

		// make sure the player is alive before testing based on them
		if (class'Pawn'.static.checkConscious(Player))
		{
			if (VSize2D(Player.Location - TestActor.Location) < Distance)
				return true;
		}

		// now check the AIs
		for(i=0; i<GetNumOfficers(); ++i)
		{
			IterOfficer = GetOfficer(i);

			if (VSize2D(IterOfficer.Location - TestActor.Location) < Distance)
				return true;
		}
	}
	else
	{
		// we should be a coop game (and be the server)
		assert(TestActor.Level.IsCOOPServer);

		// go through the (alive) players on the server, and see who is close enough
		for (Iter = TestActor.Level.ControllerList; Iter != None; Iter = Iter.NextController)
		{
			if (Iter.IsA('PlayerController'))
			{
				IterOfficer = Iter.Pawn;

				if (class'Pawn'.static.checkConscious(IterOfficer))
				{
					if (VSize2D(IterOfficer.Location - TestActor.Location) < Distance)
						return true;
				}
			}
		}
	}

	return false;
}

///////////////////////////////////////////////////////////////////////////////
//
// Engaging Points

function NavigationPoint RequestNewEngagingPointForOfficer(Pawn Officer, Pawn OfficerOpponent)
{
	local NavigationPoint EngagingPoint;

	// clear any existing engaging points for this officer
	ClearEngagingPointForOfficer(Officer);

	// get a new (or the same) point
	EngagingPoint = FindEngagingPointForOfficerInRoom(Officer, OfficerOpponent, kRequestEngagePointStaleDelta);

	// if the point's valid, then claim it for this Officer
	if (EngagingPoint != None)
	{
		SetEngagingPointForOfficer(EngagingPoint, Officer);
	}

	return EngagingPoint;
}

// clears out any point this officer has claimed for engaging
native function ClearEngagingPointForOfficer(Pawn Officer);

// set a point to be used by an officer, so multiple officers don't try and engage from the same point
native private function SetEngagingPointForOfficer(NavigationPoint inPoint, Pawn Officer);

// finds a point in the room that the officer is in that he will able to hit the Opponent from
native function NavigationPoint FindEngagingPointForOfficerInRoom(Pawn Officer, Pawn OfficerOpponent, float CacheStaleDeltaTime);

///////////////////////////////////////////////////////////////////////////////
//
// Vision

function OfficerSawPawn(Pawn OfficerViewer, Pawn Seen)
{
	assert(OfficerViewer != None);
	assert(Seen != None);

	if (Seen.IsA('SwatPlayer'))
	{
		if (CanAssignAnyOfficerToTarget(Seen))
		{
			// this may need to be moved because this will be called every time we see a Enemy or Hostage
			// (then it will be called too often I think)
			UpdateOfficerAssignments();
		}
	}
	else
	{
		if (! Blackboard.HasAIBeenEncountered(Seen))
		{
			if (Seen.IsA('SwatEnemy'))
			{
				OfficerSawEnemy(OfficerViewer, Seen);
			}
			else
			{
				// sanity check
				assert(Seen.IsA('SwatHostage'));

				OfficerSawHostage(OfficerViewer, Seen);
			}
		}

		// if the officer doesn't have a current assignment
		// we only want to engage Seen if they aren't compliant, restrained, or incapacitated,
		// if they are a threat or not ignoring us, and we can assign any officer to them
		if (! ISwatAI(Seen).IsCompliant() &&
			! ISwatAI(Seen).IsArrested() &&
			! Seen.IsIncapacitated() &&
			(Seen.IsAThreat() || ! ISwatAI(Seen).GetCommanderAction().IsIgnoringComplianceOrders()) &&
			CanAssignAnyOfficerToTarget(Seen))
		{
			// this may need to be moved because this will be called every time we see a Enemy or Hostage
			// (then it will be called too often I think)
			UpdateOfficerAssignments();
		}
	}
}

//if WasLostRecently is true, we won't play the officer speech
function OfficerLostPawn(Pawn OfficerViewer, Pawn Lost, bool WasLostRecently)
{
	assert(OfficerViewer != None);
	assert(Lost != None);

	if (Lost.IsA('SwatPlayer'))
	{
		if (CanAssignAnyOfficerToTarget(Lost))
		{
			// this may need to be moved because this will be called every time we see a Enemy or Hostage
			// (then it will be called too often I think)
			UpdateOfficerAssignments();
		}
	}
	else
	{
		if (Blackboard.HasAIBeenEncountered(Lost))
		{
			if (Lost.IsA('SwatEnemy'))
			{
				OfficerLostEnemy(OfficerViewer, Lost, WasLostRecently);
				Blackboard.RemoveAssignedTarget(Lost);
			}
			else
			{
				// sanity check
				assert(Lost.IsA('SwatHostage'));

				OfficerLostHostage(OfficerViewer, Lost);
				Blackboard.RemoveAssignedTarget(Lost);
			}
		}
	}
}

function bool HasTurnedOnPlayer()
{
	return (CurrentPlayerDamage >= PlayerDamageThreshold);
}

function NotifyOfficerShotByPlayer(Pawn OfficerShot, float Damage, Pawn PlayerInstigator)
{
	assert(PlayerInstigator != None);
	assert(OfficerShot != None);

	// only attack this pawn if we don't have a player enemy
	if (Blackboard.PlayerEnemy != PlayerInstigator)
	{
		// make sure we only add up to 100 points of damage for each shot
		CurrentPlayerDamage += FMin(Damage, 100.f);

		if (OfficerShot.logAI)
			log("CurrentPlayerDamage is: " $ CurrentPlayerDamage $ " PlayerDamageThreshold: " $ PlayerDamageThreshold);

		if (HasTurnedOnPlayer())
		{
			if (OfficerShot.logAI)
				log("going to attack: " $ PlayerInstigator.Name);

			PlayerCrossedDamageThreshold(PlayerInstigator);
		}
		else
		{
			TriggerAppropriateSpeechForRogueLead(OfficerShot);
		}
	}
}

private function TriggerAppropriateSpeechForRogueLead(Pawn OfficerShot)
{
	if (! bTriggeredFirstShotReaction)
	{
		SwatAIRepo.GetElementSquad().TriggerReactedFirstShotSpeech(OfficerShot);

		bTriggeredFirstShotReaction = true;
	}
	else if (! bTriggeredSecondShotReaction)
	{
		SwatAIRepo.GetElementSquad().TriggerReactedSecondShotSpeech(OfficerShot);

		bTriggeredSecondShotReaction = true;
	}
}

private function PlayerCrossedDamageThreshold(Pawn Player)
{
	local ElementSquadInfo Element;
	local int i;

	Blackboard.PlayerEnemy = Player;

	Element = SwatAIRepo.GetElementSquad();

	// make it so we see the player
	for(i=0; i<Element.Pawns.Length; ++i)
	{
		Element.Pawns[i].AddViewablePawn(Player);
	}

	// trigger appropriate speech to attack the officer
	Element.TriggerReactedThirdShotSpeech(Player);

	// update the officer assignments so that we go after the player right away
	UpdateOfficerAssignments();
}

// notification that an officer has finished their assignment
function FinishedAssignment()
{
	UpdateOfficerAssignments();
}

// notification that an AI is ignoring us
function NotifyAIIgnoringOfficers(Pawn AI)
{
	if (AI.IsA('SwatEnemy'))
		SwatAIRepo.GetElementSquad().TriggerSuspectWontComplySpeech(AI);
	else
		SwatAIRepo.GetElementSquad().TriggerHostageWontComplySpeech(AI);

	// for now we just update officer assignments
	UpdateOfficerAssignments();
}

// Officers are notified about hostages when the player sees them
function NotifyOfficersOfTarget(Pawn Target)
{
	assertWithDescription((Target.IsA('SwatHostage') || Target.IsA('SwatEnemy')), "Hive::NotifyOfficersOfTarget - Target ("$Target$") is not a SwatHostage or SwatEnemy");

	if (Target.IsA('SwatHostage'))
	{
		Blackboard.UpdateHostage(Target);
	}
	else
	{
		Blackboard.UpdateEnemy(Target);
	}
}

private function OfficerSawHostage(Pawn OfficerViewer, Pawn SeenHostage)
{
	Blackboard.UpdateHostage(SeenHostage);

	// only say something if the hostage is not already arrested or compliant
	if (! ISwatAI(SeenHostage).IsCompliant() &&
		! ISwatAI(SeenHostage).IsArrested())
	{
		// trigger a sound for the viewer to say
		ISwatOfficer(OfficerViewer).GetOfficerSpeechManagerAction().TriggerHostageSpottedSpeech(SeenHostage);
	}
}

private function OfficerLostHostage(Pawn OfficerViewer, Pawn LostHostage)
{
	Blackboard.UpdateHostage(LostHostage);
}

private function OfficerSawEnemy(Pawn OfficerViewer, Pawn SeenEnemy)
{
	// only say something if the suspect is not already arrested or compliant
	if (! ISwatAI(SeenEnemy).IsCompliant() &&
		! ISwatAI(SeenEnemy).IsArrested() &&
		! Blackboard.IsAnAssignedTarget(SeenEnemy))
	{
		// trigger a sound for the viewer to say
		ISwatOfficer(OfficerViewer).GetOfficerSpeechManagerAction().TriggerSuspectSpottedSpeech();
	}
	Blackboard.UpdateEnemy(SeenEnemy);

}

private function OfficerLostEnemy(Pawn OfficerViewer, Pawn LostEnemy, bool WasLostRecently)
{
	// only say something if the hostage is not already arrested or compliant, and wasn't lost recently
	if (! ISwatAI(LostEnemy).IsCompliant() &&
		! ISwatAI(LostEnemy).IsArrested() &&
		class'Pawn'.static.checkConscious(LostEnemy) &&
		Blackboard.IsAnAssignedTarget(LostEnemy) &&
		! WasLostRecently)
	{
		// trigger a sound for the viewer to say
//		ISwatOfficer(OfficerViewer).GetOfficerSpeechManagerAction().TriggerSuspectLostSpeech();
	}
//	Blackboard.UpdateEnemy(LostEnemy);
}
private function ClearCommandGoalsForOfficer(Pawn Officer)
{
	if (Officer.logTyrion)
		log("ClearCommandGoalsForOfficer ("$Officer.Name$") - Element is executing command: " $ SwatAIRepo.GetElementSquad().IsExecutingCommandGoal());

	SwatAIRepo.Level.GetLocalPlayerController().ClearHeldCommand(SwatAIRepo.GetElementSquad());
	SwatAIRepo.Level.GetLocalPlayerController().ClearHeldCommandCaptions(SwatAIRepo.GetElementSquad());
	SwatAIRepo.GetElementSquad().ClearHeldFlag();

	if (SwatAIRepo.GetElementSquad().IsExecutingCommandGoal())
	{
		// clear all of the command goals from all of the squads
		SwatAIRepo.GetElementSquad().ClearNonCharacterInteractionCommandGoal();
	}
	else if (SwatAIRepo.GetRedSquad().IsOfficerOnTeam(Officer))
	{
		if (Officer.logTyrion)
			log("Red team executing command goal - " $ SwatAIRepo.GetRedSquad().IsExecutingCommandGoal());

		if (SwatAIRepo.GetRedSquad().IsExecutingCommandGoal())
		{
			SwatAIRepo.GetRedSquad().ClearNonCharacterInteractionCommandGoal();
		}
	}
	else if (SwatAIRepo.GetBlueSquad().IsOfficerOnTeam(Officer))
	{
		if (Officer.logTyrion)
			log("Blue team executing command goal - " $ SwatAIRepo.GetRedSquad().IsExecutingCommandGoal());

		if (SwatAIRepo.GetRedSquad().IsExecutingCommandGoal())
		{
			SwatAIRepo.GetBlueSquad().ClearNonCharacterInteractionCommandGoal();
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Officer Assignments

private function bool IsOfficerBreaching(Pawn Officer)
{
	assert(class'Pawn'.static.checkConscious(Officer));

	return ((AI_Resource(Officer.characterAI).findGoalByName("UseBreachingShotgun") != None) ||
			(AI_Resource(Officer.characterAI).findGoalByName("UseBreachingCharge") != None));
}

private function bool IsOfficerDeployingNonLethal(Pawn Officer)
{
	assert(class'Pawn'.static.checkConscious(Officer));

	return ((AI_Resource(Officer.characterAI).findGoalByName("ThrowGrenade") != None) ||
			(AI_Resource(Officer.characterAI).findGoalByName("DeployPepperSpray") != None) ||
			(AI_Resource(Officer.characterAI).findGoalByName("DeployTaser") != None) ||
			(AI_Resource(Officer.characterAI).findGoalByName("DeployLessLethalShotgun") != None) ||
			(AI_Resource(Officer.characterAI).findGoalByName("DeployGrenadeLauncher") != None));
}

private function bool IsOfficerClearingIntoRoom(Pawn Officer, name RoomName)
{
	if (SwatAIRepo.GetElementSquad().IsMovingAndClearing())
	{
		if (Officer.logAI)
			log("IsOfficerClearingIntoRoom - Element - RoomName: " $ RoomName $ " RoomToClear: " $ SwatAIRepo.GetElementSquad().GetRoomNameToClear());

		return (RoomName == SwatAIRepo.GetElementSquad().GetRoomNameToClear());
	}
	else if (SwatAIRepo.GetRedSquad().IsOfficerOnTeam(Officer))
	{
		if (SwatAIRepo.GetRedSquad().IsMovingAndClearing())
		{
			if (Officer.logAI)
				log("IsOfficerClearingIntoRoom - RedTeam - RoomName: " $ RoomName $ " RoomToClear: " $ SwatAIRepo.GetRedSquad().GetRoomNameToClear());

			return (RoomName == SwatAIRepo.GetRedSquad().GetRoomNameToClear());
		}
	}
	else
	{
		if (SwatAIRepo.GetBlueSquad().IsMovingAndClearing())
		{
			if (Officer.logAI)
				log("IsOfficerClearingIntoRoom - BlueTeam - RoomName: " $ RoomName $ " RoomToClear: " $ SwatAIRepo.GetBlueSquad().GetRoomNameToClear());

			return (RoomName == SwatAIRepo.GetBlueSquad().GetRoomNameToClear());
		}
	}

	return false;
}

// if we are in the same room, have a line of sight, or we can find an engaging point for the officer in the room,
// we can assign an officer to this target
// don't give the officer an assignment if they're deploying a thrown item or breaching
private event bool CanAssignOfficerToTarget(Pawn Officer, Pawn Target)
{
	local bool bIsTargetAThreat;

	assert(class'Pawn'.static.checkConscious(Officer));

	if (Target.IsA('SwatEnemy'))
		bIsTargetAThreat = ISwatEnemy(Target).IsAThreat();

	if(IsOfficerDeployingNonLethal(Officer) || IsOfficerBreaching(Officer))
	{
		// Don't assign us if we're applying less lethal equipment
		return false;
	}

	if(FindEngagingPointForOfficerInRoom(Officer, Target, 0.0) != None)
	{ // DO NOT assign us if we cannot find a point to engage our target from
		if(Target.IsInRoom(Officer.GetRoomName()))
		{
			// DO assign us if we're in the same room
			return true;
		}

		if(IsOfficerClearingIntoRoom(Officer, Target.GetRoomName()))
		{
			// DO assign us if we are in another room, and we are clearing.
			return true;
		}

		if(Officer.CanHit(Target) || Officer.LineOfSightTo(Target))
		{ // DO assign us if we can hit the target or they are within LOS
			return true;
		}
	}

	return false;
}

private function bool CanAssignAnyOfficerToTarget(Pawn Target)
{
	local int i;
	local Pawn Officer;
	local array<Pawn> OfficersOrderedByDistanceToTarget;

	// we're gonna test based on distance, in the hopes that the closer members will be able to hit first
	for(i=0; i<GetNumOfficers(); ++i)
	{
		Officer = GetOfficer(i);

		if (class'Pawn'.static.checkConscious(Officer))
		{
			OfficersOrderedByDistanceToTarget[OfficersOrderedByDistanceToTarget.Length] = Officer;
		}
	}

	for(i=0; i<OfficersOrderedByDistanceToTarget.Length; ++i)
	{
		Officer = OfficersOrderedByDistanceToTarget[i];

		if (CanAssignOfficerToTarget(Officer, Target))
		{
			return true;
		}
	}

	return false;
}

// Called whenever we see a Hostage or an Enemy (after they are put on the blackboard)

native function UpdateOfficerAssignments();

private event AssignOfficer(Pawn Officer, Pawn Assignment)
{
	assert(Officer != None);
	assert(Assignment != None);

	if (Officer.logAI)
		log("telling " $ Officer $ " to engage " $ Assignment);

	// kill off any command goals (squad behaviors) that this officer is currently executing
	ClearCommandGoalsForOfficer(Officer);

	// save off that this target is assigned
	Blackboard.AddAssignedTarget(Assignment);

	// add the officer assignment
	ISwatOfficer(Officer).GetOfficerCommanderAction().EngageTarget(Assignment);
}

private event ClearOfficerEngagements(Pawn Officer)
{
	if (Officer.logAI)
		log(Officer.Name $ " ClearOfficerEngagements");

	// clear the assignment and engagement goals of the Officer
	ISwatOfficer(Officer).GetOfficerCommanderAction().ClearAssignment();
	ISwatOfficer(Officer).GetOfficerCommanderAction().ClearEngageGoals();
}
