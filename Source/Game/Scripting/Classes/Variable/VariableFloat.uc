class VariableFloat extends Variable;

var float value;


// add
function add(string rhs)
{
	value += float(rhs);
}

// subtract
function subtract(string rhs)
{
	value -= float(rhs);
}

// multiply
function multiply(string rhs)
{
	value *= float(rhs);
}

// divide
function divide(string rhs)
{
	value /= float(rhs);
}

// less
function bool less(string rhs)
{
	return value < float(rhs);
}

// lessEqual
function bool lessEqual(string rhs)
{
	return value <= float(rhs);
}

// equal
function bool equal(string rhs)
{
	return value == float(rhs);
}

// notEqual
function bool notEqual(string rhs)
{
	return value != float(rhs);
}

// greaterEqual
function bool greaterEqual(string rhs)
{
	return value >= float(rhs);
}

// greater
function bool greater(string rhs)
{
	return value > float(rhs);
}

// and
function bool and(string rhs)
{
	return value != 0.0 && float(rhs) != 0.0;
}

// or
function bool or(string rhs)
{
	return value != 0.0 || float(rhs) != 0.0;
}

// not
function bool not()
{
	return value == 0.0;
}

// truth
function bool truth()
{
	return value != 0.0;
}