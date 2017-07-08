class ActionRandomNumber extends Action;

var() float minimum;
var() float maximum;

// execute
latent function Variable execute()
{
	local int forceWholeNumber;

	Super.execute();

	forceWholeNumber = (FRand() * (maximum - minimum) + minimum) + 0.5;

	return newTemporaryVariable(class'VariableFloat', string(forceWholeNumber));
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = "A random number between " $ propertyDisplayString('minimum') $ " and " $ propertyDisplayString('maximum');
}

defaultproperties
{
	minimum				= 0.0
	maximum				= 1.0

	returnType			= class'Variable'
	actionDisplayName	= "Random Number"
	actionHelp			= "Generates a random number within a given range"
	category			= "Variable"
}