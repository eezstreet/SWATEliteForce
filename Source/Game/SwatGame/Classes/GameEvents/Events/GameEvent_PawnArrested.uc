class GameEvent_PawnArrested extends Core.Object;

var array<IInterested_GameEvent_PawnArrested> Interested;

function Register(IInterested_GameEvent_PawnArrested inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PawnArrested inInterested)
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

function Triggered( Pawn Arrestee, Pawn Arrester )
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPawnArrested( Arrestee, Arrester );
}
