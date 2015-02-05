///////////////////////////////////////////////////////////////////////////////

class MoveToGoalBase extends Tyrion.AI_MovementGoal implements IMoveToInformation
	abstract;

///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) bool	bShouldCrouch;
var(parameters) float	MoveToThreshold;
var(parameters) bool	bRotateTowardsFirstPoint;
var(parameters) bool	bRotateTowardsPointsDuringMovement;
var(parameters) bool	bAcceptNearbyPath;
var(parameters) bool	bShouldCloseOpenedDoors;
var(parameters) bool	bShouldNotCloseInitiallyOpenDoors;
var(parameters) bool	bAllowDirectMoveFailure;
var(parameters) bool	bUseCoveredPaths;
var(parameters) bool	bOpenDoorsFrantically;
var(parameters) bool	bUseNavigationDistanceOnSensor;
var(parameters) bool	bShouldSucceedWhenDestinationBlocked;
var(parameters) float	WalkThreshold;
var(parameters) Actor	WalkThresholdTarget;

// just in the goal (used in a delegate)
var	private bool bShouldWalkEntireMove;
var private bool bShouldWalk;


///////////////////////////////////////////////////////////////////////////////
//
// Constructor

overloaded function Construct(AI_Resource r, int pri)
{
	super.Construct(r);
    priority = pri;
}

///////////////////////////////////////////////////////////////////////////////
//
// Delegate

// the action will call this to see if it should stop moving
delegate bool ShouldStopMovingDelegate(Pawn MovingPawn) 
{ 
	return false; 
}

delegate bool ShouldWalkDelegate()
{
	return bShouldWalk;
}

function bool ShouldWalkEntireMove()
{
	return bShouldWalkEntireMove;
}

///////////////////////////////////////////////////////////////////////////////
//
// Manipulators
function SetRotateTowardsFirstPoint(bool bInRotateTowardsFirstPoint)
{
	bRotateTowardsFirstPoint = bInRotateTowardsFirstPoint;
}

function SetRotateTowardsPointsDuringMovement(bool bInRotateTowardsPointsDuringMovement)
{
	bRotateTowardsPointsDuringMovement = bInRotateTowardsPointsDuringMovement;
}

function SetAcceptNearbyPath(bool bInAcceptNearbyPath)
{
	bAcceptNearbyPath = bInAcceptNearbyPath;
}

function SetShouldCloseOpenedDoors(bool bInShouldCloseOpenedDoors)
{
	bShouldCloseOpenedDoors = bInShouldCloseOpenedDoors;
}

function SetShouldNotCloseInitiallyOpenDoors(bool bInShouldNotCloseInitiallyOpenDoors)
{
	bShouldNotCloseInitiallyOpenDoors = bInShouldNotCloseInitiallyOpenDoors;
}

function SetAllowDirectMoveFailure(bool bInAllowDirectMoveFailure)
{	
	bAllowDirectMoveFailure = bInAllowDirectMoveFailure;
}

function SetShouldCrouch(bool bInShouldCrouch)
{
	bShouldCrouch = bInShouldCrouch;
}

function SetMoveToThreshold(float inMoveToThreshold)
{
	assertWithDescription((inMoveToThreshold > 0.0), "MoveToGoalBase::SetMoveToThreshold - inMoveToThreshold ("$inMoveToThreshold$") must be greater than 0.0!");
	MoveToThreshold = inMoveToThreshold;
}

function SetUseCoveredPaths()
{
	bUseCoveredPaths = true;
}

function SetOpenDoorsFrantically(bool bInOpenDoorsFrantically)
{
	bOpenDoorsFrantically = bInOpenDoorsFrantically;
}

function SetWalkThreshold(float inWalkThreshold)
{
	assert(inWalkThreshold >= 0.0);

	WalkThreshold = inWalkThreshold;
}

function SetWalkThresholdTarget(Actor inTarget)
{
	assert(inTarget != None);

	WalkThresholdTarget = inTarget;
}

function SetShouldWalkEntireMove(bool bInShouldWalkEntireMove)
{
	bShouldWalkEntireMove = bInShouldWalkEntireMove;
	bShouldWalk           = bInShouldWalkEntireMove;
}

function SetShouldWalk(bool bInShouldWalk)
{
	// only allow others to change how we move if we haven't put a lock on walking
	if (! bShouldWalkEntireMove)
	{
		bShouldWalk = bInShouldWalk;
	}
}

function SetUseNavigationDistanceOnSensor(bool inUseNavigationDistanceOnSensor)
{
	bUseNavigationDistanceOnSensor = inUseNavigationDistanceOnSensor;
}

function SetShouldSucceedWhenDestinationBlocked(bool inShouldSucceedWhenDestinationBlocked)
{
	bShouldSucceedWhenDestinationBlocked = inShouldSucceedWhenDestinationBlocked;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	WalkThreshold=64.0
}