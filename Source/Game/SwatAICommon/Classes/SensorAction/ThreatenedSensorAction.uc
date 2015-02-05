///////////////////////////////////////////////////////////////////////////////
//
class ThreatenedSensorAction extends Tyrion.AI_SensorCharacterAction;
///////////////////////////////////////////////////////////////////////////////

const kUpdateTime = 1.0;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var ThreatenedSensor ThreatenedSensor;

///////////////////////////////////////////////////////////////////////////////
// 
// Initialization / Cleanup

function setupSensors( AI_Resource resource )
{
	ThreatenedSensor = ThreatenedSensor(addSensorClass( class'ThreatenedSensor' ));
}

function cleanup()
{
	super.cleanup();

	if (ThreatenedSensor != None)
	{
		ThreatenedSensor = None;
	}
}


///////////////////////////////////////////////////////////////////////////////
// 
// Threat

function UpdateThreatFrom(Pawn ThreateningPawn)
{
	// if the other actor is a threat, they are aiming at us, and we don't already have another threat
	if (ISwatAI(m_Pawn).IsOtherActorAThreat(ThreateningPawn) &&
		class'SwatWeaponAction'.static.IsAThreatBasedOnAim(ThreateningPawn, m_Pawn))
	{
		// if the threatening pawn is a swat enemy and not a threat, he is now
		if (ThreateningPawn.IsA('SwatEnemy') && !ISwatEnemy(ThreateningPawn).IsAThreat())
		{
			ISwatEnemy(ThreateningPawn).BecomeAThreat();
		}

		// if we're being threatened by someone for the first time or by someone new
		if (ThreatenedSensor.ThreatenedBy != ThreateningPawn)
		{
			// notify our sensor that we are now being threatened
			ThreatenedSensor.NotifyThreatened(ThreateningPawn);

			// if we're not already testing whether our threat is still threatening us
			if (isIdle())
			{
				runAction();
			}
		}
	}
}

function bool IsThreatened()
{
	return class'Pawn'.static.checkConscious(ThreatenedSensor.ThreatenedBy);
}

///////////////////////////////////////////////////////////////////////////////
// 
// State Code

state Running
{
 Begin:
	assert(m_Pawn != None);

//	log(self $ " is running for " $ m_Pawn.Name);

	// while the threatening pawn is alive and someone is interested in the sensor's value
	// not compliant, arrested, or incapacitated,
	// and is threatening the our member pawn
	while (class'Pawn'.static.checkConscious(ThreatenedSensor.ThreatenedBy) && (ThreatenedSensor.queryUsage() > 0) &&
			ISwatAI(m_Pawn).IsOtherActorAThreat(ThreatenedSensor.ThreatenedBy) &&
			class'SwatWeaponAction'.static.IsAThreatBasedOnAim(ThreatenedSensor.ThreatenedBy, m_Pawn))
	{
		// do nothing
//		log(Name $ " is polling");
		yield();
	}

	// if we got out of the above loop, than we are no longer threatened, let the sensor know
	ThreatenedSensor.NotifyNoLongerThreatened();	

	// wait until it's time to start again, we'll be notified
	pause();

//	log(self $ " is paused for " $ m_Pawn.Name);
	goto('Begin');
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
}