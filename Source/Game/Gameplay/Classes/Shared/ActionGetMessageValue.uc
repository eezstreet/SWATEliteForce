class ActionGetMessageValue extends Scripting.Action;

var() editcombotype(messageProperties) Name property;

// messageProperties
function messageProperties(Engine.LevelInfo level, out Array<Name> s)
{
	local Name propName;

	if (parentScript.messageClass == None)
	{
		logError("This script does not have a message class set for it");
		return;
	}
	
	ForEach AllProperties(parentScript.messageClass, class'Message', propName)
	{
		s[s.Length] = propName;
	}
}

// execute
latent function Variable execute()
{
	local Message currMessage;
	local class<Variable> varClass;
	local Variable v;
	local string val;

	currMessage = parentScript.triggeringMessage();

	if (currMessage == None)
		return None;

	val = currMessage.GetPropertyText(string(property));

	class'Variable'.static.bestVariableClass(val, varClass);

   	v = newTemporaryVariable(varClass);
	v.SetPropertyText("value", val);
	
	return v;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = parentScript.messageClass.Name $ "." $ propertyDisplayString('property');
}

defaultproperties
{
	actionDisplayName	= "Get Message Value"
	actionHelp			= "Gets a value from the message that triggered the script"
	returnType			= class'Variable'
	category			= "Script"
}
