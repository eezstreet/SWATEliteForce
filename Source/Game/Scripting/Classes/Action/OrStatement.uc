class OrStatement  extends ActionBool
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
	returnVar.value = lhsVAR.or(string(rhs));

	return returnVar;
}

function editorDisplayString(out string s)
{
	s = "(" $ propertyDisplayString('lhs')  $ ") OR (" $ propertyDisplayString('rhs') $ ")";
}

defaultproperties
{
	actionDisplayName	= "Or Statement"
	actionHelp			= "Returns the result of a logical or operation"
	category			= "Logic"
}