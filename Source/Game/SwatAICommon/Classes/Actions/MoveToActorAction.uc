///////////////////////////////////////////////////////////////////////////////

class MoveToActorAction extends MoveToActionBase;

///////////////////////////////////////////////////////////////////////////////

var protected bool bSucceeded;

///////////////////////////////////////////////////////////////////////////////

function Actor GetDestinationActor()
{
	assert(MoveToActorGoal(achievingGoal) != none);
    return MoveToActorGoal(achievingGoal).GetDestinationActor();
}

function vector GetDestination()
{
	assert(MoveToActorGoal(achievingGoal) != none);
	return MoveToActorGoal(achievingGoal).GetDestination();
}

protected function bool IsInPosition()
{
	local bool bIsInPosition;

	SetOverriddenMoveToThreshold();
	bIsInPosition = m_Pawn.ReachedDestination(GetDestinationActor());
	ResetOverriddenMoveToThreshold();

	return bIsInPosition;
}

///////////////////////////////////////////////////////////////////////////////

protected function SetDistanceSensorParameters()
{
	if (WalkThresholdTarget == None)
	{
		WalkThresholdTarget = GetDestinationActor();
	}

	if (WalkThresholdTarget != None)
	{
		DistanceSensor.setParameters( WalkThreshold, WalkThresholdTarget, ShouldUseNavigationDistanceOnSensor() );
	}
}

///////////////////////////////////////////////////////////////////////////////

latent function MoveToActor()
{
    local Actor destination;
	local Actor currentDestination;
	local bool bCloseFromLeft;

    // Perform santity checks and cache variables we'll need

    destination = GetDestinationActor();

    if (destination != none)
    {
        DropToGround();

        // Perform movement
        while (! ShouldStopMoving()
                //tcohen 9-13-2004: the destination could have been destroyed while we were dropping to ground
                && destination != none
                )
        {
            // If goal is reachable, move toward that.
            // Otherwise, find a path toward it
            if (m_pawn.IsActorReachable(destination))
            {
                // clear out the route cache because we aren't using pathfinding
                m_pawn.ClearRouteCache();

				// set the route goal manually because we aren't using pathfinding
				m_pawn.Controller.RouteGoal      = destination;
				m_pawn.Controller.RouteGoalPoint = vect(0,0,0);

                SetOverriddenMoveToThreshold();
                currentDestination = destination;
            }
            else
            {
                currentDestination = FindPathToActor(destination, bAcceptNearbyPath);
            }

            if (currentDestination != None)
            {
                m_pawn.controller.moveTarget = currentDestination;

//				log("moveTarget is: " $ m_pawn.controller.moveTarget.Name);

                // rotate towards the move target (determined in function whether we need to)
                RotateTowardsMovementActor(currentDestination);

                //tcohen 9-13-2004: the currentDestination could have been destroyed while we were rotating towards it
                if (currentDestination == None)
                    break;

                // open sesame
                if (currentDestination.IsA('Door'))
                {
                    // save off which side to close door from (the opposite side from where we are now)
                    // in case we move to the door but aren't yet on the left or right side
                    // (because of the inaccuracies of movement)
                    bCloseFromLeft = ! ISwatDoor(currentDestination).PointIsToMyLeft(m_Pawn.Location);

                    if (m_Pawn.logTyrion)
                        log(m_Pawn.Name $ " calling NavigateThroughDoor - bCloseFromLeft is: " $ bCloseFromLeft);

                    NavigateThroughDoor(Door(currentDestination));

                    // in case it changed
                    m_pawn.controller.moveTarget = currentDestination;

                    if (Door(currentDestination).IsClosed() && !Door(currentDestination).IsOpening() /*&& !ISwatDoor(CurrentDestination).IsBroken()*/)
                    {
                        yield();
                        continue;
                    }
                }

                assert(m_pawn.controller.moveTarget == currentDestination);

                // now move towards the move target
//				log(m_Pawn.Name $ " calling MoveTowardActor to " $ currentDestination);
                MoveTowardActor(m_pawn.controller.moveTarget);
//				log(m_Pawn.Name $ " finished MoveTowardActor");

                //tcohen 9-13-2004: the currentDestination could have been destroyed while we were moving towards it
                if (currentDestination == None)
                    break;

                assert(m_pawn.controller.moveTarget != None);
                assert(m_pawn.controller.moveTarget == currentDestination);

                // close the door if we should
                if (ShouldCloseDoor(currentDestination))
                {
                    PostCloseDoorGoal(Door(currentDestination), bCloseFromLeft);

                    // in case it changed
                    m_pawn.controller.moveTarget = currentDestination;
                }

                assert(m_pawn.controller.moveTarget != None);

                // If we allow MoveToward to fail, OR
                //  If we just moved to our goal, and we reached our destination, break out
                if (bAllowDirectMoveFailure || HasReachedNearbyPath(currentDestination) || IsInPosition())
                {
                    bSucceeded = true;
                }

                ResetOverriddenMoveToThreshold();

                if (bSucceeded)
                    break;
            }
            else    //currentDestination == None
            {
                break;
            }
        }   //while (! ShouldStopMoving())
    }   //if (destination != none)

	if (!bSucceeded && ShouldStopMoving())
	{
		bSucceeded = true;
	}
}

///////////////////////////////////////

state Running
{
Begin:
    bSucceeded = false;

    MoveToActor();
    ReportMoveToOutcome(bSucceeded);
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'MoveToActorGoal'
}

///////////////////////////////////////////////////////////////////////////////
