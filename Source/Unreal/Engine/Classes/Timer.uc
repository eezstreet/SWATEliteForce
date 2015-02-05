class Timer extends Actor
    native;

var protected float InitialTime;
var protected bool Looping;
var protected bool Running;

var private float LastStartTime;
var private float LastDuration;

function SetTime(float newTime)
{
    InitialTime = newTime;
}

function StartTimer(optional float newTime, optional bool loop, optional bool reset)
{
    assertWithDescription(newTime > 0 || InitialTime > 0,
        "[tcohen] The "$class.name$" owned by "$Owner$" was called to StartTimer(), but newTime and InitialTime are both zero.");

	if (Running && !reset)
		return;

    if (newTime > 0)
        SetTime(newTime);

	Looping = loop;

	SetTimer(InitialTime, false);
	Running = true;
    
    LastStartTime = Level.TimeSeconds;
    LastDuration = newTime;

	StartTimerHook(InitialTime, loop, reset);
}
function StartTimerHook(float newTime, bool loop, bool reset);

function StopTimer()
{
	SetTimer(0, false);	//this is the Unreal Way (tm)... not what I'd suggest
	Running = false;
}

function bool IsRunning()
{
    return Running;
}

event Timer()
{
	StopTimer();
	if (Looping) StartTimer(InitialTime, true);

	TimerHook();
	TimerDelegate();
}
//for subclasses of Timer to react to Timer popping
function TimerHook();
//for users of a Timer to receive notification of a Timer popping
delegate TimerDelegate()
{
    if (Level.GetEngine().EnableDevTools)
    {
        // ckline: changed to a log because assert was killing the network server whenever a client disconnected!
        //assertWithDescription(false,
        //   name$"'s time expired, but nobody is interested. (delegate is unassigned)");
        Log(name$"'s time expired, but nobody is interested. (delegate is unassigned)");
    }
}

event float GetLastStartTime()
{
    return LastStartTime;
}

event float GetLastDuration()
{
    return LastDuration;
}

defaultproperties
{
    Physics=PHYS_None
	bHidden=true
    RemoteRole=ROLE_None
}
