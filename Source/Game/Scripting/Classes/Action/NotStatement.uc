class NotStatement  extends ActionBool
	collapsecategories;

var() bool rhs;

// execute
latent function Variable execute()
{
	local Variable rhsVAR;
	local VariableBool returnVar;

	Super.execute();

	rhsVAR = makeVariable(string(rhs));

	returnVar = VariableBool(newTemporaryVariable(class'VariableBool'));
	returnVar.value = rhsVAR.not();

	return returnVar;
}

function editorDisplayString(out string s)
{
	s = "NOT(" $ propertyDisplayString('lhs') $ ")";
}

defaultproperties
{
	actionDisplayName	= "Not Statement"
	actionHelp			= "Returns the result of a logical not operation"
	category			= "Logic"
}