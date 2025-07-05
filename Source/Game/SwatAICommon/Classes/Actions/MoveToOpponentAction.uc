///////////////////////////////////////////////////////////////////////////////
// MoveToOpponentAction.uc - MoveToOpponentAction class
// Action that we use to move toward enemies

class MoveToOpponentAction extends MoveToActorAction
	config(AI);
///////////////////////////////////////////////////////////////////////////////

// this is a base class for moving to attack or engage an officer or an enemy

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) bool	bStopWhenSuccessful;

// this allows us to make sure we can hit by saying that we have been able to hit for a period of time.
var protected float		FirstCanHitTime;

// config
var config float		DistanceToStopMoving;

const kMinTimeToStopMoving = 0.1;

///////////////////////////////////////////////////////////////////////////////
//
// Movement Test

// we want to stop moving if we can attack
function bool ShouldStopMovingToOpponent(Pawn MovingPawn)
{
	local FiredWeapon CurrentWeapon;
	local Pawn Opponent;
	
	Opponent = Pawn(GetDestinationActor());

	// don't stop moving in a doorway
	if (m_Pawn.Anchor.IsA('Door'))
		return false;

    CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

    if (CurrentWeapon != None)
    {
		// if the current weapon is being reloaded, don't move
		if (CurrentWeapon.IsBeingReloaded())
			return true;

		if (CurrentWeapon.IsA('Pepperspray') )
		{
			if ( Vsize ( opponent.location - m_pawn.location ) >  (CurrentWeapon.Range * 0.66 ) )
			{
				return false;
			}
		}
		// if there's nothing between the weapon and our enemy (the destination), we can stop
        if ((Opponent != None) && m_Pawn.CanHitTarget(Opponent))
        {
			// we can hit the opponent, just stop
			return true;
        }   
	}

	// keep moving
	return false;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

state Running
{
Begin:
    bSucceeded = false;
	MoveToGoalBase(achievingGoal).ShouldStopMovingDelegate = ShouldStopMovingToOpponent;

    MoveToActor();

	if (bStopWhenSuccessful)
	{
		succeed();
	}
	else
	{
		// wait until we need to move
		while (ShouldStopMovingToOpponent(Pawn(GetDestinationActor())))
		{
			yield();
		}

		yield();
		goto('Begin');
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal=class'MoveToOpponentGoal'
}