class ActionExecuteScript extends Action
	abstract;

var() editcombotype(enumScripts) Name targetScript;

var bool block;

// execute
latent function Variable execute()
{
	local Script scriptToExecute;

	Super.execute();

	scriptToExecute = Script(findByLabel(class'Script', targetScript));

	if (scriptToExecute != None)
	{
		scriptToExecute.executeScriptFromScriptAction(block);
	}
	else
	{
		logError("Could find script " $ targetScript $ " to execute");
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	if (block)
		s = "Blocking";
	else
		s = "Non-blocking";

	s = s $ " execute script " $ propertyDisplayString('targetScript');
}

defaultproperties
{
	category			= "Script"
}