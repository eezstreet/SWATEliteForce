class ActionGetCurrentTime extends Scripting.Action;

// execute
latent function Variable execute()
{
   	return newTemporaryVariable(class'VariableFloat', string(parentScript.Level.TimeSeconds));
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "The current time";
}

defaultproperties
{
	actionDisplayName	= "Get Current Time"
	actionHelp			= "Gets the current time"
	returnType			= class'Scripting.VariableFloat'
	category			= "Script"
}
