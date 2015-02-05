class GameEvent_EvidenceSecured extends Core.Object;

var array<IInterested_GameEvent_EvidenceSecured> Interested;

function Register(IInterested_GameEvent_EvidenceSecured inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_EvidenceSecured inInterested)
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

function Triggered(IEvidence Secured)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnEvidenceSecured(Secured);
}
