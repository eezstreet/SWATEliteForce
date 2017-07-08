class MessageBombExploded extends Engine.Message
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The bomb timer expires.";
}


defaultproperties
{
	specificTo	= class'SwatGamePlayerController'
}
