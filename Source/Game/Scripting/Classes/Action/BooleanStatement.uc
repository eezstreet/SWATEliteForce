class BooleanStatement extends ActionBool
	collapsecategories;

var() enum ELogicOp
{
	LOGICOP_LESS,
	LOGICOP_LESSEQUAL,
	LOGICOP_EQUALS,
	LOGICOP_NOTEQUAL,
	LOGICOP_GREATEREQUAL,
	LOGICOP_GREATER
} logicOp;

var() name lhs;
var() name rhs;

// execute
latent function Variable execute()
{
	local Variable lhsVAR, returnVar;
	local bool b;

	Super.execute();

	lhsVAR = tryFindVariable(lhs);
	if (lhsVAR == None)
		lhsVAR = makeVariable(string(lhs));

	switch (logicOp)
	{
	case LOGICOP_LESS:			b = lhsVAR.less(string(rhs)); break;
	case LOGICOP_LESSEQUAL:		b = lhsVAR.lessEqual(string(rhs)); break;
	case LOGICOP_EQUALS:		b = lhsVAR.equal(string(rhs)); break;
	case LOGICOP_NOTEQUAL:		b = lhsVAR.notEqual(string(rhs)); break;
	case LOGICOP_GREATEREQUAL:	b = lhsVAR.greaterEqual(string(rhs)); break;
	case LOGICOP_GREATER:		b = lhsVAR.greater(string(rhs)); break;
	}

	returnVar = newTemporaryVariable(class'VariableBool');
	returnVar.SetPropertyText("value", string(b));

	return returnVar;
}

// logicOpDisplayString
function string logicOpDisplayString()
{
	switch (logicOp)
	{
	case LOGICOP_LESS:			return "<"; break;
	case LOGICOP_LESSEQUAL:		return "<="; break;
	case LOGICOP_EQUALS:		return "=="; break;
	case LOGICOP_NOTEQUAL:		return "!="; break;
	case LOGICOP_GREATEREQUAL:	return ">="; break;
	case LOGICOP_GREATER:		return ">"; break;
	}
}

// editorDisplayString
function editorDisplayString(out string s)
{
	s = propertyDisplayString('lhs') $ " " $ logicOpDisplayString() $ " " $ propertyDisplayString('rhs');
}

defaultproperties
{
	logicOp				= LOGICOP_EQUALS
	
	actionDisplayName	= "Boolean Statement"
	actionHelp			= "Returns the result of a logical evaluation"
	category			= "Logic"
}