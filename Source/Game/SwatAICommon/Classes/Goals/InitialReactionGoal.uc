///////////////////////////////////////////////////////////////////////////////
// InitialReactionGoal.uc - InitialReactionGoal class
// The goal that causes the AI to react to initially encountering an opponent (basically plays an animation)

class InitialReactionGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

var(parameters) Pawn StimuliPawn;	

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct( AI_Resource r, Pawn inStimuliPawn )
{
	super.construct( r );

	assert(inStimuliPawn != None);
	StimuliPawn = inStimuliPawn;
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority         = 60
    goalName         = "InitialReaction"
}