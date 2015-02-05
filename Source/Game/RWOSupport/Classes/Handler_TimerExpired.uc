class Handler_TimerExpired extends Handler;

static final simulated function Dispatch(array<Handler> Handlers, Actor Owner, Actor Other)
{
    local int i;

    for (i=0; i<Handlers.length; ++i)
        Handler_TimerExpired(Handlers[i]).Handle(Owner, Other);
}

function simulated Handle(Actor Owner, Actor Other)
{
    DoReactions(Owner, Other);
}
