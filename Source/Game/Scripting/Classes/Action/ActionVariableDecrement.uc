class ActionVariableDecrement extends Action;

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

	vTarget.subtract("1");
	result = newTemporaryVariable(vTarget.class, vTarget.GetPropertyText("value"));

	return result;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Decrement " $ propertyDisplayString('target');
}

defaultproperties
{
	returnType			= class'Variable'
	actionDisplayName	= "Decrement"
	actionHelp			= "Subtracts 1 from the variable"
	category			= "Variable"
}