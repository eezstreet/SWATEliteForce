///////////////////////////////////////////////////////////////////////////////
// DistanceToOfficersSensor.uc - the DistanceToOfficersSensor class
// a sensor that sends notifications when the AI is within or outside of a certain 
// distance of any of the officers or the player

class DistanceToOfficersSensor extends DistanceSensor;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private bool bRequiresLineOfSight;

///////////////////////////////////////////////////////////////////////////////
//
// Sensor Code

function bool IsWithinRequiredDistance()
{
	local Hive HiveMind;

	HiveMind = SwatAIRepository(sensorAction.m_Pawn.Level.AIRepo).GetHive();
	assert(HiveMind != None);
	assert(sensorAction.m_Pawn != None);

	return HiveMind.IsPawnWithinDistanceOfOfficers(sensorAction.m_Pawn, RequiredDistance, bRequiresLineOfSight);
}

overloaded function setParameters(float inRequiredDistance, bool bInRequiresLineOfSight)
{
	SetUseNavigationDistance(false);
	SetRequiredDistance(inRequiredDistance);

	// change the distance sensor update rate to the 2d rate
	DistanceSensorUpdateRate = kTwoDimensionalUpdateRate;

	// set whether we require line of sight to the officers
	bRequiresLineOfSight = bInRequiresLineOfSight;

	PostSetParameters();
}