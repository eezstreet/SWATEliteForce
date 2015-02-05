///////////////////////////////////////////////////////////////////////////////
// CowerAction.uc - CowerAction class
// Action class that causes a Hostage to cower because he/she is scared

class CowerAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// config variables
var config array<name>		CrouchedInitialCowerAnimations;

var config array<name>		StandingInitialCowerAnimations;

///////////////////////////////////////////////////////////////////////////////
//
// State code

function name GetInitialCowerAnimation()
{
	if (m_Pawn.bIsCrouched)
	{
		return CrouchedInitialCowerAnimations[Rand(CrouchedInitialCowerAnimations.Length)];
	}
	else
	{
		return StandingInitialCowerAnimations[Rand(StandingInitialCowerAnimations.Length)];
	}
}

latent function PlayCowerAnimation()
{
	local int IdleChannel;
	local name InitialCowerAnimation;
	
	// Play the animation and wait for it to finish
	if (InitialCowerAnimation != '')
	{
		IdleChannel = m_Pawn.AnimPlaySpecial(GetInitialCowerAnimation(), 0.2);    
		m_Pawn.FinishAnim(IdleChannel);
	}
    
	ISwatAI(m_Pawn).SetIdleCategory('Cower');
}


state Running
{
 Begin:
	while (! resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
		yield();

	useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);

	PlayCowerAnimation();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'CowerGoal'
}
