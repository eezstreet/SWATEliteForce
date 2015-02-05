class TruthStatement  extends ActionBool
	collapsecategories;

var() name value;

// execute
latent function Variable execute()
{
	local Variable valueVar;
	local VariableBool returnVar;

	Super.execute();

	valueVar = makeVariable(string(value));

	returnVar = VariableBool(newTemporaryVariable(class'VariableBool'));
	returnVar.value = valueVar.truth();

	return returnVar;
}

function editorDisplayString(out string s)
{
	s = propertyDisplayString('value');
}

defaultproperties
{
	actionDisplayName	= "Truth Statement"
	actionHelp			= "Returns value evaluated as a boolean"
	category			= "Logic"
}