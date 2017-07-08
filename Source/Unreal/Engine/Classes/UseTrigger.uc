//=============================================================================
// UseTrigger: if a player stands within proximity of this trigger, and hits Use, 
// it will send Trigger/UnTrigger to actors whose names match 'EventName'.
//=============================================================================
class UseTrigger extends Triggers;

var() localized string Message;

function UsedBy( Pawn user )
{
	TriggerEvent(Event, self, user);
}

function Touch( Actor Other )
{
	if( (Message != "") && (Other.Instigator != None) )
		// Send a string message to the toucher.
		Other.Instigator.ClientMessage( Message );
}