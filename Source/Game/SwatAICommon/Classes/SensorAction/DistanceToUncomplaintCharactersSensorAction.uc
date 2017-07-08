///////////////////////////////////////////////////////////////////////////////
// DistanceToUncomplaintCharactersSensorAction.uc - the DistanceToUncomplaintCharactersSensorAction class
// works in parallel with the DistanceToUncomplaintCharactersSensor to determine if any AI is within
// within a particular distance of an uncompliant AI

class DistanceToUncomplaintCharactersSensorAction extends DistanceSensorAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Initialization

function setupSensors( AI_Resource resource )
{
	DistanceSensor = DistanceSensor(addSensorClass( class'DistanceToUncomplaintCharactersSensor' ));
}
