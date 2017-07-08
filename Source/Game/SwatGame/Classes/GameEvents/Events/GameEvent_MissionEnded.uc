class GameEvent_MissionEnded extends Core.Object;

var array<IInterested_GameEvent_MissionEnded> Interested;

function Register(IInterested_GameEvent_MissionEnded inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_MissionEnded inInterested)
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
    local array<IInterested_GameEvent_MissionEnded> localInterested;
    local int i;

    // We have a number of OnMissionEnded handlers that in turn unregister for
    // MissionEnded events. Therefore, we copy to a local array before
    // iterating. We might consider doing this for other game events.
    localInterested = Interested;

    for (i=0; i<localInterested.length; ++i)
        localInterested[i].OnMissionEnded();
}
