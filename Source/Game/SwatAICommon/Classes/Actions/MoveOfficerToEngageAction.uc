///////////////////////////////////////////////////////////////////////////////
// MoveOfficerToEngageAction.uc - MoveOfficerToEngageAction class
// Goal that we use to move officers to engage enemies and hostage for compliance,
// or to attack enemies

class MoveOfficerToEngageAction extends MoveToOpponentAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) Pawn Opponent;

// where we attack from - a member variable in case latent function to determine it is required
var private NavigationPoint		PointToEngageFrom;

// room name that we will stay in
var private	name				RoomNameToEngageFrom;

// time between trying finding a point to engage from
const kMinSleepTimeBetweenFindEngagePointTests = 1.0;
const kMaxSleepTimeBetweenFindEngagePointTests = 3.0;

///////////////////////////////////////////////////////////////////////////////
//
// Init. / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	// save off the room we're engage from
	RoomNameToEngageFrom = m_Pawn.GetRoomName();
}

function cleanup()
{
	super.cleanup();

	if (PointToEngageFrom != None)
	{
		SwatAIRepository(Level.AIRepo).GetHive().ClearEngagingPointForOfficer(m_Pawn);
	}
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//
// Movement Test

function bool ShouldStopMovingToOpponent(Pawn MovingPawn)
{
    local FiredWeapon CurrentWeapon;
	local float DistanceToOpponent;

	// don't stop moving in a doorway
	if (m_Pawn.Anchor.IsA('Door'))
		return false;

    CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());
//	log("ShouldStopMovingToOpponent - CurrentWeapon is: " $ CurrentWeapon);

    if (CurrentWeapon != None)
    {
//		log("ShouldStopMovingToOpponent - CurrentWeapon.IsBeingReloaded: " $ CurrentWeapon.IsBeingReloaded());

		// if the current weapon is being reloaded, don't move
		// TODO: maybe have them try and move before reloading
		if (CurrentWeapon.IsBeingReloaded())
			return true;

		// if the opponent is dead, stop moving
		if (!class'Pawn'.static.checkConscious(Opponent))
		{
			if (MovingPawn.logTyrion)
			{
				log(Name $ " failed because Opponent " $ Opponent $ " isn't conscious");
			}

			return true;
		}

		DistanceToOpponent = VSize(Opponent.Location - m_Pawn.Location);

		// don't let us get to close to the target
//		log(m_Pawn.Name $ " Destination: " $ Destination.Name $ " DistanceToDestination: " $ DistanceToDestination $ " DistanceToStopMoving: " $ DistanceToStopMoving);
		if (DistanceToOpponent < DistanceToStopMoving)
			return true;

        // if there's nothing between the weapon and our enemy (the destination), we can stop
        if (m_Pawn.CanHit(Opponent))
        {
			if (FirstCanHitTime == 0.0)
			{
				// if we haven't saved off the last time we can hit.  save it off.
				FirstCanHitTime = Level.TimeSeconds;
			}
			else if ((FirstCanHitTime != 0.0) && (Level.TimeSeconds > (FirstCanHitTime + kMinTimeToStopMoving)))
			{
				// if we have been able to hit the target for the right amount of time, stop!
				return true;
			}

			// we're not ready to stop just yet
			return false;
        }   

		FirstCanHitTime = 0.0;	// reset the timer
		return false;
    }
    
    // if we have no weapon equipped, and we're attacking, just stop moving
	FirstCanHitTime = 0.0;		// reset the timer
    return true;
}

///////////////////////////////////////////////////////////////////////////////
//
// Finding / Moving to Points

private latent function MoveToPointToEngageFrom()
{
	assert(PointToEngageFrom != None);

	MoveToActorGoal(achievingGoal).SetDestinationActor(PointToEngageFrom);

	MoveToActor();
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

state Running
{
 Begin:
 RunningLoop:
	bSucceeded = false;

	// stop moving while we can hit the target
	// otherwise we try to find a point in the room we're in that we can engage from
	// and if we don't find a point, we just don't move
	if (m_Pawn.CanHit(Opponent))
	{
		pause();
	}
	else
	{
		PointToEngageFrom = SwatAIRepository(Level.AIRepo).GetHive().RequestNewEngagingPointForOfficer(m_Pawn, Opponent);

		if (PointToEngageFrom != None)
		{
			MoveToPointToEngageFrom();
		}
		
		sleep(RandRange(kMinSleepTimeBetweenFindEngagePointTests, kMaxSleepTimeBetweenFindEngagePointTests));
	}

	yield();
	goto('RunningLoop');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal=class'MoveOfficerToEngageGoal'
}