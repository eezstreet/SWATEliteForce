///////////////////////////////////////////////////////////////////////////////
// AvoidLocationAction.uc - AvoidLocationAction class
// The Action that causes an AI to avoid a particular location

class AvoidLocationAction extends SwatCharacterAction;

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private MoveToActorGoal CurrentMoveToActorGoal;

// copied from our goal
var(parameters) vector		AvoidLocation;

const kRunFromLocationMinDistSq  =   40000.0; //  200.0^2
const kRunFromLocationDistSq	 =  640000.0; //  800.0^2

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
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	// calling down the chain should do nothing
	super.goalNotAchievedCB(goal, child, errorCode);

	// if any of our goals fail, we succeed (so we aren't run again)
	instantSucceed();
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function NavigationPoint FindRunToPoint()
{
    // Find the point that has the highest confidence and lowest threat to move to.
    local int i;
    local array<AwarenessProxy.AwarenessKnowledge> PotentiallyVisibleSet;
    local AwarenessProxy.AwarenessKnowledge Knowledge;
    local NavigationPoint NavigationPoint;
    local vector DirectionToAvoidLocation;
    local vector DirectionToNavigationPoint;
    local float DistSq;
    local float Weight;

    local NavigationPoint BestRunToPoint;
    local float BestRunToPointWeight;

    DirectionToAvoidLocation = AvoidLocation - m_Pawn.Location;

    PotentiallyVisibleSet = ISwatAI(m_Pawn).GetAwareness().GetPotentiallyVisibleKnowledge(m_Pawn);

    for (i = 0; i < PotentiallyVisibleSet.Length; ++i)
    {
        Knowledge = PotentiallyVisibleSet[i];
        NavigationPoint = Knowledge.aboutAwarenessPoint.GetClosestNavigationPoint();
        if (NavigationPoint != None)
        {
            DistSq = VDistSquared(m_Pawn.Location, NavigationPoint.Location);
            // If within our desired distance..
            if (DistSq >= kRunFromLocationMinDistSq &&
                DistSq <= kRunFromLocationDistSq)
            {
                // If the dot product of the direction to the point, and the
                // direction to the avoid location is < 0 (this prevents the
                // pawn from running toward the avoid location)..
                DirectionToNavigationPoint = NavigationPoint.Location - m_Pawn.Location;
                if ((DirectionToNavigationPoint dot DirectionToAvoidLocation) < 0.0)
                {
                    // Calculate the weight, based on confidence, threat and distance.
                    // We favor high confidence, low threat points.
                    Weight = Knowledge.confidence - (Knowledge.threat * 2.0);
                    if (Weight > 0.0 && (BestRunToPoint == None || Weight > BestRunToPointWeight))
                    {
                        BestRunToPoint = NavigationPoint;
                        BestRunToPointWeight = Weight;
                    }
                }
            }
        }
    }

    return BestRunToPoint;
}

latent function RunFromAvoidLocation()
{
    local NavigationPoint RunToPoint;

    RunToPoint = FindRunToPoint();
    if (RunToPoint != None)
    {
        CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, FindRunToPoint());
        assert(CurrentMoveToActorGoal != None);
        CurrentMoveToActorGoal.AddRef();

        CurrentMoveToActorGoal.SetAcceptNearbyPath(true);
        CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
        CurrentMoveToActorGoal.SetMoveToThreshold(8.0);
		CurrentMoveToActorGoal.SetWalkThreshold(0.0);

        // post the goal and wait for it to complete
        CurrentMoveToActorGoal.postGoal(self);
        WaitForGoal(CurrentMoveToActorGoal);
        CurrentMoveToActorGoal.unPostGoal(self);

        CurrentMoveToActorGoal.Release();
        CurrentMoveToActorGoal = None;
    }
}

state Running
{
Begin:
	if (! resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
		instantSucceed();

	useResources(class'AI_Resource'.const.RU_ARMS);

    RunFromAvoidLocation();
	
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'AvoidLocationGoal'
}