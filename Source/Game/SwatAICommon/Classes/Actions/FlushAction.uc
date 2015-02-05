///////////////////////////////////////////////////////////////////////////////
// FlushAction.uc - FlushAction class
// The Action that causes the AI to find a FlushPoint at which to destroy eviddence

class FlushAction extends FleeAction;
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private FlushPoint					FlushDestination;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

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

   if (CurrentRotateTowardRotationGoal != None)
    {
        CurrentRotateTowardRotationGoal.Release();
        CurrentRotateTowardRotationGoal = None;
    }

	ResetFullBodyAnimations();
}

///////////////////////////////////////////////////////////////////////////////
// 
// Selection Heuristic

// returns true if we find a flush destination
private function bool FindFlushDestination()
{
	FlushDestination = FindFlushPointDestination();

	return (FlushDestination != None);
}

function float selectionHeuristic( AI_Goal goal )
{
	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	if (FindFlushDestination() && ISwatEnemy(m_Pawn).HasEvidence())
	{
		return 1.0;
	}
	
	return 0.0;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function FlushPoint FindFlushPointDestination()
{
    local SwatAIRepository SwatAIRepo;
    local FlushPoint Destination, Iter;
    local NavigationPointList AllFlushPoints, ExcludesFlushPoints;
    local int i;
	local Pawn CurrentEnemy, IterFlushPointUser;

	local array<FlushPoint> PossibleDestinations;

    SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

    // we exclude the flee points that are in the room we're in
    ExcludesFlushPoints = SwatAIRepo.GetRoomNavigationPointsOfType(m_Pawn.GetRoomName(), 'FlushPoint');
    AllFlushPoints = SwatAIRepo.FindAllOfNavigationPointClass(class'FlushPoint', ExcludesFlushPoints);

	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

    // go through each point and find the closest
    for(i=0; i<AllFlushPoints.GetSize(); ++i)
    {
        Iter = FlushPoint(AllFlushPoints.GetEntryAt(i));
		
//		log("Distance to ITer from Enemy is: " $ VSize2D(Iter.Location - CurrentEnemy.Location) $ " Required Distance is: " $ MinRequiredFleeDistanceFromOfficer);

        if ((CurrentEnemy == None) || !CurrentEnemy.IsInRoom(Iter.GetRoomName(CurrentEnemy)))
        {
			IterFlushPointUser = Iter.GetFlushPointUser();

			if ((IterFlushPointUser == None) || (IterFlushPointUser == m_Pawn))
			{
				PossibleDestinations[PossibleDestinations.Length] = Iter;
			}
        }
    }

	// all done with the excludes list
	SwatAIRepo.ReleaseNavigationPointList(ExcludesFlushPoints);
	SwatAIRepo.ReleaseNavigationPointList(AllFlushPoints);

	if (PossibleDestinations.Length > 0)
		Destination = PossibleDestinations[Rand(PossibleDestinations.Length)];

    return Destination;
}

latent function RotateTowardsTarget()
{
    CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(FlushDestination.Location - m_Pawn.Location));
    assert(CurrentRotateTowardRotationGoal != None);
    CurrentRotateTowardRotationGoal.AddRef();

    CurrentRotateTowardRotationGoal.postGoal(self);
    WaitForGoal(CurrentRotateTowardRotationGoal);
    CurrentRotateTowardRotationGoal.unPostGoal(self);

    CurrentRotateTowardRotationGoal.Release();
    CurrentRotateTowardRotationGoal = None;
}

latent function PlayFlushAnimation()
{
	local int animChannel;
	local MeshAnimation mesh_anim;

	// load a new animation set if specified
	mesh_anim = MeshAnimation(DynamicLoadObject("SWATMaleAnimation2.SwatHostage", class'MeshAnimation', true));
	if (mesh_anim == None)
		Log("FlushAction: Couldn't load animation set SWATMaleAnimation2");
	else
		m_Pawn.LinkSkelAnim(mesh_anim);

	animChannel = m_Pawn.animPlaySpecial('sDrugDispose');
	m_Pawn.finishAnim(animChannel);
}

latent function Flush()
{
	local Pawn CurrentEnemy;
	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

	// trigger the speech
	ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerFleeSpeech();

	if (CurrentEnemy != None)
	{
		// let the hive know so officers can "notice" it if they see us
		SwatAIRepository(Level.AIRepo).GetHive().NotifyEnemyFleeing(m_Pawn);
	}

	assert(FlushDestination != None);

    CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, FlushDestination);
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
    WaitForGoal(CurrentMoveToActorGoal);

    // remove the most to goal
    CurrentMoveToActorGoal.unPostGoal(self);
	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;

	if (VSize(m_Pawn.Location - FlushDestination.Location) < 100)
	{
		// rotate towards toilet
		RotateTowardsTarget();

		useResources(class'AI_Resource'.const.RU_LEGS);

		// play animation
		PlayFlushAnimation();
	}
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

    Flush();
    
	// let the commander know to clean up after this particular behavior
	ISwatEnemy(m_Pawn).GetEnemyCommanderAction().FinishedMovingEngageBehavior();

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageOfficerGoal'
}