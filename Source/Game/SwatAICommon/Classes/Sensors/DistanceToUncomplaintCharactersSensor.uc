///////////////////////////////////////////////////////////////////////////////
// DistanceToUncomplaintCharactersSensor.uc - the DistanceToUncomplaintCharactersSensor class
// a sensor that sends notifications when the AI is within or outside of a certain 
// distance of any uncompliant character

class DistanceToUncomplaintCharactersSensor extends DistanceSensor;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables
var private Pawn ClosestUncompliantCharacter;

const kDistanceToUncompliantUpdateRate = 0.1;

///////////////////////////////////////////////////////////////////////////////

function bool IsWithinRequiredDistance()
{
	local Pawn OurPawn;
	local float DistanceToCharacter;

	OurPawn = sensorAction.m_Pawn;
	assert(OurPawn != None);

	ClosestUncompliantCharacter = SwatAIRepository(OurPawn.Level.AIRepo).GetClosestUncompliantViewableAIInRoom(OurPawn.GetRoomName(), OurPawn, 'SwatAICharacter');
	
	if (ClosestUncompliantCharacter != None)
	{
		DistanceToCharacter = VSize(ClosestUncompliantCharacter.Location - OurPawn.Location);
		
//		if (DistanceToCharacter < RequiredDistance)
//			log("DistanceToCharacter is: " $ DistanceToCharacter);

		return (DistanceToCharacter < RequiredDistance);
	}
	else
	{
		return false;
	}
}

protected function SetWithinSensorValue()
{
	setObjectValue( ClosestUncompliantCharacter );
}

protected function SetOutsideSensorValue()
{
	setObjectValue( None );
}

overloaded function setParameters( float inRequiredDistance)
{
	SetUseNavigationDistance(false);
	SetRequiredDistance(inRequiredDistance);

	DistanceSensorUpdateRate = kDistanceToUncompliantUpdateRate;

	PostSetParameters();
}