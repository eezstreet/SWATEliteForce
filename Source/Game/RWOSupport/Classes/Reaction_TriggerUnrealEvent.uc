class Reaction_TriggerUnrealEvent extends Reaction;

var (Reaction) name Event;
var (Reaction) bool bUnTrigger;

protected simulated function Execute(Actor Owner, Actor Other)
{
    if (bUnTrigger)
        Owner.UnTriggerEvent(Event, Owner, Pawn(Owner));
    else
        Owner.TriggerEvent(Event, Owner, Pawn(Owner));
}
