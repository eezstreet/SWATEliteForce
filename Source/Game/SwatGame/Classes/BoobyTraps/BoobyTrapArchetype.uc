class BoobyTrapArchetype extends InanimateArchetype
    config(InanimateArchetypes);

var config class<BoobyTrap> BoobyTrapClass;

function Initialize(Actor inOwner)
{
    //TMC do work here before calling super

    Super.Initialize(inOwner);
}

//implemented from base Archetype
function class<Actor> PickClass()
{
    return BoobyTrapClass;    
}


defaultproperties
{
    InstanceClass=class'InanimateArchetypeInstance'
}
