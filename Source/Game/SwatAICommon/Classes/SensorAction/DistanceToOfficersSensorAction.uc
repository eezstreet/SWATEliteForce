///////////////////////////////////////////////////////////////////////////////
// DistanceToOfficersSensorAction.uc - the DistanceSensorAction class
// works in parallel with the DistanceSensor to determine if any of the officers
// are within a particular distance

class DistanceToOfficersSensorAction extends DistanceSensorAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Initialization

function setupSensors( AI_Resource resource )
{
	DistanceSensor = DistanceSensor(addSensorClass( class'DistanceToOfficersSensor' ));
}
