class GameEvent_EvidenceDestroyed extends Core.Object;

var array<IInterested_GameEvent_EvidenceDestroyed> Interested;

function Register(IInterested_GameEvent_EvidenceDestroyed inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_EvidenceDestroyed inInterested)
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

function Triggered(IEvidence What)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnEvidenceDestroyed(What);
}
