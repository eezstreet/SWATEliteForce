class InanimateArchetype extends Archetype
    config(InanimateArchetypes);

var config class<Actor> ActorClass;

function Initialize(Actor inOwner)
{
    //TMC do work here before calling super

    Super.Initialize(inOwner);
}

function class<Actor> PickClass()
{
    return ActorClass;
}

defaultproperties
{
    InstanceClass=class'SwatGame.InanimateArchetypeInstance'
}
