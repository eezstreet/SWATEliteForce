class AttackEnemyWhileFallingInAction extends SwatCharacterAction;
/*class AttackEnemyWhileFallingInAction extends SWATTakeCoverAndAttackAction;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var(parameters) Pawn Enemy;

var private config float MaxDistanceFromPlayer;

var private MoveInFormationGoal	CurrentMoveInFormationGoal;
var private AimAroundGoal		CurrentAimAroundGoal;
var private ReloadGoal			CurrentReloadGoal;

var config float				FallInMinAimHoldTime; // 0.25
var config float				FallInMaxAimHoldTime; // 1

///////////////////////////////////////////////////////////////////////////////
//
// Selection Heuristic
// 1 if we are falling in, 0 otherwise
function float selectionHeuristic( AI_Goal goal )
{
	if(!IsFallingIn())
	{
		return 0.0;
	}
	
	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	assert(m_Pawn.IsA('SwatOfficer'));
	AICoverFinder = ISwatAI(m_Pawn).GetCoverFinder();
	assert(AICoverFinder != None);
}

///////////////////////////////////////////////////////////////////////////////
//
// cleanup
function cleanup()
{
	super.cleanup();

	if (CurrentMoveInFormationGoal != None)
	{
		CurrentMoveInFormationGoal.Release();
		CurrentMoveInFormationGoal = None;
	}

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}
	
	if (CurrentReloadGoal != None)
	{
		CurrentReloadGoal.Release();
		CurrentReloadGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State code

protected function bool PointIsTooFarFromLeader(vector v)
{
	return vsize(v - ISwatOfficer(m_Pawn).GetCurrentFormation().GetLeader().Location) >= MaxDistanceFromPlayer;
}

protected function bool CanUseCover()
{
	// We can't use cover that's too far away from the player
	// if the cover result says we have cover and it's low cover,
	// or it's normal cover and we can lean at that point
	if ((CoverResult.coverActor != None) &&
		((CoverResult.coverLocationInfo == kAICLI_InLowCover) ||
		 ((CoverResult.coverLocationInfo == kAICLI_InCover) && CanLeanAtCoverResult())) &&
		!PointIsTooFarFromLeader(CoverResult.coverLocation))
	{
		return true;
	}
	else
	{
		return false;
	}
}

function ReloadWeapons()
{
	CurrentReloadGoal = new class'SwatAICommon.ReloadGoal'(AI_WeaponResource(m_Pawn.WeaponAI));
	assert(CurrentReloadGoal != None);
	CurrentReloadGoal.AddRef();	

	CurrentReloadGoal.postGoal( self );
}

function AimAround()
{
	CurrentAimAroundGoal = new class'SwatAICommon.AimAroundGoal'(AI_WeaponResource(m_Pawn.WeaponAI), FallInMinAimHoldTime, FallInMaxAimHoldTime);
	assert(CurrentAimAroundGoal != None);
    CurrentAimAroundGoal.SetOnlyAimIfMoving(true);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.postGoal( self );
}

latent function FollowPlayer()
{	
	CurrentMoveInFormationGoal = new class'SwatAICommon.MoveInFormationGoal'(AI_MovementResource(m_Pawn.MovementAI), 90);
	assert(CurrentMoveInFormationGoal != None);
	CurrentMoveInFormationGoal.AddRef();	

    // Let the aim around action perform the aiming and rotation for us
	CurrentMoveInFormationGoal.SetRotateTowardsPointsDuringMovement(false);
	CurrentMoveInFormationGoal.SetAcceptNearbyPath(true);
	CurrentMoveInFormationGoal.SetWalkThreshold(192.0);

	CurrentMoveInFormationGoal.postGoal( self );
}

protected latent function AttackFromBehindCover()
{
	local Pawn Target;

	// while we can still attack (Target is not dead and we are not too far from the player)
	do
	{
		Target = GetEnemy();

		Attack(Target, true);

		// rotate to the attack orientation
		AttackRotation.Yaw = CoverResult.coverYaw;
		RotateToAttackRotation(Target);

		if (CoverResult.coverLocationInfo == kAICLI_InLowCover)
		{
			AttackWhileCrouchingBehindCover(Target);
		}
		else
		{
			AttackWhileLeaningBehindCover(Target);
		}

		yield();
	} until (! class'Pawn'.static.checkConscious(Target) && !PointIsTooFarFromLeader(m_Pawn.Location));
}

state Running
{
Begin:
	// create a sensor so we fail if we get to close to the suspects
	DistanceSensor = DistanceSensor(class'AI_Sensor'.static.activateSensor( self, class'DistanceSensor', characterResource(), 0, 1000000 ));
	assert(DistanceSensor != None);
	DistanceSensor.SetParameters(MinDistanceToSuspectsWhileTakingCover, GetEnemy(), false);

TryToTakeCover:
	m_tookCover = false;

	// If we are too far away from the player, we need to reel in, not take cover
	if(CanTakeCoverAndAttack())
	{
		TakeCoverAtInitialCoverLocation();
	}

AttackNow:
	// If we wound up taking cover, attack from behind cover.
	// If we did not take cover, just attack.
	if(m_tookCover)
	{
		AttackFromBehindCover();
	}
	else
	{
		Attack(Enemy, true);
	}

Regroup:
	ReloadWeapons();
	AimAround();
	FollowPlayer();

Loop:
	sleep(0.5);
	if(class'Pawn'.static.checkConscious(Enemy))
	{
		goto('TryToTakeCover');
	}
	else
	{
		goto('Loop');
	}
	
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'AttackEnemyGoal'
    MaxDistanceFromPlayer = 1024.0
    FallInMinAimHoldTime = 0.25
	FallInMaxAimHoldTime = 1
}
*/