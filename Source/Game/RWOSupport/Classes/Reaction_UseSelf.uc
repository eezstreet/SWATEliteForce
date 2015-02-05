class Reaction_UseSelf extends Reaction;

//cause the RWO to react to being used (and execute those reactions)

protected simulated function Execute(Actor Owner, Actor Other)
{
    Owner.ReactToUsed(Other);
}
