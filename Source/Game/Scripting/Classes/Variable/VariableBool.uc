class VariableBool extends Variable;

var bool value;


// add
function add(string rhs)
{
}

// subtract
function subtract(string rhs)
{
}

// multiply
function multiply(string rhs)
{
}

// divide
function divide(string rhs)
{
}

// less
function bool less(string rhs)
{
	return false;
}

// lessEqual
function bool lessEqual(string rhs)
{
	return false;
}

// equal
function bool equal(string rhs)
{
	return value == bool(rhs);
}

// notEqual
function bool notEqual(string rhs)
{
	return value != bool(rhs);
}

// greaterEqual
function bool greaterEqual(string rhs)
{
	return false;
}

// greater
function bool greater(string rhs)
{
	return false;
}

// and
function bool and(string rhs)
{
	return value && bool(rhs);
}

// or
function bool or(string rhs)
{
	return value || bool(rhs);
}

// not
function bool not()
{
	return !value;
}

// truth
function bool truth()
{
	return value;
}