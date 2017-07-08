	//=============================================================================
// WindowConsole - console replacer to implement UWindow UI System
//=============================================================================
class WindowConsole extends Engine.Console;

import class Engine.Canvas;

// Constants.
const MaxLines=64;
const TextMsgSize=128;

// Variables.
var Engine.viewport Viewport;
var int Scrollback, NumLines, TopLine, TextLines;
var float MsgTime, MsgTickTime;
var string MsgText[64];
var float MsgTick[64];
var int ConsoleLines;
var float ConsolePos, ConsoleDest;
var bool bNoStuff, bTyping;
var bool bNoDrawWorld;

// ---------


var UWindowRootWindow	Root;
var() config string		RootWindow;

var float				OldClipX;
var float				OldClipY;
var bool				bCreatedRoot;
var float				MouseX;
var float				MouseY;

var class<UWindowConsoleWindow> ConsoleClass;
var config float		MouseScale;
var config bool			ShowDesktop;
var config bool			bShowConsole;
var bool				bBlackout;
var bool				bUWindowType;

var bool				bUWindowActive;
var bool				bQuickKeyEnable;
var bool				bLocked;
var bool				bLevelChange;
var string				OldLevel;

var config EInputKey	UWindowKey;

var UWindowConsoleWindow ConsoleWindow;

function ResetUWindow()
{
	if(Root != None)
		Root.Close();
	Root = None;
	bCreatedRoot = False;
	ConsoleWindow = None;
	bShowConsole = False;
	CloseUWindow();
}

function bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
{
	local byte k;
	k = Key;
	switch(Action)
	{
	case IST_Press:
		switch(k)
		{
#if IG_SWAT //dkaplan, we need the escape key, so we'll use pause for this
		case EInputKey.IK_Pause:
#else
		case EInputKey.IK_Escape:
#endif
			if (bLocked)
				return true;

			bQuickKeyEnable = False;
			LaunchUWindow();
			return true;
		case ConsoleKey:
			if (bLocked)
				return true;

			bQuickKeyEnable = True;
			LaunchUWindow();
			if(!bShowConsole)
				ShowConsole();
			return true;
		}
		break;
	}

	return False; 
	//!! because of ConsoleKey
	//!! return Super.KeyEvent(Key, Action, Delta);
}

function ShowConsole()
{
	bShowConsole = true;
	if(bCreatedRoot)
		ConsoleWindow.ShowWindow();
}

function HideConsole()
{
	ConsoleLines = 0;
	bShowConsole = false;
	if (ConsoleWindow != None)
		ConsoleWindow.HideWindow();
}

event Tick( float Delta )
{
	Super.Tick(Delta);

	if(bLevelChange && Root != None && string(Viewport.Actor.Level) != OldLevel)
	{
		OldLevel = string(Viewport.Actor.Level);
		// if this is Entry, we could be falling through to another level...
		if(Viewport.Actor.Level != Viewport.Actor.GetEntryLevel())
			bLevelChange = False;
		Root.NotifyAfterLevelChange();
	}
}

