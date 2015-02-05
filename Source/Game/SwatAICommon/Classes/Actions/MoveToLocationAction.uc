///////////////////////////////////////////////////////////////////////////////

class MoveToLocationAction extends MoveToActionBase;

///////////////////////////////////////////////////////////////////////////////

function vector GetDestination()
{
	assert(MoveToLocationGoal(achievingGoal) != none);
	return MoveToLocationGoal(achievingGoal).GetDestination();
}

protected function bool IsInPosition()
{
	local bool bIsInPosition;

	SetOverriddenMoveToThreshold();
	bIsInPosition = m_Pawn.ReachedLocation(GetDestination());
	ResetOverriddenMoveToThreshold();

	return bIsInPosition;
}

///////////////////////////////////////////////////////////////////////////////

protected function SetDistanceSensorParameters()
{
	if (WalkThresholdTarget == None)
	{
		DistanceSensor.SetIgnoreHeightDistance(true);

		DistanceSensor.setParameters( WalkThreshold, MoveToLocationGoal(achievingGoal).GetDestination(), ShouldUseNavigationDistanceOnSensor() );
	}
	else
	{
		DistanceSensor.setParameters( WalkThreshold, WalkThresholdTarget, ShouldUseNavigationDistanceOnSensor());
	}
}

///////////////////////////////////////////////////////////////////////////////

latent function MoveToLocation()
{
    local bool succeeded;
    local vector destination;
	local Actor currentDestination;
	local bool bCloseFromLeft;

    destination = GetDestination();

    DropToGround();

    succeeded = false;

    // Perform movement
    while (! ShouldStopMoving())
    {
        // If goal is reachable, move toward that.
        // Otherwise, find a path toward it
        if (m_pawn.IsLocationReachable(destination))
        {
			// clear out the route cache because we aren't using pathfinding
			m_pawn.ClearRouteCache();

            m_pawn.controller.destination = destination;

			// set the route goal point manually because we aren't using pathfinding
			m_pawn.Controller.RouteGoal      = None;
			m_pawn.Controller.RouteGoalPoint = destination;

            // rotate towards the destination (determined in function whether we need to)
            RotateTowardsMovementPoint(destination);

            MoveTowardLocation(m_pawn.controller.destination);

			// If we allow MoveToward to fail, OR
			//  If we have reached our destination
			if (bAllowDirectMoveFailure || IsInPosition())
			{
				succeeded = true;
				break;
			}
        }
        else
        {
            currentDestination = FindPathToLocation(destination, bAcceptNearbyPath);
            if (currentDestination != none)
            {
				m_pawn.controller.moveTarget = currentDestination;

                // rotate towards the move target (determined in function whether we need to)
                RotateTowardsMovementActor(currentDestination);

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

					if (Door(currentDestination).IsClosed() && !Door(currentDestination).IsOpening() && !ISwatDoor(CurrentDestination).IsBroken())
					{
						yield();
						continue;
					}
				}

				assert(m_pawn.controller.moveTarget == currentDestination);

                MoveTowardActor(m_pawn.controller.moveTarget);

				assert(m_pawn.controller.moveTarget != None);
				assert(m_pawn.controller.moveTarget == currentDestination);

				// close the door if we should
				if (ShouldCloseDoor(currentDestination))
				{
					PostCloseDoorGoal(Door(currentDestination), bCloseFromLeft);
				}

				if (HasReachedNearbyPath(currentDestination))
				{
					succeeded = true;
					break;
				}	
            }
            else
            {
                break;
            }
        }
    }

	if (ShouldStopMoving())
	{
		succeeded = true;
	}

    ReportMoveToOutcome(succeeded);
}

///////////////////////////////////////

state Running
{
Begin:
    MoveToLocation();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	satisfiesGoal = class'MoveToLocationGoal'
}

///////////////////////////////////////////////////////////////////////////////
