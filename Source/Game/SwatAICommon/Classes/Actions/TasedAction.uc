///////////////////////////////////////////////////////////////////////////////
// TasedAction.uc - TasedAction class
// The Action that causes an AI to react to being tased

class TasedAction extends StunnedAction;
///////////////////////////////////////////////////////////////////////////////

// when we're affected, we want to be able to comply, so this priority must be less than the compliance goal
const kPostAffectedGoalPriority = 95;

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

// overridden from StunnedAction
function TriggerStunnedSpeech()
{
	ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerTasedSpeech();
}

protected function float GetMoraleModificationAmount()
{
	return ISwatAI(m_Pawn).GetCommanderAction().GetTasedMoraleModification();
}

protected function float GetEmpathyModifierForCharacter(ISwatAICharacter target)
{
	return Target.GetTaserEmpathy();
}

function bool ShouldAffectMoraleAgain()
{
	// the Tased behavior does not affect morale again
	return false;
}

protected function AddAdditionalStunnedTime(float AdditionalStunnedTime)
{
	// being Tased adds the duration to the current time (not cumulative)
	EndTime = Level.TimeSeconds + AdditionalStunnedTime;
}

// with the taser we don't delay our reaction
protected function bool ShouldDelayReaction()
{
	return false;
}

function name GetReactionAnimation()
{
	return ISwatAI(m_Pawn).GetTasedReactionAnimation();
}

function name GetAffectedAnimation()
{
	return ISwatAI(m_Pawn).GetTasedAffectedAnimation();
}

function name GetRecoveryAnimation()
{
	return ISwatAI(m_Pawn).GetTasedRecoveryAnimation();
}

// when we are finished being affected, we are crouched and we change our goal priority to allow us to comply while recovering
protected latent function NotifyFinishedAffectedAnimation()
{
	if (achievingGoal.priority != kPostAffectedGoalPriority)
	{
		achievingGoal.changePriority(kPostAffectedGoalPriority);
		clearDummyGoals();
		useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'TasedGoal'
}
