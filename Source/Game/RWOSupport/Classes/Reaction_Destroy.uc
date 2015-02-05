class Reaction_Destroy extends Reaction;

protected simulated function Execute(Actor Owner, Actor Other)
{
    AssertWithDescription(Owner.IsA('ReactiveWorldObject'),
        "[carlos] "$Owner$" is not a ReactiveWorldObject!  Only ReactiveWorldObjects can execute Reaction_Destroy()");

    if (Owner.bNeedLifetimeEffectEvents)
    {
        Owner.UntriggerEffectEvent('Alive');
    	Owner.TriggerEffectEvent('Destroyed');
    }

    ReactiveWorldObject(Owner).DestroyRWO();
}
