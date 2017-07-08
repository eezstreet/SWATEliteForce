class MessageZone extends Message
	editinlinenew;

var Name zone;
var() Name instigator;


// construct
overloaded function construct(Name _zone, Name _instigator)
{
	zone = _zone;
	instigator = _instigator;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "Any zone message from "$triggeredBy;
}


defaultproperties
{
	specificTo	= class'ZoneInfo'
}