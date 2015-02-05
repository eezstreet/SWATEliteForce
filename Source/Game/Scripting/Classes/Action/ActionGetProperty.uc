class ActionGetProperty extends Action;

var() editcombotype(enumScriptLabels)	Name	object;
var() editcombotype(enumObjectProperties)	Name	property;


// execute
latent function Variable execute()
{
	local Actor a;
	local string val;
	local class<Variable> bestClass;

	Super.execute();

	a = findByLabel(class'Actor', object);
	if (a == None)
	{
		logError("object "$object$" not found");
	}
	else
	{
		val = a.GetPropertyText(string(property));
		class'Variable'.static.bestVariableClass(val, bestClass);
		return newTemporaryVariable(bestClass, val);
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Get " $ propertyDisplayString('object') $ "." $ propertyDisplayString('property');
}

// enumObjectProperties
function enumObjectProperties(LevelInfo l, out Array<Name> s)
{
	local Actor a;
	local Name propName;

	a = findByLabel(class'Actor', object);
	if (a != None)
	{
		ForEach AllProperties(a.class, a.class, propName)
			s[s.Length] = propName;

		if (s.Length == 0)
		{
			ForEach AllProperties(a.class, class'Object', propName)
				s[s.Length] = propName;
		}
	}
}


defaultproperties
{
	returnType			= class'Variable'
	actionDisplayName	= "Get Object Property"
	actionHelp			= "Returns the value of a given object's property"
	category			= "Actor"
}