class ActionStartTimer extends Action;

var() float seconds;

// execute
latent function Variable execute()
{
	Super.execute();

	parentScript.SetTimer(seconds, false);

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Start timer for " $ propertyDisplayString('seconds') $ " second";

	if (seconds != 1.0)
		s = s $ "s";
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Start Timer"
	actionHelp			= "Starts a timer that will send a timer expired message after n seconds."
	category			= "Script"
}