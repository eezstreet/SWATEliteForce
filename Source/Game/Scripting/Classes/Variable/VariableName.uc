class VariableName extends Variable;

var Name value;


// add
function add(string rhs)
{
	// TBD when name to string coerce implemented
	value = Name(string(value) $ rhs);
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
	// invalid comparison?! should this be fixed?
	return false;
}

// lessEqual
function bool lessEqual(string rhs)
{
	// invalid comparison
	return false;
}

// equal
function bool equal(string rhs)
{
	return string(value) == rhs;
}

// notEqual
function bool notEqual(string rhs)
{
	return string(value) != rhs;
}

// greaterEqual
function bool greaterEqual(string rhs)
{
	// invalid comparison
	return false;
}

// greater
function bool greater(string rhs)
{
	// invalid comparison
	return false;
}

// and
function bool and(string rhs)
{
	return value != '' && Name(rhs) != '';
}

// or
function bool or(string rhs)
{
	return value != '' || Name(rhs) != '';
}

// not
function bool not()
{
	return value == '';
}

// truth
function bool truth()
{
	return value != '';
}