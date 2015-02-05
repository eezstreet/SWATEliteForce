class ActionGetIsLocked extends Scripting.Action;

var() editcombotype(enumScriptLabels)	    Name	Door;
//var() editcombotype(enumObjectProperties)	Name	property;

// execute
latent function Variable execute()
{
	local SwatDoor d;
	local string val;
	local class<Variable> bestClass;

	Super.execute();

	d = SwatDoor(findByLabel(class'SwatDoor', Door));
	if (d == None)
	{
		logError("door "$door$" not found");
	}
	else
	{
		val = string(d.IsLocked());
		class'Variable'.static.bestVariableClass(val, bestClass);
		return newTemporaryVariable(bestClass, val);
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Get Door IsLocked";
}

// editcombotype list fill functions
// enumScriptLabelList
event function enumScriptLabels(Engine.LevelInfo level, out Array<Name> s)
{
	local SwatDoor d;
	
	ForEach level.AllActors(class'SwatDoor', d)
	{
		if (d.label != d.name && d.label != '')
		{
			s[s.Length] = d.label;
		}
	}
}

defaultproperties
{
	returnType			= class'Variable'
	actionDisplayName	= "Get Door IsLocked"
	actionHelp			= "Returns true if the specified Door is locked, and false otherwise"
	category			= "Door"
}
