// Variable
// Used for any variable that is user-settable, by constant or Script Variable, within the GUI Scripting System.
class Variable extends Core.Object
	collapsecategories
	hidecategories(object)
	editinlinenew
	native;

import class Engine.LevelInfo;

var Script ownerScript;

overloaded function construct(Script owner)
{
	ownerScript = owner;
}

// logError
static function logError(string rval, string reason)
{
	SLog("ERROR: Could not resolve rval "$rval$", no variable of that name or "$reason);
}

// findVariable
// All variable searches must be qualified with a script name (i.e. OpenDoor01.HasBeenTriggered)
// Does not log errors, use for variable find operations that can fail without causing an error
static function Variable findVariable(coerce String name, Script requestingScript)
{
	local Script s;
	local int dotPos;

	// extract script and variable name
	dotPos = InStr(name, ".");
	if (dotPos == -1)
	{
		// if no dot present in the name, then it's within the current script
		s = requestingScript;
	}
	else
	{
		// find the script object
		s = Script(requestingScript.findByLabel(class'Script', Name(Left(name, dotPos))));
		if (s == None)
		{
			return None;
		}
	}

	return s.findVariable(Name(Mid(name, dotPos + 1)));
}

// nativeClassToVariableClass
static event function nativeClassToVariableClass(string nativeClass, out class<Variable> varClass)
{
	if (nativeClass == "NameProperty")			varClass = class'VariableName';
	else if (nativeClass == "FloatProperty")	varClass = class'VariableFloat';
	else if (nativeClass == "BoolProperty")		varClass = class'VariableBool';
	else										varClass = None;
}

// variableClassToNativeClass
static event function variableClassToNativeClass(class<Variable> varClass, out string nativeClass)
{
	if (varClass == class'VariableName')		nativeClass = "NameProperty";
	else if (varClass == class'VariableFloat')	nativeClass = "FloatProperty";
	else if (varClass == class'VariableBool')	nativeClass = "BoolProperty";
	else										nativeClass = "None";
}

// bestVariableClass
// returns the best Variable class to represent the data in a string
static event function bestVariableClass(string val, out class<Variable> varClass)
{
	local int i, c;

	// if val is 'true' or 'false', make the class a bool
	if (val == "True" || val == "False")
	{
		varClass = class'VariableBool';
		return;
	}

	// if val has no alpha characters, make the class a float
	for (i = 0; i < Len(val); i++)
	{
		c = Asc(Mid(val, i, 1));
		if ((c > Asc("9") || c < Asc("0")) && c != Asc("-") && c != Asc("."))
		{
			break;
		}

		varClass = class'VariableFloat';
		return;
	}

	// everything fits in a name
	varClass = class'VariableName';
}

// Operators
// add
function add(string rhs)
{
}

// subtract
function subtract(string rhs)
{
}

// multiply
function multiply(string rhs)
{
}

// divide
function divide(string rhs)
{
}

// less
function bool less(string rhs)
{
	return false;
}

// lessEqual
function bool lessEqual(string rhs)
{
	return false;
}

// equal
function bool equal(string rhs)
{
	return false;
}

// notEqual
function bool notEqual(string rhs)
{
	return false;
}

// greaterEqual
function bool greaterEqual(string rhs)
{
	return false;
}

// greater
function bool greater(string rhs)
{
	return false;
}

// and
function bool and(string rhs)
{
	return false;
}

// or
function bool or(string rhs)
{
	return false;
}

// not
function bool not()
{
	return false;
}

// truth
function bool truth()
{
	return false;
}