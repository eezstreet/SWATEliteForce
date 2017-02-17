///////////////////////////////////////////////////////////////////////////////
// MoveOfficerToEngageGoal.uc - MoveOfficerToEngageGoal class
// Goal that we use to move officers to engage enemies and hostage for compliance,
// or to attack enemies

class SWATTakeCoverAndAimGoal extends SWATTakeCoverGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) Pawn Opponent;

///////////////////////////////////////////////////////////////////////////////
//
// Constructor 

overloaded function Construct(AI_Resource r, int pri, Pawn inOpponent)
{
	super.Construct(r, pri);

	assertWithDescription((inOpponent != None), "SWATTakeCoverAndAimGoal::construct - Opponent passed in is None!");
    Opponent = inOpponent;
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    goalName   = "SWATTakeCoverAndAim"
}