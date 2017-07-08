class MessageLevelStart extends Engine.Message;

var bool UsingCustomScenario;

// construct
overloaded function construct(bool inUsingCustomScenario)
{
    UsingCustomScenario = inUsingCustomScenario;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "The level starts";
}


defaultproperties
{
	specificTo	= class'GameInfo'
}
