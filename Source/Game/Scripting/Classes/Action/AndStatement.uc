class AndStatement  extends ActionBool
	collapsecategories;

var() bool lhs;
var() bool rhs;

// execute
latent function Variable execute()
{
	local Variable lhsVAR;
	local VariableBool returnVar;

	Super.execute();

	lhsVAR = makeVariable(string(lhs));

	returnVar = VariableBool(newTemporaryVariable(class'VariableBool'));
	returnVar.value = lhsVAR.and(string(rhs));

	return returnVar;
}

function editorDisplayString(out string s)
{
	s = "(" $ propertyDisplayString('lhs')  $ ") AND (" $ propertyDisplayString('rhs') $ ")";
}

defaultproperties
{
	actionDisplayName	= "And Statement"
	actionHelp			= "Returns the result of a logical and operation"
	category			= "Logic"
}