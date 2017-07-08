class ActionVariableIncrement extends Action;

var() actionnoresolve Name target;

// execute
latent function Variable execute()
{
	local Variable vTarget, result;

	Super.execute();

	vTarget = findVariable(target);
	if (vTarget == None)
	{
		logError("Target of the increment operation must be a variable");
		return None;
	}

	vTarget.add("1");
	result = newTemporaryVariable(vTarget.class, vTarget.GetPropertyText("value"));

	return result;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Increment " $ propertyDisplayString('target');
}

defaultproperties
{
	returnType			= class'Variable'
	actionDisplayName	= "Increment"
	actionHelp			= "Adds 1 to the variable"
	category			= "Variable"
}