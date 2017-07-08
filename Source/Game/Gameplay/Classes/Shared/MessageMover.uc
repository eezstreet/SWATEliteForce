class MessageMover extends Engine.Message
	abstract;

var Name moverLabel;


// construct
overloaded function construct(Name _moverLabel)
{
	moverLabel = _moverLabel;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "Any mover message from "$triggeredBy;
}


defaultproperties
{
	specificTo	= class'Mover';
}