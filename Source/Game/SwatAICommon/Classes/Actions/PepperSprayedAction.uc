///////////////////////////////////////////////////////////////////////////////
// PepperSprayedAction.uc - PepperSprayedAction class
// The Action that causes an AI to react to being pepper sprayed

class PepperSprayedAction extends StunnedAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Accessors

// overridden from StunnedAction
function TriggerStunnedSpeech()
{
	ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerPepperSprayedSpeech();
}

protected function float GetMoraleModificationAmount()
{
	return ISwatAI(m_Pawn).GetCommanderAction().GetPepperSprayedMoraleModification();
}

protected function float GetEmpathyModifierForCharacter(ISwatAICharacter target)
{
	return Target.GetPepperSprayEmpathy();
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

// with the pepper spray we don't delay our reaction
// pepper spray now takes some time to take effect like it does in real life
protected function bool ShouldDelayReaction()
{
	return true;
}

// TODO: figure out if we need pepper sprayed animations
// Shawn says that we should use the gas reaction animations
// and see how it plays
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
    satisfiesGoal = class'PepperSprayedGoal'
}
