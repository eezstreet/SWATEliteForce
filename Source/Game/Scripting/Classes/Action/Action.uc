// Action
//
// All Action paramters should be of type "string". These parameters must be resolved before use.
// On execution of the action, locals of type Variable should be defined (they are 'new'ed in the resolve function)
// "resolve" should then be called, passing each local Variable and its string representation.
// The string is first parsed to attempt to resolve it to an existing script variable by name.
// If a variable is found, then the value from that object is used to create a new variable object. 
// If no variable by the given name exists, then the resolve function attempts to parse the value to a built-in data type.
class Action extends Core.Object
	editinlinenew
	collapsecategories
	hidecategories(object)
	native
	abstract;

import class Engine.Actor;
import class Engine.Pawn;
import class Engine.LevelInfo;

cpptext
{
	virtual void CleanupDestroyed();
}

var string actionDisplayName;
var string actionHelp;
var class<Variable> returnType;
var string category;

var Script parentScript;

// True if this actions properties can accept any return type from a nested action
// used by the assignment actions
var bool acceptAllTypes;

// parameter resolve data
struct native ParameterResolveInfo
{
	var deepcopy Action action;
	var Name variable; 
	var Name propertyName;
};

var private Array<ParameterResolveInfo> resolveInfoList;

// construct
overloaded function construct()
{
	parentScript = Script(Outer);
	assert(parentScript != None);
}

function setParentScript(Script s)
{
	parentScript = s;
}

native final function SetActionPropertyText(string PropName, string PropValue);

// resolveParameters
// Uses the parameterResolveInfo array (previously filled by native UnrealEd code during script creation) to
// set the value of Action or Variable parameters to the run-time return value of an action/variable, if required.
// Call this at the start of your execute function to resolve script variables to Action return values.
private latent function resolveParameters()
{
	local int i;
	local Name propName;
	local Variable v;
	local Array<int> resolveActions;

	ForEach AllProperties(self.Class, class'Action', propName)
	{
		// See if this action property should be set to the value of an action
		for (i = 0; i < resolveInfoList.Length; i++)
		{
			if (resolveInfoList[i].propertyName == propName)
			{
                if (resolveInfoList[i].action != None) // add resolve index to resolve action list
				{
					resolveActions.Length = resolveActions.Length + 1;
					resolveActions[resolveActions.Length - 1] = i;
				}
				else if (resolveInfoList[i].variable != '') // resolve as a variable
				{
					v = tryFindVariable(resolveInfoList[i].variable);

					if (v != None)
					{
						SetActionPropertyText(string(propName), v.GetPropertyText("value"));
					}
				}
				else // empty resolve info
				{
					logError("Parameter "$propName$" has an entry in the resolveinfo map, but has no action or variable resolve target");
				}
			}
		}
	}

	// Execute resolved actions
	for (i = 0; i < resolveActions.Length; ++i)
	{
		v = resolveInfoList[resolveActions[i]].action.execute();

		if (v != None)
		{
			SetActionPropertyText(string(resolveInfoList[resolveActions[i]].propertyName), v.GetPropertyText("value"));
		}
		else
		{
			SetPropertyText(string(resolveInfoList[resolveActions[i]].propertyName), "");
		}
	}
}

// logError
function logError(string reason)
{
	local string s;

	editorDisplayString(s);

	s = "ERROR: "$parentScript.Name$", Action "$s$": "$reason;
	SLog(s);
}

// findByLabel
function Actor findByLabel(class<Actor> actorClass, Name label)
{
	return parentScript.findByLabel(actorClass, label);
}

// findStaticByLabel
function Actor findStaticByLabel(class<Actor> actorClass, Name label)
{
	return parentScript.findStaticByLabel(actorClass, label);
}

// newVariable
// Convenience
function Variable newVariable(Name variableName, class<Variable> variableType)
{
	return parentScript.newVariable(variableName, variableType);
}

// newTemporaryVariable
// Convenience
function Variable newTemporaryVariable(class<Variable> variableType, optional string initValue)
{
	return parentScript.newTemporaryVariable(variableType, initValue);
}

// findVariable
// Convenience
function Variable findVariable(coerce string variableName)
{
	local Variable v;

    v = class'Variable'.static.findVariable(variableName, parentScript);
	if (v == None)
	{
		logError("Variable "$variableName$" not found");
	}

	return v;
}

// tryFindVariable
// Convenience, doesn't log, use for situations where the find can fail without causing an error (i.e. a test for existance)
function Variable tryFindVariable(coerce string variableName)
{
	local Variable v;

    v = class'Variable'.static.findVariable(variableName, parentScript);

	return v;
}

// execute
latent function Variable execute()
{
	resolveParameters();
	return None;
}

// propertyDisplayString
// resolves a property if necessary and determines the appropriate display string for it
function string propertyDisplayString(Name propName)
{
	local string s;
	local int i;

	for (i = 0; i < resolveInfoList.Length; i++)
	{
		if (resolveInfoList[i].propertyName == propName)
		{
			if (resolveInfoList[i].action != None)
			{
				resolveInfoList[i].action.editorDisplayString(s);
				return s;
			}
			else if (resolveInfoList[i].variable != '')
			{
				return string(resolveInfoList[i].variable);
			}
		}
	}

	return GetPropertyText(string(propName));
}

// editorDisplayString
// called by UnrealEd to get a display string
event function editorDisplayString(out string s)
{
	s = actionDisplayName;
}

// editcombotype list fill functions
// enumScriptLabelList
event function enumScriptLabels(Engine.LevelInfo level, out Array<Name> s)
{
	local Actor a;
	
	ForEach level.AllActors(class'Actor', a)
	{
		if (a.label != a.name && a.label != '')
		{
			s[s.Length] = a.label;
		}
	}
}

// enum all scripts with a valid label
event function enumScripts(Engine.LevelInfo level, out Array<Name> s)
{
	local Script aScript;
	
	ForEach level.AllActors(class'Script', aScript)
	{
		if (aScript.label != '')
		{
			s[s.Length] = aScript.label;
		}
	}
}


defaultproperties
{
	returnType			= None
	actionDisplayName	= "<actionDisplayName>"
	actionHelp			= "<actionHelp>"
	category			= "Default Category"
	acceptAllTypes		= false
}