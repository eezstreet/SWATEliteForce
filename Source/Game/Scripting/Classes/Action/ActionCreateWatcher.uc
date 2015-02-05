class ActionCreateWatcher extends Action
	collapsecategories;

var() deepcopy actionnoresolve editinline WatcherBase newWatcher;

// execute
latent function Variable execute()
{
	Super.execute();

	if (newWatcher != None)
	{
		if (newWatcher.enabled)
			newWatcher.GotoState('LookAtExpression');

		parentScript.addWatcher(newWatcher);
	}
	else
	{
		logError("Tried to create an empty watcher");
	}

	return None;
}

function editorDisplayString(out string s)
{
	local string watcherDisplay;
	local string watcherName;

	watcherDisplay = "Do Nothing";
	watcherName = "Nothing";

	if (newWatcher != None)
	{
		newWatcher.editorDisplayString(watcherDisplay);
		watcherName = string(newWatcher.watcherName);
	}

	s = "Create watcher '" $ watcherName $ "' to: " $ watcherDisplay;
}

defaultproperties
{
	actionDisplayName	= "Create a new watcher"
	actionHelp			= "Creates a new watcher and puts it in the scripts watcher list"
	category			= "Watch"
}