///////////////////////////////////////////////////////////////////////////////
// MoveToAttackOfficerAction.uc - MoveToAttackOfficerAction class
// Action that we use to move enemies to attack officers

class MoveToAttackOfficerAction extends MoveToOpponentAction
	config(AI);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// internal
var private vector		StartMovingLocation;
var private float		DistanceToTravel;
var private bool		bFinishUp;

// config
var config float		MinDistanceToTravel;
var config float		MaxDistanceToTravel;

var config float		CrouchWhileAttackingChance;
var config float		MinDistanceToCrouch;
var config float		MinTimeToCrouch;
var config float		MaxTimeToCrouch;
var config float		MinTimeToStand;
var config float		MaxTimeToStand;

///////////////////////////////////////////////////////////////////////////////
//
// Movement Test

// we want to stop moving if we can attack
function bool ShouldStopMovingToOfficer(Pawn MovingPawn)
{
    local FiredWeapon CurrentWeapon;
	local Pawn CurrentEnemy;

	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

	// stop if we're supposed to based on distance
	if (VSize2D(m_Pawn.Location - StartMovingLocation) >= DistanceToTravel)
		return true;

    CurrentWeapon = FiredWeapon(m_Pawn.GetActiveItem());

    if (CurrentWeapon != None)
    {
		// if the current weapon is being reloaded, don't move
		// TODO: maybe have them try and move before reloading
		if (CurrentWeapon.IsBeingReloaded())
			return true;

		// if the destination isn't a pawn, is None, or is dead, fail!
		if (!class'Pawn'.static.checkConscious( CurrentEnemy ))
		{
			if (MovingPawn.logTyrion)
			{
				log(Name $ " failed because CurrentEnemy " $ CurrentEnemy $ " isn't conscious");
			}

			return true;
		}

        // if there's nothing between the weapon and our enemy, we can stop
        if (m_Pawn.CanHit(CurrentEnemy))
        {
//			log("Level.TimeSeconds: " $ Level.TimeSeconds $ " FirstCanHitTime: " $ FirstCanHitTime $ " (FirstCanHitTime + kMinTimeToStopMoving): " $ (FirstCanHitTime + kMinTimeToStopMoving));

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
		else
		{
			// keep moving
			FirstCanHitTime = 0.0;
			return false;
		}
    }
	else
	{
		// if we don't have a weapon equipped, don't move
		FirstCanHitTime = 0.0;		// reset the timer
		return true;
	}
}

private function bool ShouldCrouchWhileAttacking()
{
	local Actor Target;

	Target = MoveToActorGoal(achievingGoal).GetDestinationActor();

	return  ((FRand() < CrouchWhileAttackingChance) && 
			 (VSize(Target.Location - m_Pawn.Location) >= MinDistanceToCrouch));
}

private latent function CrouchWhileAttacking()
{
	bShouldCrouch = true;
	SetMovement(false, bShouldCrouch);

//	log("should be crouching now! time is " $ Level.TimeSeconds);

	sleep(RandRange(MinTimeToCrouch, MaxTimeToCrouch));
}

private latent function StandUp()
{
	bShouldCrouch = false;
	SetMovement(false, bShouldCrouch);

	sleep(RandRange(MinTimeToStand, MaxTimeToStand));
}

// allows us to stand up first before completing
// notification comes from AttackOfficerAction
function FinishUp()
{
	bFinishUp = true;
	gotostate('Running', 'End');
}

state Running
{
 Begin:
    bSucceeded = false;

	DistanceToTravel    = RandRange(MinDistanceToTravel, MaxDistanceToTravel);
	StartMovingLocation = m_Pawn.Location;

	MoveToGoalBase(achievingGoal).ShouldStopMovingDelegate = ShouldStopMovingToOfficer;
    MoveToActor();

	if (bStopWhenSuccessful)
	{
		succeed();
	}
	else
	{
		if (ShouldCrouchWhileAttacking())
		{
			CrouchWhileAttacking();
		}

		// wait until we need to move
		while (ShouldStopMoving())
		{
			yield();
		}

 End:
		if (m_Pawn.bIsCrouched)
		{
			StandUp();
		}

		if (bFinishUp)
			succeed();

		yield();
		goto('Begin');
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal=class'MoveToAttackOfficerGoal'
}