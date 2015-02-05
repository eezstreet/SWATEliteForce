class GameEvent_PawnDamaged extends Core.Object;

var array<IInterested_GameEvent_PawnDamaged> Interested;

function Register(IInterested_GameEvent_PawnDamaged inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PawnDamaged inInterested)
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

function Triggered(Pawn Pawn, Actor Damager)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPawnDamaged(Pawn, Damager);
}
