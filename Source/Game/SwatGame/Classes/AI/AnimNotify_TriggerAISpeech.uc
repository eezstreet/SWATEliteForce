class AnimNotify_TriggerAISpeech extends Engine.AnimNotify_Scripted;

var() name SpeechEffectEvent;
var() bool ClearEventQueue;

// just tells the owner to drop its weapon if it is a SwatEnemy
event Notify( Actor Owner )
{
	local bool bEffectEventExists;
	assert(Owner != None);

    if (Owner.IsA('SwatAI'))
    {
		// debug to make sure the effect event exists
		bEffectEventExists = Owner.TriggerEffectEvent(SpeechEffectEvent,,,,,,true);

		if (bEffectEventExists)
		{
			// trigger the actual speech
			SwatAI(Owner).GetSpeechManagerAction().TriggerSpeech(SpeechEffectEvent, ClearEventQueue);
		}
		else
		{
			warn("AnimNotify_TriggerAISpeech - attempt to trigger effect event (" $ SpeechEffectEvent $ ") failed because the effects system has no response available");
		}
    }
}

defaultproperties
{
}
