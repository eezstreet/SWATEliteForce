///////////////////////////////////////////////////////////////////////////////
// ComplianceAction.uc - ComplianceAction class
// The action that causes the AI to be compliant

class ComplianceAction extends LookAtOfficersActionBase
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;
import enum EnemySkill from ISwatEnemy;

///////////////////////////////////////////////////////////////////////////////
//
// Variables


var config array<name>	CrouchingComplianceAnimations;
var config array<name>	StandingComplianceAnimations;

var config array<name>	CrouchingStunnedComplianceAnimations;
var config array<name>	StandingStunnedComplianceAnimations;

var config array<name>	CrouchingArmsUpAnimations;
var config array<name>	StandingArmsUpAnimations;

var config array<name>	CrouchingStunnedArmsUpAnimations;
var config array<name>	StandingStunnedArmsUpAnimations;

var private bool		bJustComplied;

const kPostComplianceGoalPriority = 91;	// lower than being stunned or shot

///////////////////////////////////////////////////////////////////////////////
//
// Init / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
	super.initAction(r, goal);

	// disable upper body animation
    ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_ComplianceAction);

	// see if we've already done this behavior before
	if (! ComplianceGoal(achievingGoal).HasCompliedAlready())
	{
		ComplianceGoal(achievingGoal).SetHasCompliedAlready();

		bJustComplied = true;
	}

	// let the hive know
	SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().NotifyAIBecameCompliant(m_Pawn);

    InitLookAtOfficersActionBase(kUBABCI_ComplianceAction);
}

function cleanup()
{
	super.cleanup();

    ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_ComplianceAction);

	ISwatAI(m_Pawn).AnimStopSpecial();
}

///////////////////////////////////////////////////////////////////////////////
//
// Speech

private function TriggerCompliantSpeech()
{
	ISwatAI(m_Pawn).GetSpeechManagerAction().TriggerCompliantSpeech();
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function name GetComplianceAnimation()
{
	// returns a random animation from the list of compliance animations
	if (m_Pawn.bIsCrouched)
	{		
		if (m_Pawn.IsStunned())
		{
			return CrouchingStunnedComplianceAnimations[Rand(CrouchingStunnedComplianceAnimations.Length)];
		}
		else
		{
			return CrouchingComplianceAnimations[Rand(CrouchingComplianceAnimations.Length)];
		}
	}
	else
	{
		if (m_Pawn.IsStunned())
		{
			return StandingStunnedComplianceAnimations[Rand(StandingStunnedComplianceAnimations.Length)];
		}
		else
		{
			return StandingComplianceAnimations[Rand(StandingComplianceAnimations.Length)];
		}
	}
}

function name GetPreComplyAnimation()
{
	// returns a random pre comply animation (arms up) depending on whether we are crouching or standing
	if (m_Pawn.bIsCrouched)
	{
		if (m_Pawn.IsStunned())
		{
			return CrouchingStunnedArmsUpAnimations[Rand(CrouchingStunnedArmsUpAnimations.Length)];
		}
		else
		{
			return CrouchingArmsUpAnimations[Rand(CrouchingArmsUpAnimations.Length)];
		}
	}
	else
	{
		if (m_Pawn.IsStunned())
		{
			return StandingStunnedArmsUpAnimations[Rand(StandingStunnedArmsUpAnimations.Length)];
		}
		else
		{
			return StandingArmsUpAnimations[Rand(StandingArmsUpAnimations.Length)];
		}
	}
}

// don't override
latent final function PreComply()
{
	local int ComplyAnimChannel;
	local float AnimationRate;
	
	// play the arms up animation
	AnimationRate = RandRange(1.1, 1.6);
	ComplyAnimChannel = m_Pawn.AnimPlaySpecial(GetPreComplyAnimation(), 0.1, '', AnimationRate);
    m_Pawn.FinishAnim(ComplyAnimChannel);

	// play the compliance animation
	AnimationRate = RandRange(1.0, 1.4);
    ComplyAnimChannel = m_Pawn.AnimPlaySpecial(GetComplianceAnimation(), 0, '', AnimationRate);
    m_Pawn.FinishAnim(ComplyAnimChannel);
}

latent final function Comply()
{
    local ISwatAICharacter SwatAICharacter;
	local ISwatEnemy Enemy;

    mplog( "in ComplianceAction::Comply()." );
	
	//give them a chance to drop their weapon BEFORE raising their hands,
	//like a sane person -K.F.
	Enemy = ISwatEnemy(m_Pawn);
	if (Enemy != None) 
	{
		if (Enemy.ShouldDropWeaponInstantly())
		{
			Enemy.DropActiveWeapon();
		}
	}

    if (bJustComplied)
	{
		TriggerCompliantSpeech();
		PreComply();
	}

	// at this point we can be arrested, so let the goal know
	ComplianceGoal(achievingGoal).SetCanBeArrested();

    SwatAICharacter = ISwatAICharacter(m_Pawn);
    if (SwatAICharacter != None)
    {
        SwatAICharacter.SetCanBeArrested(true);
    }

	// makes sure the weapon is dropped if we are an enemy
	if (Enemy != None)
	{
		Enemy.DropAllWeapons();
		Enemy.DropAllEvidence(false);
		// make sure we are not a threat anymore
		if (m_Pawn.IsA('SwatEnemy') && ISwatEnemy(m_Pawn).IsAThreat())
		{
			Enemy.UnbecomeAThreat();
		}
	}
}

state Running
{
 Begin:
	// if we're being restrained, or our resources aren't available, wait.
	while (ISwatAI(m_Pawn).GetCommanderAction().IsRestrainedGoalRunning() ||
		   ! resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
	{
		yield();
	}

	// now use those resources
	useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);

	// only sleep if we just complied and we're not stunned
	if (bJustComplied && !m_Pawn.IsStunned())
		SleepInitialDelayTime(false);

	// swap in the compliance anim. set
	ISwatAI(m_Pawn).SwapInCompliantAnimSet();
	ISwatAI(m_Pawn).SetIdleCategory('Compliant');

    Comply();

	// let the hive know that we're on the ground and have finished animating
	SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().NotifyCompliantAIFinishedComplying(m_Pawn);

	if (achievingGoal.priority != kPostComplianceGoalPriority)
	{
		// set the priority lower now so that any higher priority goal 
		// (incapacitation, stunned, injury) will take over
		achievingGoal.changePriority(kPostComplianceGoalPriority);
		ClearDummyGoals();
		useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);
	}

    LookAtNearbyOfficers();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal=class'ComplianceGoal'
}
