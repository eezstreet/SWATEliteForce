class GameEvent_MissionStarted extends Core.Object;

var array<IInterested_GameEvent_MissionStarted> Interested;

function Register(IInterested_GameEvent_MissionStarted inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_MissionStarted inInterested)
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

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnMissionStarted();
}
