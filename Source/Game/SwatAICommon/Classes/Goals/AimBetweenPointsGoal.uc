///////////////////////////////////////////////////////////////////////////////
// AimBetweenPointsGoal.uc - AimBetweenPointsGoal class
// The goal that causes the AI to aim at defined points from its current location

class AimBetweenPointsGoal extends SwatWeaponGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// AimBetweenPointsGoal variables
var private array<vector> Points;

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

function int GetNumberOfPoints()
{
    return Points.Length;
}

function vector GetPoint(int Index)
{
    assert(Index >= 0);
    assert(Index < GetNumberOfPoints());

    return Points[Index];
}

function AddPoint(vector Point)
{
    Points[Points.Length] = Point;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    Priority = 50
    GoalName = "AimBetweenPoints"
}

