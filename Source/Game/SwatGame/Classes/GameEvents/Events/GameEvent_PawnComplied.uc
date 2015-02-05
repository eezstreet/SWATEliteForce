class GameEvent_PawnComplied extends Core.Object;

var array<IInterested_GameEvent_PawnComplied> Interested;

function Register(IInterested_GameEvent_PawnComplied inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PawnComplied inInterested)
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

function Triggered( Pawn Compliee, Pawn Complier )
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPawnComplied( Compliee, Complier );
}
