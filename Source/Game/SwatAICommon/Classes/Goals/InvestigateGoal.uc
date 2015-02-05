///////////////////////////////////////////////////////////////////////////////
// InvestigateGoal.uc - InvestigateGoal class
// this goal causes the AI to investigate a particular location
// it is usually triggered when an AI hears a sound

class InvestigateGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) vector InvestigateLocation;
var(parameters) bool   bShouldWalkToInvestigate;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct( AI_Resource r, vector inInvestigateLocation, bool bInShouldWalkToInvestigate)
{
	super.construct( r, priority );

	InvestigateLocation = inInvestigateLocation;
	bShouldWalkToInvestigate = bInShouldWalkToInvestigate;
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority   = 60
    goalName   = "Investigate"
}