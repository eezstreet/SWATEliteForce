class ActionPropertyTest extends ActionBool
	collapsecategories
	native;

var() name label;
var() actionnoresolve class<Actor> actorClass;
var() actionnoresolve string propertyPath;
var() string value;
var() int maxPasses "The number of actors with a matching label that must pass the test (-1 means all)";

var private transient actionnoresolve Object testProperty;
var private transient actionnoresolve Array<int> offsets;

var() actionnoresolve enum EOpTest
{
	OPTEST_LESS,
	OPTEST_LESSEQUAL,
	OPTEST_EQUALS,
	OPTEST_NOTEQUAL,
	OPTEST_GREATEREQUAL,
	OPTEST_GREATER
} opTest;

// execute
latent function Variable execute()
{
	local VariableBool retVar;
	retVar = new class'VariableBool';

	Super.execute();

	if (testProperty == None)
		findTestProperty();

	retVar.value = doPropertyTest();

	return retVar;
}

function editorDisplayString(out string s)
{
	if (maxPasses != -1)
		s = maxPasses $ " ";
	else
		s = "all ";

	s = s $ label $ "." $ propertyPath $ " " $ getOperatorText() $ " " $ value;
}

function String getOperatorText()
{
	switch (opTest)
	{
	case OPTEST_LESS:			return "<"; break;
	case OPTEST_LESSEQUAL:		return "<="; break;
	case OPTEST_EQUALS:			return "=="; break;
	case OPTEST_NOTEQUAL:		return "!="; break;
	case OPTEST_GREATEREQUAL:	return ">="; break;
	case OPTEST_GREATER:		return ">"; break;
	}
}

native private function findTestProperty();
native private function bool doPropertyTest();

defaultproperties
{
	maxPasses			= -1
	actionDisplayName	= "Test Property"
	actionHelp			= "Returns true if the property passes the operator test against value"
	category			= "Watch"
}