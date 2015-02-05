class ActionStopTimer extends Action;

var() name scriptLabel;

// execute
latent function Variable execute()
{
	local Script s;

	Super.execute();

	ForEach parentScript.actorLabel(class'Script', s, scriptLabel)
	{
		s.SetTimer(0.0, false);
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Stop timer for " $ propertyDisplayString('scriptLabel');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Stop Timer"
	actionHelp			= "Stops the timer for all scripts with the given label"
	category			= "Script"
}