state UWindow
{
	event Tick( float Delta )
	{
		Global.Tick(Delta);
		if(Root != None)
			Root.DoTick(Delta);
	}

	function PostRender( canvas Canvas )
	{
		if(Root != None)
			Root.bUWindowActive = True;
		RenderUWindow( Canvas );
	}

	function bool KeyType( EInputKey Key, optional string Unicode )
	{
		if (Root != None)
			Root.WindowEvent(WM_KeyType, None, MouseX, MouseY, Key );
		return True;
	}

	function bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
	{
		local byte k;
		k = Key;

		switch (Action)
		{
		case IST_Release:
			switch (k)
			{
			case EInputKey.IK_LeftMouse:
				if(Root != None) 
					Root.WindowEvent(WM_LMouseUp, None, MouseX, MouseY, k);
				break;
			case EInputKey.IK_RightMouse:
				if(Root != None)
					Root.WindowEvent(WM_RMouseUp, None, MouseX, MouseY, k);
				break;
			case EInputKey.IK_MiddleMouse:
				if(Root != None)
					Root.WindowEvent(WM_MMouseUp, None, MouseX, MouseY, k);
				break;
			default:
				if(Root != None)
					Root.WindowEvent(WM_KeyUp, None, MouseX, MouseY, k);
				break;
			}
			break;

		case IST_Press:
			switch (k)
			{
			case EInputKey.IK_F9:	// Screenshot
				return Global.KeyEvent(Key, Action, Delta);
				break;
			case ConsoleKey:
				if (bShowConsole)
				{
					HideConsole();
					if(bQuickKeyEnable)
						CloseUWindow();
				}
				else
				{
					if(Root.bAllowConsole)
						ShowConsole();
					else
						Root.WindowEvent(WM_KeyDown, None, MouseX, MouseY, k);
				}
				break;
			case EInputKey.IK_Escape:
				if(Root != None)
					Root.CloseActiveWindow();
				break;
			case EInputKey.IK_LeftMouse:
				if(Root != None)
					Root.WindowEvent(WM_LMouseDown, None, MouseX, MouseY, k);
				break;
			case EInputKey.IK_RightMouse:
				if(Root != None)
					Root.WindowEvent(WM_RMouseDown, None, MouseX, MouseY, k);
				break;
			case EInputKey.IK_MiddleMouse:
				if(Root != None)
					Root.WindowEvent(WM_MMouseDown, None, MouseX, MouseY, k);
				break;
			default:
				if(Root != None)
					Root.WindowEvent(WM_KeyDown, None, MouseX, MouseY, k);
				break;
			}
			break;
		case IST_Axis:
			switch (Key)
			{
			case IK_MouseX:
				MouseX = MouseX + (MouseScale * Delta);
				break;
			case IK_MouseY:
				MouseY = MouseY - (MouseScale * Delta);
				break;					
			}
		default:
			break;
		}

		return true;
	}

Begin:
}

function ToggleUWindow()
{
}

function LaunchUWindow()
{
	Viewport.bSuspendPrecaching = True;
	bUWindowActive = !bQuickKeyEnable;
	Viewport.bShowWindowsMouse = True;

	if(bQuickKeyEnable)
		bNoDrawWorld = False;
	else
	{
		if(Viewport.Actor.Level.NetMode == NM_Standalone)
			Viewport.Actor.SetPause( True );
		bNoDrawWorld = ShowDesktop;
	}
	if(Root != None)
		Root.bWindowVisible = True;

	GotoState('UWindow');
}

function CloseUWindow()
{
	if(!bQuickKeyEnable)
		Viewport.Actor.SetPause( False );

	bNoDrawWorld = False;
	bQuickKeyEnable = False;
	bUWindowActive = False;
	Viewport.bShowWindowsMouse = False;

	if(Root != None)
		Root.bWindowVisible = False;
	GotoState('');
	Viewport.bSuspendPrecaching = False;
}

function CreateRootWindow(Canvas Canvas)
{
	local int i;

	if(Canvas != None)
	{
		OldClipX = Canvas.ClipX;
		OldClipY = Canvas.ClipY;
	}
	else
	{
		OldClipX = 0;
		OldClipY = 0;
	}
	
	Log("Creating root window: "$RootWindow);
	
	Root = New(None) class<UWindowRootWindow>(DynamicLoadObject(RootWindow, class'Class'));

	Root.BeginPlay();
	Root.WinTop = 0;
	Root.WinLeft = 0;

	if(Canvas != None)
	{
		Root.WinWidth = Canvas.ClipX / Root.GUIScale;
		Root.WinHeight = Canvas.ClipY / Root.GUIScale;
		Root.RealWidth = Canvas.ClipX;
		Root.RealHeight = Canvas.ClipY;
	}
	else
	{
		Root.WinWidth = 0;
		Root.WinHeight = 0;
		Root.RealWidth = 0;
		Root.RealHeight = 0;
	}

	Root.ClippingRegion.X = 0;
	Root.ClippingRegion.Y = 0;
	Root.ClippingRegion.W = Root.WinWidth;
	Root.ClippingRegion.H = Root.WinHeight;

//	Root.Console = Self;

	Root.bUWindowActive = bUWindowActive;

	Root.Created();
	bCreatedRoot = True;

	// Create the console window.
	ConsoleWindow = UWindowConsoleWindow(Root.CreateWindow(ConsoleClass, 100, 100, 200, 200));
	if(!bShowConsole)
		HideConsole();

	UWindowConsoleClientWindow(ConsoleWindow.ClientArea).TextArea.AddText(" ");
	for (I=0; I<4; I++)
		UWindowConsoleClientWindow(ConsoleWindow.ClientArea).TextArea.AddText(MsgText[I]);
}

