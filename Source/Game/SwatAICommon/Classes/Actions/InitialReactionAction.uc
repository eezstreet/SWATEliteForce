///////////////////////////////////////////////////////////////////////////////
// InitialReactionAction.uc - the InitialReactionAction class
// The action that causes an Enemy to initially react to seeing Swat (animation)

class InitialReactionAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private InitialReactionDefinition	InitialReaction;

// Copied from our Goal
var(parameters) Pawn					StimuliPawn;

// behaviors we use
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

///////////////////////////////////////////////////////////////////////////////
//
// Cleanup

function cleanup()
{
	super.cleanup();

	// stop animating
	ISwatAI(m_Pawn).AnimStopSpecial();

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}
}


///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  failing.");

	// just fail
	InstantFail(errorCode);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function RotateTowardStimuli()
{
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(StimuliPawn.Location - m_Pawn.Location));
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

latent function PlayInitialReactionAnimation()
{
    local int ReactionAnimationChannel;
	
	assert(m_Pawn != None);

	// get the random initial reaction based on a number of variables (see InitialReactionDefinition, etc.)
	InitialReaction = SwatAIRepository(Level.AIRepo).GetInitialReactions().GetRandomInitialReactionDefinitionFor(m_Pawn, StimuliPawn);

	// play the animation
    ReactionAnimationChannel = m_Pawn.AnimPlaySpecial(InitialReaction.AnimationName, InitialReaction.AnimationTweenTime);
	m_Pawn.FinishAnim(ReactionAnimationChannel);
}

state Running
{
 Begin:
	useResources(class'AI_Resource'.const.RU_ARMS);

	RotateTowardStimuli();

	useResources(class'AI_Resource'.const.RU_LEGS);

	PlayInitialReactionAnimation();

	ISwatAI(m_Pawn).GetCommanderAction().ResetIdling();

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	satisfiesGoal = class'InitialReactionGoal'
}
