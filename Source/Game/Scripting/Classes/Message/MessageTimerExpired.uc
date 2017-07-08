class MessageTimerExpired extends Engine.Message;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The timer for " $ triggeredBy $ " expires";
}


defaultproperties
{
	specificTo	= class'Script'
}