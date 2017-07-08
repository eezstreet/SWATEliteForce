class DebugFrameTester extends Engine.Actor
    placeable;

var float Period;

function PostBeginPlay()
{
    Super.PostBeginPlay();

    if (SwatGameInfo(Level.Game).bDebugFrames)
        SetTimer(Period, true);
}

event Timer()
{
    local int i;
    local float j;

    SwatGameInfo(Level.Game).GuardSlow(name$"::Timer() wasting a lot of time (happens every "$Period$" second(s))");

    //waste a lot of time
    for (i=0; i<100000; ++i) j = Sqrt(100000);
}

defaultproperties
{
    Period=1.0
}
