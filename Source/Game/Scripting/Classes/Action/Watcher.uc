class Watcher extends WatcherBase
	collapsecategories;

var() bool watchedExpression;

// execute
latent function Variable execute()
{
	if (!enabled)
		return None;

	Super.execute();

	if (watchedExpression)
	{
		enabled = false;
		parentScript.dispatchMessage(new class'MessageWatcher'(parentScript.Label, watcherName));
	}

	return None;
}

function editorDisplayString(out string s)
{
	s = "Send a watch message when " $ propertyDisplayString('watchedExpression') $ " is true";
}

state LookAtExpression
{
begin:
	while (enabled)
	{
		Sleep(1);
		execute();
	}
}

defaultproperties
{
	actionDisplayName	= "Watcher"
	actionHelp			= "Sends a watcher message if the watched expression is true"
	category			= "Watch"
}