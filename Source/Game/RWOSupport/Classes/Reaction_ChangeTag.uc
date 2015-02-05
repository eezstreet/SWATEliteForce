class Reaction_ChangeTag extends Reaction;

var (Reaction) name OldTag;
var (Reaction) name NewTag;

protected simulated function Execute(Actor Owner, Actor Other)
{
    local Actor Current;

    foreach Owner.DynamicActors(class'Actor', Current, OldTag)
        Current.Tag = NewTag;
}
