///////////////////////////////////////////////////////////////////////////////
// BarricadeGoal.uc - BarricadeGoal class
// this goal causes the AI to find a random flee point in the room it is currently 
// in, and tells the AI to move to that point, when the barricade is finished, the
// AI is told to watch a particular door

class BarricadeGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) vector	StimuliOrigin;
var(parameters) bool	bDelayBarricade;
var(parameters) bool	bCanCloseDoors;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct(AI_Resource r, vector inStimuliOrigin, bool bInDelayBarricade, bool bInCanCloseDoors)
{
	super.construct( r, priority );

	StimuliOrigin   = inStimuliOrigin;
	bDelayBarricade = bInDelayBarricade;
	bCanCloseDoors  = bInCanCloseDoors;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority   = 60
    goalName   = "Barricade"
}