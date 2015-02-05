class GameEvent_Special extends Core.Object;

var array<IInterested_GameEvent_Special> Interested;

function Register(IInterested_GameEvent_Special inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_Special inInterested)
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

function Triggered(name SpecialGameEvent)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnSpecialGameEvent(SpecialGameEvent);
}
