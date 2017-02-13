///////////////////////////////////////////////////////////////////////////////
// PatrolAction.uc - PatrolAction class
// The Action that causes the AI to patrol along designer specified routes

class PatrolAction extends SwatCharacterAction
    dependson(PatrolList);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private MoveToActorGoal				CurrentMoveToActorGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;
var private int							CurrentPatrolIndex;

// copied from our goal
var(parameters) PatrolList	Patrol;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

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

	m_Pawn.ChangeAnimation();

	// reset any setting of the idle category
	ISwatAI(m_Pawn).SetIdleCategory('');
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  failing.");

	// just fail
	InstantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveToPatrolDestination()
{
    local PatrolPoint Destination;

    Destination = Patrol.GetPatrolEntry(CurrentPatrolIndex).PatrolPoint;
    assert(Destination != None);

    CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, Destination);
    assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsFirstPoint(true);
	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToActorGoal.SetShouldWalkEntireMove(true);
	CurrentMoveToActorGoal.SetShouldCloseOpenedDoors(true);
	CurrentMoveToActorGoal.SetShouldNotCloseInitiallyOpenDoors(true);

    // post the move to goal and wait for it to complete
    CurrentMoveToActorGoal.postGoal(self);
    WaitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

latent function RotateToPatrolPointRotation(PatrolPoint PatrolPoint)
{
	assert(PatrolPoint != None);

	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, PatrolPoint.Rotation);
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

latent function IdleAtPatrolPoint()
{
	local float PatrolPointIdleTime;
	local PatrolList.PatrolEntry CurrentPatrolEntry;

	CurrentPatrolEntry = Patrol.GetPatrolEntry(CurrentPatrolIndex);

	// sleep (idle) for a bit based on the patrol entry's min and max idle time
	PatrolPointIdleTime = RandRange(CurrentPatrolEntry.IdleTime.Min, CurrentPatrolEntry.IdleTime.Max);

	if (PatrolPointIdleTime > 0.0)
	{
		// rotate to the position
		RotateToPatrolPointRotation(CurrentPatrolEntry.PatrolPoint);

		useResources(class'AI_Resource'.const.RU_LEGS);

		// set the idle category
		ISwatAI(m_Pawn).SetIdleCategory(CurrentPatrolEntry.IdleCategory);

		// wait for the current idle to finish
		m_Pawn.FinishAnim();

		// and sleep
		sleep(PatrolPointIdleTime);

		// reset the idle category
		ISwatAI(m_Pawn).SetIdleCategory('');

		clearDummyMovementGoal();
	}
}

function bool ShouldWander() {
  return ISwatAICharacter(m_Pawn).Wanders();
}

function int PickRandomPatrolIndex(int Previous) {
  local int Index;

  Index = int(RandRange(0, Patrol.GetNumPatrolEntries()));

  // If we've hit the same patrol index, try again until we find one that isn't the same
  /*if(Index == Previous) {
    return PickRandomPatrolIndex(Previous);
  }*/

  return Index;
}

function int PickNextSequentialPatrolIndex(int Previous) {
  local int Index;

  Index = Previous++;

  // Start over if we reach the end
  if(Index == Patrol.GetNumPatrolEntries()) {
    Index = 0;
  }

  return 0;
}

function UpdatePatrolIndex()
{
    if(ShouldWander()) {
      CurrentPatrolIndex = PickRandomPatrolIndex(CurrentPatrolIndex);
    } else {
      CurrentPatrolIndex = PickNextSequentialPatrolIndex(CurrentPatrolIndex);
    }
}

state Running
{
Begin:
	while (! resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
		yield();

	// use the dummy arms so we get interrupted
	useResources(class'AI_Resource'.const.RU_ARMS);

//    log(self@" running at time"@Level.TimeSeconds);
    CurrentPatrolIndex = 0;
    goto('Patrolling');

Patrolling:
    MoveToPatrolDestination();

    if ((FRand() * 100) <= Patrol.GetPatrolEntry(CurrentPatrolIndex).IdleChance)
    {
		IdleAtPatrolPoint();
    }

    UpdatePatrolIndex();
    goto('Patrolling');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'PatrolGoal'
}
