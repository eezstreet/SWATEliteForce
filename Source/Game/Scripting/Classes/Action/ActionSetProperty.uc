class ActionSetProperty extends Action;

var() editcombotype(enumScriptLabels)		Name	object;
var() editcombotype(enumObjectProperties)	Name	property;
var()										string	newValue;


// execute
latent function Variable execute()
{
	local Actor a;

	Super.execute();

	ForEach parentScript.staticActorLabel(class'Actor', a, object)
	{
		a.SetPropertyText(string(property), newValue);
	}

	return None;
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "Set " $ propertyDisplayString('object') $ "." $ propertyDisplayString('property') $ " = " $ propertyDisplayString('newValue');
}

// enumObjectProperties
function enumObjectProperties(LevelInfo l, out Array<Name> s)
{
	local Actor a;
	local Array<class> classes;
	local class commonBaseClass;
	local Name propName;

	ForEach parentScript.staticActorLabel(class'Actor', a, object)
	{
		classes[classes.length] = a.class;
	}

	commonBaseClass = CommonBase(classes);

	if (commonBaseClass != None)
	{
		ForEach AllProperties(commonBaseClass, class'Object', propName)
			s[s.Length] = propName;
	}
}


defaultproperties
{
	returnType			= None
	actionDisplayName	= "Set Object Property"
	actionHelp			= "Sets a new value for a given object's property"
	category			= "Actor"
}