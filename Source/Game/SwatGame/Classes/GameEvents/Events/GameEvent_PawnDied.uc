class GameEvent_PawnDied extends Core.Object;

var array<IInterested_GameEvent_PawnDied> Interested;

function Register(IInterested_GameEvent_PawnDied inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PawnDied inInterested)
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

function Triggered(Pawn Pawn, Actor Killer, bool WasAThreat, class<DamageType> damageType)
{
    local int i;

	if(SwatPawn(Pawn) != None)
	{
		SwatPawn(Pawn).OnKilled(Killer, damageType);
	}

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPawnDied(Pawn, Killer, WasAThreat);
}
