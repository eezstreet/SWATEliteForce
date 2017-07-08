
class SwatAIController extends Tyrion.AI_Controller 
    dependsOn(SwatAI)
	native;

///////////////////////////////////////////////////////////////////////////////
//
// Low-Level Hearing Implementation

event OnHearSound(Actor SoundMaker, vector SoundOrigin, Name SoundCategory)
{
	// temporary (probably want to catch this case earlier)
	if (SwatAI(pawn).hearing != None)
		SwatAI(pawn).hearing.OnHearSound(SoundMaker, SoundOrigin, SoundCategory);
}

///////////////////////////////////////////////////////////////////////////////

//=============================================================================

defaultProperties
{
}
