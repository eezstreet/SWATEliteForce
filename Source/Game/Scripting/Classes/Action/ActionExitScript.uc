class ActionExitScript extends Action;

var() editcombotype(enumScripts) Name targetScript;

// execute
latent function Variable execute()
{
	local Script s;

	Super.execute();

	ForEach parentScript.actorLabel(class'Script', s, targetScript)
	{
		s.exit();
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Exit script " $ propertyDisplayString('targetScript');
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Exit Script"
	actionHelp			= "Ends execution of a script"
	category			= "Script"
}