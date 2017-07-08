class MessageMissionEnded extends Engine.Message
	editinlinenew;

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The Mission has Ended.";
}


defaultproperties
{
	specificTo = class'PlayerController'
}
