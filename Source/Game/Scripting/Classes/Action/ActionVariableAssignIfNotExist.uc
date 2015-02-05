class ActionVariableAssignIfNotExist extends Action;

var() actionnoresolve Name lhs;
var() String rhs;


// execute
latent function Variable execute()
{
	local Variable vLhs;
	local class<Variable> newClass;

	Super.execute();

	vLhs = tryFindVariable(lhs);
	if (vLhs == None)
	{
		// If variable not found, create new Variable based on the type of the rhs
		
		if (InStr(lhs, ".") != -1) // can't create variables in other scripts
		{
			logError("You can only create variables that reside within the current script (variable "$lhs$" not found)");
			return None;
		}

		class'Variable'.static.bestVariableClass(rhs, newClass);
		vLhs = newVariable(lhs, newClass);

		// only assign if variable was just created
		vLhs.SetPropertyText("value", rhs);
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = propertyDisplayString('lhs') $ " = " $ propertyDisplayString('rhs') $ " (if not exist)";
}

defaultproperties
{
	returnType			= None
	actionDisplayName	= "Assign (If Not Exist)"
	actionHelp			= "Assigns one variable to another, but only if the variable did not exist and had to be created."
	category			= "Variable"
	acceptAllTypes		= true
}