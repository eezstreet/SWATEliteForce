class Handler_Damaged extends Handler;

var (Handler) int Minimum;      //the minimum damage required to ilicit a response from this DamageHandler
var (Handler) bool AccumulateDamage;   //with respect to Minimum, should damage be accumulated, or forgotten each time damage happens

var int AccumulatedDamage;

static final simulated function Dispatch(
    array<Handler> Handlers,
    Actor Owner,
    int Damage,
    Pawn EventInstigator,
    vector HitLocation,
    vector Momentum,
    class<DamageType> DamageType)
{
    local int i;

    for (i=0; i<Handlers.length; ++i)
        Handler_Damaged(Handlers[i]).Handle(Owner, Damage, EventInstigator, HitLocation, Momentum, DamageType);
}

final simulated function Handle(
    Actor Owner,
    int Damage,
    Pawn EventInstigator,
    vector HitLocation,
    vector Momentum,
    class<DamageType> DamageType)
{
    if (Owner != None && Owner.Level.GetEngine().EnableDevTools)
    {
        Log("** Handling "$self$" On "$Owner$" Damage = "$Damage$" Accumulated = "$AccumulatedDamage);
    }

    AccumulatedDamage += Damage;

    if (AccumulateDamage)
    {
        if (AccumulatedDamage < Minimum)
            return;
    }
    else    //!AccumulateDamage
    {
        if (Damage < Minimum)
            return;
    }

    DoReactions(Owner, EventInstigator);
}
