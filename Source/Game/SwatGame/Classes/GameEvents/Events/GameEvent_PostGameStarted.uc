class GameEvent_PostGameStarted extends Core.Object;

var array<IInterested_GameEvent_PostGameStarted> Interested;

function Register(IInterested_GameEvent_PostGameStarted inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_PostGameStarted inInterested)
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

function Triggered()
{
    local int i;
log("dkaplan: Triggered of GameEvent_PostGameStarted");
    for (i=0; i<Interested.length; ++i)
        Interested[i].OnPostGameStarted();
}
