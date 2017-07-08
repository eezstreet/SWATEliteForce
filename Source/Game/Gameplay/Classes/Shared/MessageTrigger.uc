class MessageTrigger extends Engine.Message
	editinlinenew;

var Name trigger;
var() Name instigator;


// construct
overloaded function construct(Name _trigger, Name _instigator)
{
	trigger = _trigger;
	instigator = _instigator;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "Any trigger message from "$triggeredBy;
}


defaultproperties
{
	specificTo	= class'Trigger'
}