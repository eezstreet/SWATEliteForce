///////////////////////////////////////////////////////////////////////////////
// StungAction.uc - StungAction
// The Action that causes an AI to react to being stung by the sting grenade

class StungAction extends StunnedAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var(parameters) Actor StingGrenade;

///////////////////////////////////////////////////////////////////////////////
//
// Accessors

// overridden from StunnedAction
function TriggerStunnedSpeech()
{
	// if the sting grenade is none, then we were hit by the less lethal
	// otherwise we were hit by the sting grenade
	if (StingGrenade != None)
	{
		ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerStingSpeech();
	}
	else
	{
		ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerBeanBagSpeech();
	}
}

protected function float GetMoraleModificationAmount()
{
	return ISwatAI(m_Pawn).GetCommanderAction().GetStungMoraleModification();
}

function bool ShouldAffectMoraleAgain()
{
	// the stung behavior does affect morale again
	return true;
}

protected function AddAdditionalStunnedTime(float AdditionalStunnedTime)
{
	// flashbang adds the duration to the current duration (cumulative)
	EndTime += AdditionalStunnedTime;
}

function name GetReactionAnimation()
{
	return ISwatAI(m_Pawn).GetStungReactionAnimation();
}

function name GetAffectedAnimation()
{
	return ISwatAI(m_Pawn).GetStungAffectedAnimation();
}

function name GetRecoveryAnimation()
{
	return ISwatAI(m_Pawn).GetStungRecoveryAnimation();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'StungGoal'
}