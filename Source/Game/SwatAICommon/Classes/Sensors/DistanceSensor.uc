///////////////////////////////////////////////////////////////////////////////
// DistanceSensor.uc - the DistanceSensor class
// a sensor that sends notifications when the AI is within or outside of a certain 
// distance of another actor or point

class DistanceSensor extends Tyrion.AI_Sensor;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var Actor	TargetActor;
var vector	TargetLocation;
var float	RequiredDistance;
var bool	bWithinRequiredDistance;
var bool	bInitialTest;
var bool	bUseNavigationDistance;
var bool	bIgnoreHeightDistance;
var float   CollisionHeightMultiplier;

var float	DistanceSensorUpdateRate;


const kTwoDimensionalUpdateRate  = 0.0;		// every tick
const kPathfindingUpdateRate     = 0.25;	// every 1/4 of a second
const kMinDistanceForPathfinding = 150.0;

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Action Notifications

function NotifyWithinRequiredDistance()
{
	if (! bWithinRequiredDistance || bInitialTest)
	{
		bWithinRequiredDistance = true;
		bInitialTest            = false;
		SetWithinSensorValue();
	}
}

function NotifyOutsideRequiredDistance()
{
	if (bWithinRequiredDistance || bInitialTest)
	{
		bWithinRequiredDistance = false;
		bInitialTest            = false;
		SetOutsideSensorValue();
	}
}

protected function SetWithinSensorValue()
{
	setIntegerValue( 1 );
}

protected function SetOutsideSensorValue()
{
	setIntegerValue( 0 );
}

delegate UpdateTarget();

function ResetRequiredDistance(float inNewRequiredDistance)
{
	if (RequiredDistance != inNewRequiredDistance)
	{
		RequiredDistance = inNewRequiredDistance;
		bInitialTest     = true;
	}
}

function ResetTargetActor(Actor inNewTargetActor)
{
	// we don't handle the inNewTargetActor being None.
	// we probably could, but I don't think it's necessary yet.
	assert(inNewTargetActor != None);		

	if (TargetActor != inNewTargetActor)
	{
		TargetActor  = inNewTargetActor;
		bInitialTest = true;
	}
}

function vector GetTargetOrigin()
{
	if (TargetActor != None)
	{
		return TargetActor.Location;
	}
	else
	{
		return TargetLocation;
	}
}

function bool IsWithinRequiredDistance()
{
	local float Distance2D, Distance, HeightDifference;
	local vector TargetOrigin;

	TargetOrigin     = GetTargetOrigin();
	Distance2D       = VSize2D(TargetOrigin - sensorAction.m_Pawn.Location);
	HeightDifference = abs(TargetOrigin.Z - sensorAction.m_Pawn.Location.Z);

	if (bUseNavigationDistance && 
		((Distance2D > kMinDistanceForPathfinding) ||
		 (bIgnoreHeightDistance || (HeightDifference > (CollisionHeightMultiplier * sensorAction.m_Pawn.CollisionHeight)))))
	{
		if (TargetActor != None)
		{
			Distance = sensorAction.m_Pawn.GetPathfindingDistanceToActor(TargetActor, true);
		}
		else
		{
			if (sensorAction.m_Pawn.FastTrace(TargetLocation, sensorAction.m_Pawn.Location))
			{
				Distance = VSize(TargetLocation - sensorAction.m_Pawn.Location);
			}
			else
			{
				Distance = sensorAction.m_Pawn.GetPathfindingDistanceToPoint(TargetLocation, true);
			}
		}

		// change the distance sensor update rate to the pathfinding rate
		DistanceSensorUpdateRate = kPathfindingUpdateRate;

		return (Distance < RequiredDistance);
	}
	else
	{
		// change the distance sensor update rate to the 2d rate
		DistanceSensorUpdateRate = kTwoDimensionalUpdateRate;

		return ((Distance2D <= RequiredDistance) && (bIgnoreHeightDistance || (HeightDifference < (CollisionHeightMultiplier * sensorAction.m_Pawn.CollisionHeight))));
	}
}

function SetRequiredDistance(float inRequiredDistance)
{
	assert(inRequiredDistance >= 0.0);
	RequiredDistance = inRequiredDistance;
}

function SetUseNavigationDistance(bool inUseNavigationDistance)
{
	bUseNavigationDistance = inUseNavigationDistance;
}

function SetIgnoreHeightDistance(bool inIgnoreHeightDistance)
{
	bIgnoreHeightDistance = inIgnoreHeightDistance;
}

function SetCollisionHeightMultiplier(float NewCollisionHeightMultiplier)
{
	assert(NewCollisionHeightMultiplier > 0.0);

	CollisionHeightMultiplier = NewCollisionHeightMultiplier;
}

// Initialize set the sensor's parameters
// 'target': the pawn this sensor is interested in
overloaded function setParameters( float inRequiredDistance, Actor inTargetActor, optional bool inUseNavigationDistance )
{
	SetUseNavigationDistance(inUseNavigationDistance);
	SetRequiredDistance(inRequiredDistance);
	
	assert(inTargetActor != None);
	TargetActor = inTargetActor;

	PostSetParameters();
}

overloaded function setParameters( float inRequiredDistance, vector inTargetLocation, optional bool inUseNavigationDistance)
{
	SetUseNavigationDistance(inUseNavigationDistance);
	SetRequiredDistance(inRequiredDistance);

	TargetLocation = inTargetLocation;

	PostSetParameters();
}

// code shared between overloaded setParameters goes in here
protected function PostSetParameters()
{
	// only activate if distance is greater than 0.0
	if (RequiredDistance > 0.0)
	{
		// start the sensor!
		assert(sensorAction != None);
		assert(sensorAction.IsA('DistanceSensorAction'));

		if (sensorAction.m_Pawn.logTyrion)
			log(sensorAction.Name $ " told to run by " $ name $ " RequiredDistance is: " $ RequiredDistance);

		bInitialTest = true;

		if (sensorAction.isIdle())
			sensorAction.runAction();
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	CollisionHeightMultiplier=1.0
}