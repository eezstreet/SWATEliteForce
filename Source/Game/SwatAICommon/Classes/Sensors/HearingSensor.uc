///////////////////////////////////////////////////////////////////////////////
// HearingSensor.uc - the HearingSensor class
// sensor that 

class HearingSensor extends Tyrion.AI_Sensor implements IHearingNotification;
///////////////////////////////////////////////////////////////////////////////

// the delta time between hearing a sound and actually responding to it
const kDeltaHeardTime = 2.5;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var Actor				LastSoundMaker;					// who made the sound
var vector				LastSoundHeardOrigin;			// where the sound was made
var float				LastSoundHeardTime;				// when the sound happened
var Name            	LastSoundHeardCategory;			// what the sound is

///////////////////////////////////////////////////////////////////////////////
//
// Are we going to hear this sound?

function bool WillListenToSound(Name SoundCategory)
{
	return true;
}

///////////////////////////////////////////////////////////////////////////////
//
// IHearingNotification implementation

function OnListenerHeardNoise(Pawn Listener, Actor SoundMaker, vector SoundOrigin, Name SoundCategory)
{
	if (WillListenToSound(SoundCategory))
	{
		LastSoundMaker         = SoundMaker;
		LastSoundHeardTime     = Listener.Level.TimeSeconds;
		LastSoundHeardOrigin   = SoundOrigin;
		LastSoundHeardCategory = SoundCategory;
		
		// just set a value
		setIntegerValue( 1 );
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Initialization / Cleanup

function begin()
{
	ISwatAI(CommonSensorAction(sensorAction).pawn()).RegisterHearingNotification( self );
}

function cleanup()
{
	ISwatAI(CommonSensorAction(sensorAction).pawn()).UnregisterHearingNotification( self );
}

///////////////////////////////////////////////////////////////////////////////
//
// Debug

function DebugHearingSensorToLog()
{
	log(Name $ " current info used by " $ CommonSensorAction(sensorAction).pawn().Name $ " LastSoundMaker: " $ LastSoundMaker $ " LastSoundHeardOrigin: " $ LastSoundHeardOrigin $ " LastSoundHeardTime: " $ LastSoundHeardTime $ " LastSoundHeardCategory: " $ LastSoundHeardCategory);
}
