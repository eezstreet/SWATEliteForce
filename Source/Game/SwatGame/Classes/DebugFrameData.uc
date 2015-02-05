class DebugFrameData extends Core.Object;

var float EndTimeSeconds;
var float DeltaTime;
var private String GuardString;

function AddGuardString(String inGuardString)
{
    if (GuardString != "")
        GuardString = GuardString $ "_|_";
    GuardString = GuardString $ inGuardString;
}

function String GetGuardString()
{
    return GuardString;
}

