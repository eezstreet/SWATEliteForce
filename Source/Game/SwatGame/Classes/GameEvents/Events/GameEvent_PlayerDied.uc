class GameEvent_PlayerDied extends Core.Object;

var array<IInterested_GameEvent_PlayerDied> Interested;

function Register(IInterested_GameEvent_PlayerDied inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PlayerDied inInterested)
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

function Triggered(PlayerController Player, Controller Killer)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPlayerDied(Player, Killer);
}
