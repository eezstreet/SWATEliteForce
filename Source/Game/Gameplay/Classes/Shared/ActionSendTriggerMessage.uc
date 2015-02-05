class ActionSendTriggerMessage extends Scripting.Action;

var() Name	instigator;


// construct
overloaded function construct()
{
	super.construct();

	instigator = parentScript.label;
}

// execute
latent function Variable execute()
{
	parentScript.dispatchMessage( new class'MessageTrigger'(parentScript.label, instigator) );

	return None;
}


defaultproperties
{
	returnType			= None
	actionDisplayName	= "Send Trigger Message"
	actionHelp			= "Sends a MessageTrigger that can be used to open doors, move movers, etc."
	category			= "Script"
}