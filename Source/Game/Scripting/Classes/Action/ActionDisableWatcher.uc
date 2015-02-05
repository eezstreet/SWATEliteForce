class ActionDisableWatcher extends ActionSetWatcherEnabled;

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Disable watcher " $ propertyDisplayString('scriptName') $ "." $ propertyDisplayString('watcherName');
}

defaultproperties
{
	enabled				= false
	actionDisplayName	= "Disable Watcher"
	actionHelp			= "Disables a watcher in a given script"
	category			= "Watch"
}