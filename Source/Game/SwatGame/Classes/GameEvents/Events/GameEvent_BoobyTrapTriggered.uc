class GameEvent_BoobyTrapTriggered extends Core.Object;

var array<IInterested_GameEvent_BoobyTrapTriggered> Interested;

function Register(IInterested_GameEvent_BoobyTrapTriggered inInterested)
{
    Interested[Interested.length] = inInterested;
}

function UnRegister(IInterested_GameEvent_BoobyTrapTriggered inInterested)
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

function Triggered(BoobyTrap Trap, Actor Triggerer)
{
  local int i;

  for (i=0; i<Interested.length; ++i)
      Interested[i].OnBoobyTrapTriggered(Trap, Triggerer);
}
