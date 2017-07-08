class MPArchetype extends Archetype
    config(MPArchetypes);

var config class<Actor> ActorClass;

function class<Actor> PickClass()
{
    return ActorClass;
}

defaultproperties
{
    InstanceClass=class'SwatGame.MPArchetypeInstance'
}
