class GameEvent_ReportableReportedToTOC extends Core.Object;

var array<IInterested_GameEvent_ReportableReportedToTOC> Interested;

function Register(IInterested_GameEvent_ReportableReportedToTOC inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_ReportableReportedToTOC inInterested)
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

function Triggered(IAmReportableCharacter ReportableCharacter, Pawn Reporter)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnReportableReportedToTOC(ReportableCharacter, Reporter);
}
