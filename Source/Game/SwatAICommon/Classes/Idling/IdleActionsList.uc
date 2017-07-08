///////////////////////////////////////////////////////////////////////////////
/// IdleActionsList.uc - The IdleActionsList class
/// Contains the lists of all possible IdleActions that AIs can use
///////////////////////////////////////////////////////////////////////////////
class IdleActionsList extends Engine.Actor
    config(IdleActionsList);
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
///
/// IdleActionsClassList config variables
var config array<Name>              AnimatorIdleNames;
var array<AnimatorIdleDefinition>   AnimatorIdleDefinitions;

var config array<Name>              ProceduralIdleNames;
var array<ProceduralIdleDefinition> ProceduralIdleDefinitions;

///////////////////////////////////////////////////////////////////////////////
///
/// Initialization Events
event PreBeginPlay()
{
    Super.PreBeginPlay();

    CreateAnimatorIdleActionDefinitions();
	// disabled this for now [crombie]
//    CreateProceduralIdleActionDefinitions();
}

private function CreateAnimatorIdleActionDefinitions()
{
    local int i, j;
    local AnimatorIdleDefinition NewAnimatorIdleDefinition;

	// sanity check for animators
	for(i=0; i<AnimatorIdleNames.Length; ++i)
	{
		for(j=i+1; j<AnimatorIdleNames.Length; ++j)
		{
			if (AnimatorIdleNames[i] == AnimatorIdleNames[j])
                warn("IdleActionsList::CreateAnimatorIdleActionDefinitions - Animator Idle Named " $ AnimatorIdleNames[i] $ " duplicated in IdleActionsList.ini");
		}
	}

    for (i=0; i<AnimatorIdleNames.length; ++i)
    {
        // Create the Animator Idle Definition
        NewAnimatorIdleDefinition = new(self, string(AnimatorIdleNames[i]), 0) class'AnimatorIdleDefinition';
        assert(NewAnimatorIdleDefinition != None);

        AnimatorIdleDefinitions[i] = NewAnimatorIdleDefinition;
    }
}


private function CreateProceduralIdleActionDefinitions()
{
    local int i;
    local ProceduralIdleDefinition NewProceduralIdleDefinition;

    for (i=0; i<ProceduralIdleNames.length; ++i)
    {
        // Create the Procedural Idle Definition
        NewProceduralIdleDefinition = new(self, string(ProceduralIdleNames[i]), 0) class'ProceduralIdleDefinition';
        assert(NewProceduralIdleDefinition != None);

        ProceduralIdleDefinitions[i] = NewProceduralIdleDefinition;
    }
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    bHidden=true
}