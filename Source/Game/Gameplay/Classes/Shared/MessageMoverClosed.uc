class MessageMoverClosed extends MessageMover;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "Mover "$triggeredBy$" finished closing";
}