class Handler_KarmaImpacted extends Handler;

var (Handler) float MinimumVelocity;      //the minimum velocity required to ilicit a response from this DamageHandler
var (Handler) bool AccumulateVelocity;   //with respect to Minimum, should velocity be accumulated, or forgotten each time impact happens

var float AccumulatedVelocity;

static final simulated function Dispatch(
    array<Handler> Handlers,
    Actor Owner,
    Actor Other,
    vector pos,
    vector impactVel,
    vector impactNorm)
{
    local int i;

    for (i=0; i<Handlers.length; ++i)
        Handler_KarmaImpacted(Handlers[i]).Handle(Owner, Other, pos, impactVel, impactNorm);
}

final simulated function Handle(
    Actor Owner,
    Actor Other,
    vector pos,
    vector impactVel,
    vector impactNorm)
{
    local float velocityMagnitude;

    velocityMagnitude = VSize(impactVel);
    AccumulatedVelocity += velocityMagnitude;

    if (AccumulateVelocity)
    {
        if (AccumulatedVelocity < MinimumVelocity)
            return;
    }
    else    //!AccumulateVelocity
    {
        if (velocityMagnitude < MinimumVelocity)
            return;
    }

    DoReactions(Owner, Other);
}
