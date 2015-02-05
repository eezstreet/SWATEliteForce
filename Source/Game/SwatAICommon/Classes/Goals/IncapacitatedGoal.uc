///////////////////////////////////////////////////////////////////////////////
// IncapacitatedGoal.uc - IncapacitatedGoal class
// The goal that causes the AI to be incapacitated

class IncapacitatedGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied to our action
var(parameters) name			IncapaciatedIdleCategoryOverride;
var(parameters) bool			bIsInstantIncapacitation;

///////////////////////////////////////////////////////////////////////////////
//
// Overloaded Constructor

overloaded function construct( AI_Resource r, bool bInIsInstantIncapacitation, optional name inIncapaciatedIdleCategoryOverride )
{
	super.construct( r, priority );

	IncapaciatedIdleCategoryOverride = inIncapaciatedIdleCategoryOverride;
	bIsInstantIncapacitation = bInIsInstantIncapacitation;
}


///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 100
	goalName = "Incapacitated"
}