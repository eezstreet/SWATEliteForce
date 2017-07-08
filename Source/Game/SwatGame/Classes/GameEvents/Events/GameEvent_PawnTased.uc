class GameEvent_PawnTased extends Core.Object;

var array<IInterested_GameEvent_PawnTased> Interested;

function Register(IInterested_GameEvent_PawnTased inInterested) {
	Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_EvidenceSecured inInterested)
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

function Triggered(Pawn Tased, Actor Taser)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPawnTased(Tased, Taser);
}