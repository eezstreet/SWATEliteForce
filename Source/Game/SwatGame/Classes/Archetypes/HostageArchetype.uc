class HostageArchetype extends CharacterArchetype
    config(HostageArchetypes);

//HostageArchetype data

function Initialize(Actor inOwner)
{
    //TMC do work here before calling super

    Super.Initialize(inOwner);
}

protected function Validate()
{
    Super.Validate();

    //validate HostageArchetype data
}

function InitializeInstance(ArchetypeInstance inInstance)
{
    local HostageArchetypeInstance Instance;

    Instance = HostageArchetypeInstance(inInstance);

    Super.InitializeInstance(Instance);

    //TMC TODO initialize HostageArchetypeInstance
}

//implemented from base Archetype
function class<Actor> PickClass()
{
    log("[ARCHETYPE] .. Class SwatHostage selected to spawn from Archetype "$name);

    return class'SwatHostage';
}

defaultproperties
{
    InstanceClass=class'SwatGame.HostageArchetypeInstance'

	CharacterType=HostageMaleDefault
}
