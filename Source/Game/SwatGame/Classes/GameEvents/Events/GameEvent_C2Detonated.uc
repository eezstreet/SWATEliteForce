class GameEvent_C2Detonated extends Core.Object;

var array<IInterested_GameEvent_C2Detonated> Interested;

function Register(IInterested_GameEvent_C2Detonated inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_C2Detonated inInterested)
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

function Triggered( Pawn C2Owner, DeployedC2ChargeBase C2 )
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnC2Detonated( C2Owner, C2 );
}
