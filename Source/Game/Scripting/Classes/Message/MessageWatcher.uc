class MessageWatcher extends Engine.Message
	editinlinenew;

var Name scriptName;
var() Name watcherName;

// construct
overloaded function construct(Name _scriptName, Name _watcherName)
{
	scriptName = _scriptName;
	watcherName = _watcherName;
}

// editorDisplay
static function string editorDisplay(Name triggeredBy, Message filter)
{
	return "A watcher message from " $ triggeredBy;
}


defaultproperties
{
	specificTo	= class'Script'
}