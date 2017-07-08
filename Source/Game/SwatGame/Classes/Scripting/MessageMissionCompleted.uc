class MessageMissionCompleted extends Engine.Message
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The Mission is Completed.";
}


defaultproperties
{
	specificTo = class'PlayerController'
}
