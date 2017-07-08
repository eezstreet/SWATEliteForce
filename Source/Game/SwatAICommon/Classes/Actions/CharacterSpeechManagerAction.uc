///////////////////////////////////////////////////////////////////////////////
// CharacterSpeechManagerAction.uc - the CharacterSpeechManagerAction class
// this action is used by characters to organize their speech

class CharacterSpeechManagerAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private array<name> EventQueue;
var private bool		bInterrupted;

///////////////////////////////////////////////////////////////////////////////
//
// Queue

function TriggerSpeech(name SpeechEffectEvent, optional bool bClearEventQueue)
{
	assert(SpeechEffectEvent != '');

//	DebugTriggerSpeech(SpeechEffectEvent, bClearEventQueue);

	// make sure the effect event exists before adding it to the queue
//	if (m_Pawn.TriggerEffectEvent(SpeechEffectEvent,,,,,,true))
//	{
		if (bClearEventQueue)
		{
			ClearEventQueue();
		}

		EventQueue[EventQueue.Length] = SpeechEffectEvent;
	
		if (isIdle())
		{
			runAction();
		}
//	}
}
 
private function function DebugTriggerSpeech(name SpeechEffectEvent, bool bClearEventQueue)
{
	local int i;

	log(m_Pawn.Name $ " DebugTriggerSpeech - SpeechEffectEvent: " $ SpeechEffectEvent $ " bClearEventQueue: " $ bClearEventQueue);

	for(i=0; i<EventQueue.Length; ++i)
	{
		log("EventQueue["$i$"] is: " $ EventQueue[i]);
	}
}

private function ClearEventQueue()
{
	// clear the event queue
	EventQueue.Remove(0, EventQueue.Length);

	// we interrupted the current event
	bInterrupted = true;

	// if we're running stop!
	if (! isIdle())
	{
		m_Pawn.StopWaiting();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Speech Requests

function TriggerCompliantSpeech()
{
	TriggerSpeech('AnnouncedCompliant', true);
}

function TriggerRestrainedSpeech()
{
	TriggerSpeech('AnnouncedRestrained', true);
}

function TriggerHitByDoorSpeech()
{
	TriggerSpeech('ReactedHitByDoor', true);
}

function TriggerIncapacitatedSpeech()
{
	TriggerSpeech('ReactedDown', true);
}

function TriggerDiedSpeech()
{
	TriggerSpeech('Died', true);
}

function TriggerNormalInjuredSpeech()
{
	TriggerSpeech('ReactedInjuryNormal', true);
}

function TriggerIntenseInjuredSpeech()
{
	TriggerSpeech('ReactedInjuryIntense', true);
}

function TriggerGassedSpeech()
{
	TriggerSpeech('ReactedGas', true);
}

function TriggerFlashbangedSpeech()
{
	TriggerSpeech('ReactedBang', true);
}

function TriggerPepperSprayedSpeech()
{
	TriggerSpeech('ReactedPepper', true);
}

function TriggerTasedSpeech()
{
	TriggerSpeech('ReactedTaser', true);
}

function TriggerStunnedByC2Speech()
{
	TriggerSpeech('ReactedBreach', true);
}

function TriggerStingSpeech()
{
	TriggerSpeech('ReactedSting', true);
}

function TriggerBeanBagSpeech()
{
	TriggerSpeech('ReactedBeanBag', true);
}

function TriggerScreamSpeech()
{
	TriggerSpeech('Screamed', true);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

state Running
{
 Begin:
	if (m_Pawn.logTyrion)
		log(Name $ " started at time " $ Level.TimeSeconds);

	// wait until we are told to start playing sounds
	if (EventQueue.Length == 0)
		pause();

	
	while (EventQueue.Length > 0)
	{
//		log("triggering EventQueue[0]: " $ EventQueue[0]);
		bInterrupted = false;
		ISwatAI(m_Pawn).LatentAITriggerEffectEvent(EventQueue[0],,,,,,true);
		
		if (! bInterrupted)
		{
			EventQueue.Remove(0, 1);
		}
	}

	goto('Begin');
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'SpeechManagerGoal'
}