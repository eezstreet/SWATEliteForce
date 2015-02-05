///////////////////////////////////////////////////////////////////////////////
// GassedAction.uc - FlashbangedActionclass
// The Action that causes an AI to react to being Gassed

class GassedAction extends StunnedAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

// overridden from StunnedAction
function TriggerStunnedSpeech()
{
	ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerGassedSpeech();
}

protected function UnTriggerStunnedSpeech()
{
	m_Pawn.BroadcastUnTriggerEffectEvent('ReactedGas', m_Pawn.Tag);
}

// because the gassed speech is looping, we don't retrigger it
protected function bool ShouldReTriggerStunnedSpeech()
{
	return false;
}

protected function float GetMoraleModificationAmount()
{
	return ISwatAI(m_Pawn).GetCommanderAction().GetGassedMoraleModification();
}

function bool ShouldAffectMoraleAgain()
{
	// the gassed behavior does not affect morale again
	return false;
}

protected function AddAdditionalStunnedTime(float AdditionalStunnedTime)
{
	// gassed adds the duration to the current time (not cumulative)
	EndTime = Level.TimeSeconds + AdditionalStunnedTime;
}

function name GetReactionAnimation()
{
	return ISwatAI(m_Pawn).GetGasReactionAnimation();
}

function name GetAffectedAnimation()
{
	return ISwatAI(m_Pawn).GetGasAffectedAnimation();
}

function name GetRecoveryAnimation()
{
	return ISwatAI(m_Pawn).GetGasRecoveryAnimation();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'GassedGoal'
}