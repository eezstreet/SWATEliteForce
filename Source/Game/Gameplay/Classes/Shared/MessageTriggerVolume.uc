class MessageTriggerVolume extends Engine.Message
	editinlinenew;

var Name TriggerVolume;
var() Name instigator;


// construct
overloaded function construct(Name _triggerVolume, Name _instigator)
{
	TriggerVolume = _triggerVolume;
	instigator = _instigator;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "Any TriggerVolume message from "$triggeredBy;
}


defaultproperties
{
	specificTo	= class'TriggerVolume'
}
