///////////////////////////////////////////////////////////////////////////////
// AimSweepAction.uc - AimAroundAction class
// Causes the AI to aim between a number of points, then completes

class AimBetweenPointsAction extends SwatWeaponAction;
///////////////////////////////////////////////////////////////////////////////

const MinPauseTime = 0.2;
const MaxPauseTime = 1.0;

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function AimBetweenPoints()
{
    local int i, TotalPoints;
    local vector CurrentPoint;

    TotalPoints = AimBetweenPointsGoal(achievingGoal).GetNumberOfPoints();

    for(i=0; i<TotalPoints; ++i)
    {
        CurrentPoint = AimBetweenPointsGoal(achievingGoal).GetPoint(i);
        AimAndHoldAtPoint(CurrentPoint, MinPauseTime, MaxPauseTime);
    }
}

state Running
{
 Begin:
    AimBetweenPoints();
    succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal=class'AimBetweenPointsGoal'
}