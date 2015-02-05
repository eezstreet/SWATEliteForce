///////////////////////////////////////////////////////////////////////////////
// StackUpGoal.uc - StackUpGoal class
// this goal is given to those Officers when they stack up

class StackUpGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// StackUpGoal variables

// copied to our action automatically
var(Parameters) StackupPoint StackUpPoint;
var(Parameters) bool		 bRunToStackupPoint;


///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, StackupPoint inStackUpPoint )
{
    Super.construct(r);

    assert(inStackUpPoint != None);
    StackUpPoint = inStackUpPoint;
}


function SetStackUpPoint(StackUpPoint NewStackUpPoint)
{
	assert(NewStackUpPoint != None);
	assert(achievingAction != None);		// IF THIS DOESN'T WORK, just set StackUpPoint to the new one

	StackUpAction(achievingAction).SetStackUpPoint(NewStackUpPoint);
}

function SetRunToStackupPoint(bool inRunToStackupPoint)
{
	bRunToStackupPoint = inRunToStackupPoint;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority   = 75
    goalName   = "StackUp"
}