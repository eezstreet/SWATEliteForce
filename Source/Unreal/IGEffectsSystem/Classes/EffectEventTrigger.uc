class EffectEventTrigger extends Engine.Trigger;

var(Events) name EffectEvent;

simulated function DoTrigger(Pawn instigator)
{
    //copied from Actor::TriggerEvent()
    
	local Actor A;

	if ( Event == '' )
		return;

	ForEach DynamicActors( class 'Actor', A, Event )
        A.TriggerEffectEvent(EffectEvent);
}
