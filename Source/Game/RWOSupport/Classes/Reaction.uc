class Reaction extends Core.Object
    hideCategories(Object)
    collapsecategories
    editinlinenew
    abstract
    native;

var (Reaction) bool OnceOnly "If true, this reaction will be triggered the first time only. If false, it will be re-triggered every time";
var protected bool Done;

var (Reaction) name Event;

final simulated function InternalExecute(Actor Owner, Actor Other)
{
    if (Done && OnceOnly) return;

    Execute(Owner, Other);

    Done = true;

    Owner.TriggerEvent(Event, Owner, Pawn(Other));
}

protected simulated function Execute(Actor Owner, Actor Other);

