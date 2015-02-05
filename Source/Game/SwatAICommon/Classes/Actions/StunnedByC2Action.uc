///////////////////////////////////////////////////////////////////////////////
// StunnedByC2Action.uc - StunnedByC2Action
// The Action that causes an AI to react to being stunned by a c2 detonation

class StunnedByC2Action extends StunnedAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Accessors

// overridden from StunnedAction
function TriggerStunnedSpeech()
{
	ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerStunnedByC2Speech();
}

protected function bool ShouldTriggerStunnedSpeech()
{
	return ! bPlayedReaction;
}

protected function float GetMoraleModificationAmount()
{
	return ISwatAI(m_Pawn).GetCommanderAction().GetStunnedByC2DetonationMoraleModification();
}

function bool ShouldAffectMoraleAgain()
{
	// the stunned by c2 behavior does affect morale again
	return true;
}

protected function AddAdditionalStunnedTime(float AdditionalStunnedTime)
{
	// stunned by c2 adds the duration to the current duration (cumulative)
	EndTime += AdditionalStunnedTime;
}

// @NOTE: the stunned by c2 behavior uses the flashbanged animations [crombie]
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
    satisfiesGoal = class'StunnedByC2Goal'
}