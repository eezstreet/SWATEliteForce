class MessageMissionFailed extends Engine.Message
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The Mission is Failed.";
}


defaultproperties
{
	specificTo = class'PlayerController'
}
