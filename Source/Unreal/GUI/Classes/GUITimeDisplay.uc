// ====================================================================
//	Class: GUI. GUITimeDisplay
// ====================================================================
/*=============================================================================
	In Game GUI Editor System V1.0
	2003 - Irrational Games, LLC.
	* Dan Kaplan
=============================================================================*/
#if !IG_GUI_LAYOUT
#error This code requires IG_GUI_LAYOUT to be defined due to extensive revisions of the origional code. [DKaplan]
#endif
/*===========================================================================*/

class GUITimeDisplay extends GUINumericEdit
        HideCategories(Menu,Object)
	Native;


var(GUITimeDisplay) config GUILabel TimerLabel "GUI Label associated with this Time display";
var(GUITimeDisplay) private config bool bShowWhileNotRunning "If true, will show this component while the timer is not running";
var(GUITimeDisplay) private config bool bPauseWhileGamePaused "If true, will pause this timer while the game is not running";

var(DEBUG) private bool bRunning;
var(DEBUG) private bool bLooping;
var(DEBUG) private int StartTime;
var(DEBUG) private int ElapsedTime;


function InitComponent(GUIComponent MyOwner)
{
	Super.InitComponent(MyOwner);
	
	if( TimerLabel != None )
	{
	    MyEditBox.TextAlign=TXTA_Center;
	    TimerLabel.bBoundToParent = false;
	    TimerLabel.bScaleToParent = false;
	}
}

event Show()
{
    //only show when running?
    if( bShowWhileNotRunning || bRunning )
        Super.Show();
}

delegate OnTimeExpired();

function SetTime( int time )
{
    SetValue(time);
}

function StartTimer( optional int time, optional bool loop, optional bool reset )
{
    if( !reset && bRunning )
        return;
        
    if( time > 0 )
        SetTime( time );
    
    bLooping = loop;    
    StartTime = Value;
    ElapsedTime = 0;
    bRunning = true;
    //always show while running
    Show();
    SetTimer( Step, true );
}

function StopTimer()
{
    bRunning = false;
    KillTimer();

    if( !bShowWhileNotRunning )
        Hide();
}

event Timer()
{
    SetValue(Value - Step);
    
    ElapsedTime = StartTime - Value;
    
	if( Value <= 0 )
	{
	    TimerExpired();
	}
}

private function TimerExpired()
{
    OnTimeExpired();
    
    if( bLooping )
        SetTime( StartTime );
    else
        StopTimer();
}

function bool IsRunning()
{
    return bRunning;
}

function int GetStartTime()
{
    return StartTime;
}

function int GetElapsedTime()
{
    return ElapsedTime;
}

defaultproperties
{
	Value=0
	bAcceptsInput=false
	bDisplayAsTime=true
    bReadOnly=true
    MinValue=0
    Step=1
	bPauseWhileGamePaused=True
	StyleName="STY_TimeDisplay"
}