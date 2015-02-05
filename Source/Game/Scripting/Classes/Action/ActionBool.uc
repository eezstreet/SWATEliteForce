class ActionBool extends Action
	native
	abstract;

// makeVariable
function Variable makeVariable(string val)
{
	local class<Variable> varClass;
	local Variable v;

	class'Variable'.static.bestVariableClass(val, varClass);

   	v = newTemporaryVariable(varClass);
	v.SetPropertyText("value", val);
	
	return v;
}

// editorDisplayString
function editorDisplayString(out string s)
{
}

defaultproperties
{
	returnType			= class'VariableBool'
}