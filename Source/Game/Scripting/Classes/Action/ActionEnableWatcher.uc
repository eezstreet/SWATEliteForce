class ActionEnableWatcher extends ActionSetWatcherEnabled;

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Enable watcher " $ propertyDisplayString('scriptName') $ "." $ propertyDisplayString('watcherName');
}

defaultproperties
{
	enabled				= true
	actionDisplayName	= "Enable Watcher"
	actionHelp			= "Enables a watcher in a given script"
	category			= "Watch"
}