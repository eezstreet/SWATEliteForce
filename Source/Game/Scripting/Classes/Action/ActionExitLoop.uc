class ActionExitLoop extends Action;

// execute
latent function Variable execute()
{
	Super.execute();

	parentScript.exitLoop();

	return None;
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Exit Loop"
	actionHelp			= "Ends execution of the current loop. Does nothing if no loop is running"
	category			= "Script"
}