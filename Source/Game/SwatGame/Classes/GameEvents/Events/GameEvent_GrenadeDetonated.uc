class GameEvent_GrenadeDetonated extends Core.Object;

var array<IInterested_GameEvent_GrenadeDetonated> Interested;

function Register(IInterested_GameEvent_GrenadeDetonated inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_GrenadeDetonated inInterested)
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

function Triggered(Pawn GrenadeOwner, SwatGrenadeProjectile Grenade )
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnGrenadeDetonated(GrenadeOwner, Grenade);
}