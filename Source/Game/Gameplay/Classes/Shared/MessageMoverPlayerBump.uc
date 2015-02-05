class MessageMoverPlayerBump extends MessageMover
	editinlinenew;

var() Name playerLabel;


// construct
overloaded function construct(Name _moverLabel, Name _playerLabel)
{
	moverLabel = _moverLabel;
	playerLabel = _playerLabel;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The player bumps mover "$triggeredBy;
}