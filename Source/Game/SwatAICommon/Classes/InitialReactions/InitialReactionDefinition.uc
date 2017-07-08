class InitialReactionDefinition extends Core.Object
    within InitialReactionsList
    perobjectconfig;

///////////////////////////////////////////////////////////////////////////////
//
// InitialReactionDefinition Enumerations

enum EReactionCharacterType
{
    GuardReaction,
    EnemyReaction,
    HostageReaction,
};

enum ECharacterReactionPosition
{
    ReactStanding,
    ReactCrouching,
	CharacterPositionDoesntMatter
};

enum EStimuliPosition
{
	StimuliInFront,
	StimuliBehind,
	StimuliPositionDoesntMatter,
};

///////////////////////////////////////////////////////////////////////////////
//
// IdleDefinition Configuration Variables
var config array<EReactionCharacterType>	ReactionCharacterTypes;
var config ECharacterReactionPosition		ReactionPosition;
var config EStimuliPosition					StimuliPosition;

// Animator related config variables
var config name							AnimationName;
var config float						AnimationTweenTime;

///////////////////////////////////////////////////////////////////////////////
//
// IdleDefinition Queries

function bool CanUseInitialReactionDefinition(Pawn Reactor, Pawn Stimuli)
{
	assert(Reactor != None);
	assert(Reactor.IsA('SwatAI'));

	assert(Stimuli != None);

	return (CanUseInitialReactionBasedOnType(Reactor) &&
			CanUseInitialReactionBasedOnPosition(Reactor) &&
			CanUseInitialReactionBasedOnStimuliPosition(Reactor, Stimuli));
}

private function bool CanUseInitialReactionBasedOnType(Pawn Reactor)
{
    local EReactionCharacterType TypeToMatch;
    local int i;

    // Determine the reaction character type we want to match
    // @NOTE: The order here is important, since SwatGuard is currently a
    // specialized subclass of the SwatEnemy class. [darren]
    if (Reactor.IsA('SwatGuard'))
    {
        TypeToMatch = GuardReaction;
    }
    else if (Reactor.IsA('SwatEnemy'))
    {
        TypeToMatch = EnemyReaction;
    }
    else if (Reactor.IsA('SwatHostage'))
    {
        TypeToMatch = HostageReaction;
    }
    else
    {
        // didn't find one, this is bad!
        assert(false);
        return false;
    }

    for (i = 0; i < ReactionCharacterTypes.length; ++i)
    {
        if (ReactionCharacterTypes[i] == TypeToMatch)
        {
            return true;
        }
    }

    return false;
}

private function bool CanUseInitialReactionBasedOnPosition(Pawn Reactor)
{

	if (ReactionPosition == CharacterPositionDoesntMatter)
	{
		return true;
	}
	else if (ReactionPosition == ReactStanding)
	{
		return !Reactor.bIsCrouched;
	}
	else
	{
		// sanity check!
		assert(ReactionPosition == ReactCrouching);

		return Reactor.bIsCrouched;
	}
}

private function bool CanUseInitialReactionBasedOnStimuliPosition(Pawn Reactor, Pawn Stimuli)
{
	local bool bInFront;

	if (StimuliPosition == StimuliPositionDoesntMatter)
	{
		return true;
	}
	else
	{
		bInFront = (vector(ISwatAI(Reactor).GetAimOrientation()) Dot Normal(Stimuli.Location - Reactor.Location)) >= 0.0;

		if (StimuliPosition == StimuliInFront)
		{
			return bInFront;
		}
		else
		{
			assert(StimuliPosition == StimuliBehind);

			return ! bInFront;
		}
	}
}

defaultproperties
{
	AnimationTweenTime = 0.1
}