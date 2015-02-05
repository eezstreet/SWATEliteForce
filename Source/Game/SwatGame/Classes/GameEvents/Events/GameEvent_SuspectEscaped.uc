class GameEvent_SuspectEscaped extends Core.Object;

var array<IInterested_GameEvent_SuspectEscaped> Interested;

function Register(IInterested_GameEvent_SuspectEscaped inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_SuspectEscaped inInterested)
{
    local int i;
    
    for( i = 0; i < Interested.length; i++ )
    {
        if( Interested[i] == inInterested )
        {
            Interested.Remove(i,1);
        }
    }
}

function Triggered(SwatPawn What)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnSuspectEscaped(What);
}
