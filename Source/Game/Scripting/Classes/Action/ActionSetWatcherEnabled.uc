class ActionSetWatcherEnabled extends Action
	abstract;

var() editcombotype(enumScripts) Name scriptName;
var() Name watcherName;
var private bool enabled;

latent function Variable execute()
{
	local Script s;

	Super.execute();

	if (scriptName != '')
	{
		ForEach parentScript.actorLabel(class'Script', s, scriptName)
		{
			s.setWatcherEnabled(watcherName, enabled);
		}
	}
	else
	{
		parentScript.setWatcherEnabled(watcherName, enabled);
	}

	return None;
}