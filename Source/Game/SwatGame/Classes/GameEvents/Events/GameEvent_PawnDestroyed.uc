class GameEvent_PawnDestroyed extends Core.Object;

var array<IInterested_GameEvent_PawnDestroyed> Interested;

function Register(IInterested_GameEvent_PawnDestroyed inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PawnDestroyed inInterested)
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

function Triggered(Pawn Pawn)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPawnDestroyed(Pawn);
}
