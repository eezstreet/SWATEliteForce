///////////////////////////////////////////////////////////////////////////////
// EscapeAction.uc - EscapeAction class
// The Action that causes the AI to escape from the level and despawn

class EscapeAction extends FleeAction;
///////////////////////////////////////////////////////////////////////////////

import enum EnemySkill from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private EscapePoint					EscapeDestination;

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

	ResetFullBodyAnimations();
}

///////////////////////////////////////////////////////////////////////////////
// 
// Selection Heuristic

// returns true if we find a escape destination
private function bool FindEscapeDestination()
{
	EscapeDestination = FindEscapePointDestination();

	return (EscapeDestination != None);
}

function float selectionHeuristic( AI_Goal goal )
{
	// if we don't have a pawn yet, set it
	if (m_Pawn == None)
	{
		m_Pawn = AI_CharacterResource(goal.resource).m_pawn;
		assert(m_Pawn != None);
	}

	if (FindEscapeDestination())
	{
		return 1.0;
	}
	
	return 0.0;
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

private function EscapePoint FindEscapePointDestination()
{
    local SwatAIRepository SwatAIRepo;
    local EscapePoint Destination, Iter;
    local NavigationPointList AllEscapePoints, ExcludesEscapePoints;
    local int i;
	local Pawn CurrentEnemy;

	local array<EscapePoint> PossibleDestinations;

    SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

    // we exclude the escape points that are in the room we're in
    ExcludesEscapePoints = SwatAIRepo.GetRoomNavigationPointsOfType(m_Pawn.GetRoomName(), 'EscapePoint');
    AllEscapePoints = SwatAIRepo.FindAllOfNavigationPointClass(class'EscapePoint', ExcludesEscapePoints);

	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

    // go through each point and find the closest
    for(i=0; i<AllEscapePoints.GetSize(); ++i)
    {
        Iter = EscapePoint(AllEscapePoints.GetEntryAt(i));
		
        if ((CurrentEnemy == None) || !CurrentEnemy.IsInRoom(Iter.GetRoomName(CurrentEnemy)))
        {
			PossibleDestinations[PossibleDestinations.Length] = Iter;
        }
    }

	// all done with the excludes list
	SwatAIRepo.ReleaseNavigationPointList(ExcludesEscapePoints);
	SwatAIRepo.ReleaseNavigationPointList(AllEscapePoints);

	if (PossibleDestinations.Length > 0)
		Destination = PossibleDestinations[Rand(PossibleDestinations.Length)];

    return Destination;
}

latent function Escape()
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

	assert(EscapeDestination != None);

    CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, EscapeDestination);
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

    Escape();
    
	// let the commander know to clean up after this particular behavior
	ISwatEnemy(m_Pawn).GetEnemyCommanderAction().FinishedMovingEngageBehavior();

	if (VSize(m_Pawn.Location - EscapeDestination.Location) < 100 || ISwatEnemy(m_Pawn).EnteredFleeSafeguard())
	{
		ISwatAICharacter(m_Pawn).OnEscaped();


		// prevent this AI form doing anything else (should act likes it dead without actually dying)
		ISwatEnemy(m_Pawn).GetEnemyCommanderAction().DisableAI();
	}

    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'EngageOfficerGoal'
}