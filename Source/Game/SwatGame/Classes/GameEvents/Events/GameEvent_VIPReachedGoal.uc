class GameEvent_VIPReachedGoal extends Core.Object;

var array<IInterested_GameEvent_VIPReachedGoal> Interested;

function Register(IInterested_GameEvent_VIPReachedGoal inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_VIPReachedGoal inInterested)
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

function Triggered( SwatPlayer Triggerer )
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnVIPReachedGoal( Triggerer );
}
