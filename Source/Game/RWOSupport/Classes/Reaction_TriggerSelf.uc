class Reaction_TriggerSelf extends Reaction;

//cause this RWO to react to being Triggered (and execute those reactions)

protected simulated function Execute(Actor Owner, Actor Other)
{
    Owner.PreTrigger(Owner, Pawn(Other));
    Owner.Trigger(Owner, Pawn(Other));
}
