class GameEvent_PawnUnarrested extends Core.Object;

var array<IInterested_GameEvent_PawnUnarrested> Interested;

function Register(IInterested_GameEvent_PawnUnarrested inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PawnUnarrested inInterested)
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

function Triggered( Pawn Arrester, Pawn Arrestee )
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPawnUnarrested( Arrester, Arrestee );
}
