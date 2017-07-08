class GameEvent_InanimateDisabled extends Core.Object;

var array<IInterested_GameEvent_InanimateDisabled> Interested;

function Register(IInterested_GameEvent_InanimateDisabled inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_InanimateDisabled inInterested)
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

function Triggered(ICanBeDisabled Disabled, Pawn Disabler)
{
    local int i;

    for (i=0; i<Interested.length; ++i)
        Interested[i].OnInanimateDisabled(Disabled, Disabler);
}
