class ActionVariableSubtract extends Action;

var() actionnoresolve Name lhs;
var() String rhs;


// execute
latent function Variable execute()
{
	local Variable vLhs, result;

	Super.execute();

	vLhs = findVariable(lhs);
	if (vLhs == None)
	{
		logError("lhs of an arithmetic operation must be a variable");
		return None;
	}

	result = newTemporaryVariable(vLhs.class, vLhs.GetPropertyText("value"));
	result.subtract(rhs);

	return result;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = propertyDisplayString('lhs') $ " - " $ propertyDisplayString('rhs');
}

defaultproperties
{
	returnType			= class'Variable'
	actionDisplayName	= "Subtraction"
	actionHelp			= "Returns the result of the subtraction of one variable from another"
	category			= "Variable"
}