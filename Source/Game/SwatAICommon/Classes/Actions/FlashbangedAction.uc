///////////////////////////////////////////////////////////////////////////////
// FlashbangedAction.uc - FlashbangedActionclass
// The Action that causes an AI to react to being flashbanged

class FlashbangedAction extends StunnedAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Accessors

// overridden from StunnedAction
function TriggerStunnedSpeech()
{
	ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerFlashbangedSpeech();
}

protected function float GetMoraleModificationAmount()
{
	return ISwatAI(m_Pawn).GetCommanderAction().GetFlashbangedMoraleModification();
}

function bool ShouldAffectMoraleAgain()
{
	// the flashbang behavior does affect morale again
	return true;
}

protected function AddAdditionalStunnedTime(float AdditionalStunnedTime)
{
	// flashbang adds the duration to the current duration (cumulative)
	EndTime += AdditionalStunnedTime;
}

function name GetReactionAnimation()
{
	return ISwatAI(m_Pawn).GetFBReactionAnimation();
}

function name GetAffectedAnimation()
{
	return ISwatAI(m_Pawn).GetFBAffectedAnimation();
}

function name GetRecoveryAnimation()
{
	return ISwatAI(m_Pawn).GetFBRecoveryAnimation();
}



///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'FlashbangedGoal'
}