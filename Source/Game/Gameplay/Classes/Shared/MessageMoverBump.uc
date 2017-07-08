class MessageMoverBump extends MessageMover
	editinlinenew;

var() Name bumperLabel;

// construct
overloaded function construct(Name _moverLabel, Name _bumperLabel)
{
	moverLabel = _moverLabel;
	bumperLabel = _bumperLabel;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "Mover "$triggeredBy$" is bumped";
}