function RenderUWindow( canvas Canvas )
{
	local UWindowWindow NewFocusWindow;

	Canvas.bNoSmooth = True;
	Canvas.Z = 1;
	Canvas.Style = 1;
	Canvas.DrawColor.r = 255;
	Canvas.DrawColor.g = 255;
	Canvas.DrawColor.b = 255;

	if(Viewport.bWindowsMouseAvailable && Root != None)
	{
		MouseX = Viewport.WindowsMouseX/Root.GUIScale;
		MouseY = Viewport.WindowsMouseY/Root.GUIScale;
	}

	if(!bCreatedRoot) 
		CreateRootWindow(Canvas);

	Root.bWindowVisible = True;
	Root.bUWindowActive = bUWindowActive;
	Root.bQuickKeyEnable = bQuickKeyEnable;

	if(Canvas.ClipX != OldClipX || Canvas.ClipY != OldClipY)
	{
		OldClipX = Canvas.ClipX;
		OldClipY = Canvas.ClipY;
		
		Root.WinTop = 0;
		Root.WinLeft = 0;
		Root.WinWidth = Canvas.ClipX / Root.GUIScale;
		Root.WinHeight = Canvas.ClipY / Root.GUIScale;

		Root.RealWidth = Canvas.ClipX;
		Root.RealHeight = Canvas.ClipY;

		Root.ClippingRegion.X = 0;
		Root.ClippingRegion.Y = 0;
		Root.ClippingRegion.W = Root.WinWidth;
		Root.ClippingRegion.H = Root.WinHeight;

		Root.Resized();
	}

	if(MouseX > Root.WinWidth) MouseX = Root.WinWidth;
	if(MouseY > Root.WinHeight) MouseY = Root.WinHeight;
	if(MouseX < 0) MouseX = 0;
	if(MouseY < 0) MouseY = 0;


	// Check for keyboard focus
	NewFocusWindow = Root.CheckKeyFocusWindow();

	if(NewFocusWindow != Root.KeyFocusWindow)
	{
		Root.KeyFocusWindow.KeyFocusExit();		
		Root.KeyFocusWindow = NewFocusWindow;
		Root.KeyFocusWindow.KeyFocusEnter();
	}


	Root.MoveMouse(MouseX, MouseY);
	Root.WindowEvent(WM_Paint, Canvas, MouseX, MouseY, 0);
	if(bUWindowActive || bQuickKeyEnable) 
		Root.DrawMouse(Canvas);
}

event Message( coerce string Msg, float MsgLife )
{
	Super.Message( Msg, MsgLife );

	if ( Viewport.Actor == None )
		return;

	if( (Msg!="") && (ConsoleWindow != None) )
		UWindowConsoleClientWindow(ConsoleWindow.ClientArea).TextArea.AddText(MsgText[TopLine]);
}

function UpdateHistory()
{
	// Update history buffer.
	History[HistoryCur++ % MaxHistory] = TypedStr;
	if( HistoryCur > HistoryBot )
		HistoryBot++;
	if( HistoryCur - HistoryTop >= MaxHistory )
		HistoryTop = HistoryCur - MaxHistory + 1;
}

function HistoryUp()
{
	if( HistoryCur > HistoryTop )
	{
		History[HistoryCur % MaxHistory] = TypedStr;
		TypedStr = History[--HistoryCur % MaxHistory];
	}
}

function HistoryDown()
{
	History[HistoryCur % MaxHistory] = TypedStr;
	if( HistoryCur < HistoryBot )
		TypedStr = History[++HistoryCur % MaxHistory];
	else
		TypedStr="";
}

function NotifyLevelChange()
{
//	Super.NotifyLevelChange();
	bLevelChange = True;
	if(Root != None)
		Root.NotifyBeforeLevelChange();
}

defaultproperties
{
	MouseScale=0.6
	RootWindow="UWindow.UWindowRootWindow"
	UWindowKey=IK_None
	ConsoleKey=192
	ConsoleClass=class'UWindowConsoleWindow'
	bShowConsole=False
	bLevelChange=False
}
