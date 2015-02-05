class GameEvent_BombDisabled extends Core.Object;

var array<IInterested_GameEvent_BombDisabled> Interested;

function Register(IInterested_GameEvent_BombDisabled inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_BombDisabled inInterested)
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

function Triggered( BombBase TheBomb, Pawn Disarmer )
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnBombDisabled( TheBomb, Disarmer );
}
