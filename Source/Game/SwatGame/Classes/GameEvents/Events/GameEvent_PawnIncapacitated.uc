class GameEvent_PawnIncapacitated extends Core.Object;

var array<IInterested_GameEvent_PawnIncapacitated> Interested;

function Register(IInterested_GameEvent_PawnIncapacitated inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PawnIncapacitated inInterested)
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

function Triggered(Pawn Pawn, Actor Incapacitator, bool WasAThreat, class<DamageType> damageType)
{
    local int i;

	if(SwatPawn(Pawn) != None)
	{
		SwatPawn(Pawn).OnIncapacitated(Incapacitator, damageType);
	}

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPawnIncapacitated(Pawn, Incapacitator, WasAThreat);
}
