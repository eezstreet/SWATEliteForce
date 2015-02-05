class GameEvent_EnemyFiredWeapon extends Core.Object;

var array<IInterested_GameEvent_EnemyFiredWeapon> Interested;

function Register(IInterested_GameEvent_EnemyFiredWeapon inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_EnemyFiredWeapon inInterested)
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

function Triggered(Pawn Enemy, Actor Target)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnEnemyFiredWeapon(Enemy, Target);
}