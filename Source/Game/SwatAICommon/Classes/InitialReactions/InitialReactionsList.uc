///////////////////////////////////////////////////////////////////////////////
/// InitialReactionsList.uc - The InitialReactionsList class
/// Contains the lists of all possible InitialReactionsList that AIs can use
///////////////////////////////////////////////////////////////////////////////
class InitialReactionsList extends Engine.Actor
    config(InitialReactionsList);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///
/// InitialReactionsList config variables

var config array<Name>					InitialReactionNames;
var array<InitialReactionDefinition>	InitialReactions;

///////////////////////////////////////////////////////////////////////////////
///
/// Initialization Events

event PreBeginPlay()
{
    Super.PreBeginPlay();

    CreateInitialReactionDefinitions();
}

private function CreateInitialReactionDefinitions()
{
    local int i;
    local InitialReactionDefinition NewInitialReactionDefinition;

    for (i=0; i<InitialReactionNames.length; ++i)
    {
        // Create the Initial Reaction Definitions
        NewInitialReactionDefinition = new(self, string(InitialReactionNames[i]), 0) class'InitialReactionDefinition';
        assert(NewInitialReactionDefinition != None);

        InitialReactions[i] = NewInitialReactionDefinition;
    }
}

function InitialReactionDefinition GetRandomInitialReactionDefinitionFor(Pawn Reactor, Pawn Stimuli)
{
	local int i;
	local array<InitialReactionDefinition> UsableInitialReactions;
	local InitialReactionDefinition Iter;

	assert(Reactor != None);
	assert(Stimuli != None);

	for (i=0; i<InitialReactions.Length; ++i)
	{
		Iter = InitialReactions[i];

		if (Iter.CanUseInitialReactionDefinition(Reactor, Stimuli))
		{
			UsableInitialReactions[UsableInitialReactions.Length] = Iter;
		}
	}

	return UsableInitialReactions[Rand(UsableInitialReactions.Length)];
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    bHidden=true
}